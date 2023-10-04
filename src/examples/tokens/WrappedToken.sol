// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CsrRewardsERC20, ERC20} from "../../contracts/CsrRewardsERC20.sol";
import {ERC20Wrapper} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Wrapper.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SimpleWrappedToken is ERC20, CsrRewardsERC20, ERC20Wrapper {
    constructor(
        string memory _name, 
        string memory _symbol, 
        uint256 _supply, 
        uint8 _scalar,
        address _underlyingToken
    ) 
        ERC20(_name, _symbol)
        CsrRewardsERC20(_scalar)
        ERC20Wrapper(IERC20(_underlyingToken))
    {
        _mint(msg.sender, _supply);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, CsrRewardsERC20) {
        super._afterTokenTransfer(from, to, amount);
    }

    function decimals() public view virtual override(ERC20, ERC20Wrapper) returns (uint8) {
        return super.decimals();
    }
}