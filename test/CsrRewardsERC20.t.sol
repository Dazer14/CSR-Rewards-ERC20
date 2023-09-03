// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/console.sol";

import {CsrRewardsERC20, ERC20} from "src/contracts/CsrRewardsERC20.sol";
import {TurnstileInterface} from "src/contracts/TurnstileInterface.sol";
import {RPC} from "src/utils/RPC.sol";

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

contract CsrRewardsERC20Test is Test, RPC {
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
        vm.createSelectFork(RPC.MAINNET_RPC_URL);
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

    // Tests

    function testUserHasEligibleBalance() external {
        assertEq(token.balanceOf(user1), userBalance);
        assertEq(token.rewardEligibleBalanceOf(user1), userBalance);
    }

    function testTurnstileBalance(uint256 amountToDistribute) external {
        _distributeAmount(amountToDistribute);
        assertEq(token.turnstileBalance(), amountToDistribute);
    }

    function testWithdrawFromTurnstile(uint256 amountToDistribute) external {
        _distributeAmount(amountToDistribute);
        // Assert that the turnstile balance is as expected
        assertEq(token.turnstileBalance(), amountToDistribute);
        // Call the withdrawFromTurnstile function
        token.withdrawFromTurnstile();
        // Assert that the turnstile balance is now zero
        assertEq(token.turnstileBalance(), 0);
        // Compute the fraction of the eligible supply user1 has and compare to fraction of rewards received
        uint256 user1EligibleBalance = token.rewardEligibleBalanceOf(user1);
        uint256 totalEligibleSupply = token.totalRewardEligibleSupply();
        // Assert that user1 has earned their proportion of the amount distributed
        // This assumes user1 received a proportion of the supply, based on their eligible balance
        assertEq(token.earned(user1), amountToDistribute * user1EligibleBalance / totalEligibleSupply);
    }

    function testUserCanClaimRewards(uint256 amountToDistribute) external {
        _distributeAmount(amountToDistribute);
        token.withdrawFromTurnstile();
        // Ensure that the user has some rewards to claim
        uint256 rewards = token.earned(user1);
        assertTrue(rewards > 0);
        // Store the initial balance of the user
        uint256 initialBalance = address(user1).balance;
        // Prank user1 to claim their rewards
        vm.prank(user1);
        token.getReward();
        // Assert that the rewards have been transferred to the user's balance
        uint256 finalBalance = address(user1).balance;
        assertEq(finalBalance, initialBalance + rewards);
    }

    function testUserGetsCorrectRewardsAfterTransfer(uint256 amountToDistribute, uint16 fractionToTransfer) external {
        // Ensure fractionToTransfer is between 0 and 10000
        vm.assume(fractionToTransfer >= 0 && fractionToTransfer <= 10000);
        uint256 balanceToTransfer = token.balanceOf(user1) * fractionToTransfer / 10000;
        // Prank a transfer from user1 to user2, sending a fraction of user1's balance
        vm.prank(user1);
        token.transfer(user2, balanceToTransfer);
        // Distribute and withdraw rewards from turnstile
        _distributeAmount(amountToDistribute);
        token.withdrawFromTurnstile();
        // Compute the fraction of the eligible supply both users have and compare to fraction of rewards received
        uint256 user1EligibleBalance = token.rewardEligibleBalanceOf(user1);
        uint256 user2EligibleBalance = token.rewardEligibleBalanceOf(user2);
        uint256 totalEligibleSupply = token.totalRewardEligibleSupply();
        uint256 user1Rewards = token.earned(user1);
        uint256 user2Rewards = token.earned(user2);
        // Assert that expected fraction of rewards are received
        assertEq(user1Rewards, amountToDistribute * user1EligibleBalance / totalEligibleSupply);
        assertEq(user2Rewards, amountToDistribute * user2EligibleBalance / totalEligibleSupply);
    }
    
}
