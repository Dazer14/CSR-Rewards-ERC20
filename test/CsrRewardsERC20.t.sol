// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/console2.sol";

import {CsrRewardsERC20, ERC20} from "src/contracts/CsrRewardsERC20.sol";
// import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

// forge test --fork-url https://canto.gravitychain.io -vv

contract TestToken is ERC20, CsrRewardsERC20 {
    constructor(
        string memory _name, 
        string memory _symbol,
        bool _usingFee,
        uint8 _feeBasisPoints
    ) ERC20(_name, _symbol) CsrRewardsERC20(_usingFee, _feeBasisPoints) {}

    function _afterTokenTransfer(address from, address to, uint amount) 
        internal 
        override(ERC20, CsrRewardsERC20) 
    {
        super._afterTokenTransfer(from, to, amount);
    }
}

// Tests are not yet reliable, need to register turnstile accumulation
contract CsrRewardsERC20Test is Test {
    TestToken _token;

    address _origin = address(0x555);
    address _user1 = address(0x1);
    address _user2 = address(0x2);
    address _user3 = address(0x3);

    function setUp() public {
        _token = new TestToken("Test", "TEST", true, 100);
        deal(address(_token), _origin, 3000, true);
        console.log(_token.turnstileBalance());
        vm.startPrank(_origin);
        _token.transfer(_user1, 1000);
        _token.transfer(_user2, 1000);
        _token.transfer(_user3, 1000);
        vm.stopPrank();
    }

    function testUserHasBalance() external {
        // vm.roll(block.number + 1);
        // console.log(_token.turnstileBalance());
        assertEq(_token.balanceOf(_user1), 1000);
        assertEq(_token.rewardEligibleBalanceOf(_user1), 1000);
    }
}
