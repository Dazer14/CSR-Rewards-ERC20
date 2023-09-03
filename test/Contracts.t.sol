// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/console.sol";

import {CsrRewardsERC20, ERC20} from "src/contracts/CsrRewardsERC20.sol";
import {TurnstileInterface} from "src/contracts/TurnstileInterface.sol";

interface TurnstileOwnerControls {
    function distributeFees(uint256 _tokenId) external payable;
}

contract TestToken is ERC20, CsrRewardsERC20 {
    constructor(
        string memory _name, 
        string memory _symbol,
        uint8 _feeBasisPoints
    ) ERC20(_name, _symbol) CsrRewardsERC20(_feeBasisPoints) {}

    function _afterTokenTransfer(address from, address to, uint amount) 
        internal 
        override(ERC20, CsrRewardsERC20) 
    {
        super._afterTokenTransfer(from, to, amount);
    }
}

contract Contracts is Test {
    TestToken public token;

    address public turnstile = address(0xEcf044C5B4b867CFda001101c617eCd347095B44);
    address public turnstileOwner = address(0xC27338c453067b437471aFBCE792704D816112c6);

    address public origin = address(0x555);
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    address public user3 = address(0x3);
    address public user4 = address(0x4);

    uint256 public totalSupply = 4000;
    uint256 public userBalance = totalSupply / 4;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("canto"));
        // Testing with no withdraw call fee
        token = new TestToken("Test", "TEST", 0);

        vm.deal(turnstileOwner, type(uint256).max);

        // Deal then transfer to make sure after transfer hook is run
        // Only users will have an eligible account 
        deal(address(token), origin, totalSupply, true);
        vm.startPrank(origin);
        token.transfer(user1, userBalance);
        token.transfer(user2, userBalance);
        token.transfer(user3, userBalance);
        token.transfer(user4, userBalance);
        vm.stopPrank();
    }

    // Helpers

    function _distributeAmount(uint256 amount) internal {
        // Mocking a wide range of reward amounts
        vm.assume(amount < 10000e18 && amount > 10000);
        vm.startPrank(turnstileOwner);
        TurnstileOwnerControls(turnstile).distributeFees{value:amount}(token.csrID());
        vm.stopPrank();
    }

    // All you need to be testing is eligible supply being aligned with token balance for an EOA and a contract
    function testBasicTransferToExistingContract(uint256 amountToDistribute, uint16 fractionToTransfer) external {
        // Ensure fractions are between 0 and 10000
        vm.assume(fractionToTransfer >= 0 && fractionToTransfer <= 10000);
        
        // Deploy a new contract for this test
        // This contract is just used to simulate transfers to and from a reward ineligible contract
        address existingContract = turnstile;
        
        uint256 balanceToTransfer = token.balanceOf(user1) * fractionToTransfer / 10000;
        
        // Prank a transfer from user1 to existingContract
        vm.prank(user1);
        token.transfer(existingContract, balanceToTransfer);
        
        // Distribute and withdraw rewards from turnstile
        _distributeAmount(amountToDistribute);
        token.withdrawFromTurnstile();
        
        // Compute the fraction of the eligible supply each user has and compare to fraction of rewards received
        uint256 user1EligibleBalance = token.rewardEligibleBalanceOf(user1);
        uint256 existingContractEligibleBalance = token.rewardEligibleBalanceOf(existingContract);
        
        assertEq(user1EligibleBalance, token.balanceOf(user1));
        assertEq(existingContractEligibleBalance, 0);
    }

    function testTransferToAndFromExistingContract(uint256 amountToDistribute, uint16 fractionToTransfer1, uint16 fractionToTransfer2) external {
        // Ensure fractions are between 0 and 10000
        vm.assume(fractionToTransfer1 >= 0 && fractionToTransfer1 <= 10000);
        vm.assume(fractionToTransfer2 >= 0 && fractionToTransfer2 <= 10000);
        
        // Calculate the balance to transfer
        uint256 balanceToTransfer1 = token.balanceOf(user1) * fractionToTransfer1 / 10000;
        
        // Prank a transfer from user1 to existingContract
        vm.prank(user1);
        token.transfer(turnstile, balanceToTransfer1);
        
        // Calculate the balance to transfer
        uint256 balanceToTransfer2 = token.balanceOf(turnstile) * fractionToTransfer2 / 10000;
        
        // Prank a transfer from existingContract to user2
        vm.prank(turnstile);
        token.transfer(user2, balanceToTransfer2);
        
        // Distribute and withdraw rewards from turnstile
        _distributeAmount(amountToDistribute);
        token.withdrawFromTurnstile();
        
        // Compute the fraction of the eligible supply each user has and compare to fraction of rewards received
        assertEq(token.rewardEligibleBalanceOf(user1), token.balanceOf(user1));
        assertEq(token.rewardEligibleBalanceOf(turnstile), 0);
        assertEq(token.rewardEligibleBalanceOf(user2), token.balanceOf(user2));
    }

}
