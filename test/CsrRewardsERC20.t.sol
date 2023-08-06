// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import "src/CsrRewardsERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

// forge test --v --fork-url https://canto.gravitychain.io

contract TestToken is ERC20, CsrRewardsERC20 {
    constructor(
        string memory _name, 
        string memory _symbol
    ) ERC20(_name, _symbol) CsrRewardsERC20() {}

    function _beforeTokenTransfer(address from, address to, uint amount) 
        internal 
        override(ERC20, CsrRewardsERC20) 
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}

contract CsrRewardsERC20Test is Test {
    TestToken _token;

    function setUp() public {
        _token = new TestToken("Test", "TEST");
    }

    function testGetsCsrID() external {
        assertEq(_token.name(), "Test");
        console.log(_token.csrID());
    }
}
