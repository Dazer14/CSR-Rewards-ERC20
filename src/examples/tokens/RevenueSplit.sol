// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CsrRewardsERC20, ERC20} from "../../contracts/CsrRewardsERC20.sol";

contract RevenueSplit is ERC20, CsrRewardsERC20 {
    uint256 public revenueBasisPoints;
    address public revenueWallet;

    constructor(
        string memory _name,
        string memory _symbol,
        uint16 _withdrawCallFeeBasisPoints,
        uint256 _revenueBasisPoints,
        address _revenueWallet,
        uint256 _supply
    ) ERC20(_name, _symbol) CsrRewardsERC20(_withdrawCallFeeBasisPoints) {
        require((_revenueBasisPoints <= _BPS), "Revenue basis points must be less than 10000");
        revenueBasisPoints = _revenueBasisPoints;
        revenueWallet = _revenueWallet;
        _mint(msg.sender, _supply);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, CsrRewardsERC20) {
        super._afterTokenTransfer(from, to, amount);
    }

    /// @dev Mostly duplicating existing code, just factoring in revenue fee
    function withdrawFromTurnstile() external virtual override nonReentrant {
        uint256 amountToClaim = turnstileBalance();
        require(amountToClaim > 0, "CsrRewardsERC20: No CSR to claim");

        TURNSTILE.withdraw(csrID, payable(address(this)), amountToClaim);

        uint256 revenueAmount = amountToClaim * revenueBasisPoints / _BPS;
        _transferCANTO(revenueWallet, revenueAmount);

        if (withdrawCallFeeBasisPoints != 0) {
            uint256 withdrawCallfeeAmount = amountToClaim * withdrawCallFeeBasisPoints / _BPS;
            _registerRewardDelivery(amountToClaim - revenueAmount - withdrawCallfeeAmount);
            _transferCANTO(msg.sender, withdrawCallfeeAmount);
        } else {
            _registerRewardDelivery(amountToClaim - revenueAmount);
        }
    }
}
