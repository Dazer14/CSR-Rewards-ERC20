// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

import "../../contracts/CsrRewardsERC20.sol";

/// @dev These vault shares would earn CSR from the vault shares being minted, burned or used
/// If these shares are custodied by a contract it will need to made eligible to earn CSR
/// Deposit contracts made eligible could further compound these shares
/// NB This would be used for non CsrRewardERC20 tokens
/// If wanting to deposit CsrRewardERC20 token,
///     consider assigning to that tokens turnstile ID and compounding {_depositToken}
///     - Will leave in another example
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
