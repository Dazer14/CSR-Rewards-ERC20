// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICsrRewardsERC20 {
    function totalRewardEligibleSupply() external view returns (uint);
    function rewardEligibleBalanceOf(address account) external view returns (uint);
    function rewardPerToken() external view returns (uint);
    function turnstileBalance() external view returns (uint);
    function earned(address account) external view returns (uint);
    function getReward() external;
}
