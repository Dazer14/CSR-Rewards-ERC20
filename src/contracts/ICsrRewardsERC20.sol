// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICsrRewardsERC20 {
    function totalRewardEligibleSupply() external view returns (uint256);
    function rewardEligibleBalanceOf(address account) external view returns (uint256);
    function turnstileBalance() external view returns (uint256);
    function earned(address account) external view returns (uint256);
    function csrID() external view returns (uint256);
    function getReward() external;
    function withdrawFromTurnstile() external;
}
