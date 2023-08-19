// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

import "../../contracts/ICsrRewardsERC20.sol";
import "../../contracts/TurnstileInterface.sol";

/// @dev CsrRewardsERC20 token compounder
/// This contract custodies CsrRewardsERC20 token aggregate and converts CANTO earned to CsrRewardsERC20
abstract contract CsrRewardsERC20Compounder is ERC20, ERC4626 {
    ICsrRewardsERC20 public immutable csrRewardsERC20;

    TurnstileInterface public constant TURNSTILE = TurnstileInterface(0xEcf044C5B4b867CFda001101c617eCd347095B44);

    constructor(string memory _name, string memory _symbol, IERC20 _csrRewardsERC20, uint256 _csrID)
        ERC20(_name, _symbol)
        ERC4626(_csrRewardsERC20)
    {
        TURNSTILE.assign(_csrID);

        csrRewardsERC20 = ICsrRewardsERC20(address(_csrRewardsERC20));

        _makeEligible();
    }

    function decimals() public view virtual override(ERC20, ERC4626) returns (uint8) {
        return super.decimals();
    }

    function _makeEligible() internal virtual;

    function _convertToDepositToken(uint256 amount) internal virtual;

    function compoundCSR() external virtual {
        uint256 amountEarned = csrRewardsERC20.earned(address(this));
        require(amountEarned > 0, "CsrRewardsERC20Compounder: No earnings to claim");
        csrRewardsERC20.getReward();
        _convertToDepositToken(amountEarned);
    }
}
