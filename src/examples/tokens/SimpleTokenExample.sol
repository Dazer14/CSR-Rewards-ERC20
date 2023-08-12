// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "openzeppelin/token/ERC20/ERC20.sol";

import "../../contracts/CsrRewardsERC20.sol";

contract SimpleTokenExample is ERC20, CsrRewardsERC20 {
    constructor(
        string memory _name, 
        string memory _symbol,
        bool _usingFee,
        uint16 _feeBasisPoints,
        uint _supply
    ) ERC20(_name, _symbol) CsrRewardsERC20(_usingFee, _feeBasisPoints) {
        _mint(msg.sender, _supply);
    }

    function _afterTokenTransfer(address from, address to, uint amount) 
        internal 
        override(ERC20, CsrRewardsERC20) 
    {
        super._afterTokenTransfer(from, to, amount);
    }
}
