// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC4626, ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {CsrRewardsERC20} from "../../contracts/CsrRewardsERC20.sol";

/// @dev These vault shares would earn CSR from the vault shares being minted, burned or used
/// This amounts to an unneccessarily complex wrapper and should be deprecated, example only
contract CsrEarningVaultShare is ERC20, ERC4626, CsrRewardsERC20 {
    constructor(
        string memory _vaultName,
        string memory _vaultSymbol,
        IERC20 _depositToken,
        bool _usingWithdrawCallFee,
        uint16 _withdrawCallFeeBasisPoints
    )
        ERC20(_vaultName, _vaultSymbol)
        ERC4626(_depositToken)
        CsrRewardsERC20(_usingWithdrawCallFee, _withdrawCallFeeBasisPoints)
    {}

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        virtual
        override(ERC20, CsrRewardsERC20)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function decimals() public view virtual override(ERC20, ERC4626) returns (uint8) {
        return super.decimals();
    }
}
