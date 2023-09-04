// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "lib/forge-std/src/Test.sol";
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

contract BaseTest is Test {
    TestToken public token;

    address public turnstile = address(0xEcf044C5B4b867CFda001101c617eCd347095B44);
    address public turnstileOwner = address(0xC27338c453067b437471aFBCE792704D816112c6);

    address public origin = address(0x555);
    address public user1 = address(0x111);
    address public user2 = address(0x222);
    address public user3 = address(0x333);
    address public user4 = address(0x444);

    uint256 public totalSupply = 4_000_000e18;
    uint256 public userBalance = totalSupply / 4;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("canto"));
        // Testing with no withdraw call fee
        token = new TestToken("Test", "TEST", 0);

        vm.deal(turnstileOwner, type(uint256).max);

        // Deal then transfer to make sure after transfer hook is run
        // Only these users will have an eligible account initially
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
        vm.assume(amount < 10000e18 && amount > 1000);
        vm.startPrank(turnstileOwner);
        TurnstileOwnerControls(turnstile).distributeFees{value:amount}(token.csrID());
        vm.stopPrank();
    }
}