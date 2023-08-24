// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {TurnstileRegister} from "./TurnstileRegister.sol";

/**
 * @title CSR Reward Accumulating Token
 * Distributes all CSR earned to reward eligible holders
 * Logic is borrowed and modified from Synthetix StakingRewards.sol
 */
abstract contract CsrRewardsERC20 is ERC20, ReentrancyGuard, TurnstileRegister {
    bool public immutable usingWithdrawCallFee;
    uint16 public immutable withdrawCallFeeBasisPoints;

    uint256 public rewardPerEligibleToken;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewardsEarned;

    uint256 private _totalRewardEligibleSupply;
    mapping(address => uint256) private _rewardEligibleBalances;
    mapping(address => bool) private _rewardEligibleAddress;

    uint16 internal constant _BPS = 10000;

    event RewardsDelivered(uint256 amount);
    event RewardsClaimed(address indexed account, uint256 amount);

    constructor(
        bool _usingWithdrawCallFee, 
        uint16 _withdrawCallFeeBasisPoints
    ) TurnstileRegister() {
        usingWithdrawCallFee = _usingWithdrawCallFee;
        withdrawCallFeeBasisPoints = _withdrawCallFeeBasisPoints;
    }

    receive() external payable {
        require(
            msg.sender == address(TURNSTILE), "CsrRewardsERC20: Only turnstile transfers will be processed for rewards"
        );
        // _registerRewardDelivery(msg.value);
    }

    /// VIEW FUNCTIONS

    function totalRewardEligibleSupply() external view returns (uint256) {
        return _totalRewardEligibleSupply;
    }

    function rewardEligibleBalanceOf(address account) external view returns (uint256) {
        return _rewardEligibleBalances[account];
    }

    function earned(address account) public view returns (uint256) {
        return rewardsEarned[account]
            + (_rewardEligibleBalances[account] * (rewardPerEligibleToken - userRewardPerTokenPaid[account]) / 1e18);
    }

    function turnstileBalance() public view returns (uint256) {
        return TURNSTILE.balances(csrID);
    }

    function _withdrawFeeAmount(uint256 amountBeingClaimed) internal view returns (uint256) {
        return amountBeingClaimed * withdrawCallFeeBasisPoints / _BPS;
    }

    function currentWithdrawFeeAmount() external view returns (uint256) {
        return _withdrawFeeAmount(turnstileBalance());
    }

    /// INTERNAL FUNCTIONS

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        /// @dev First time transfer to address with code size 0 will register as reward eligible
        /// Contract addresses will have code size 0 before and during deploy
        /// Any method that sends this token to that address will make the contract reward eligible
        /// NB Self-minting in constructor makes this contract reward eligible
        if (_rewardEligibleAddress[to]) {
            _increaseRewardEligibleBalance(to, amount);
        } else {
            if (to.code.length == 0 && to != address(0)) { 
                _increaseRewardEligibleBalance(to, amount);
                _rewardEligibleAddress[to] = true;
            }
        }

        if (_rewardEligibleAddress[from]) { 
            _updateReward(from);
            _totalRewardEligibleSupply -= amount;
            _rewardEligibleBalances[from] -= amount;
        }
    }

    function _transferCANTO(address to, uint256 amount) internal {
        (bool success,) = payable(to).call{value: amount}("");
        require(success, "CsrRewardsERC20: Unable to send value, recipient may have reverted");
    }

    function _updateReward(address account) internal {
        rewardsEarned[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerEligibleToken;
    }

    function _registerRewardDelivery(uint256 rewardAmount) internal {
        rewardPerEligibleToken += rewardAmount * 1e18 / _totalRewardEligibleSupply;

        emit RewardsDelivered(rewardAmount);
    }

    function _increaseRewardEligibleBalance(address to, uint256 amount) private {
        _updateReward(to);
        _totalRewardEligibleSupply += amount;
        _rewardEligibleBalances[to] += amount;
    }

    /// EXTERNAL MUTABLE FUNCTIONS

    /// @notice Token holder function for claiming CSR rewards
    function getReward() external virtual nonReentrant {
        _updateReward(msg.sender);
        uint256 reward = rewardsEarned[msg.sender];
        if (reward > 0) {
            rewardsEarned[msg.sender] = 0;
            _transferCANTO(msg.sender, reward);

            emit RewardsClaimed(msg.sender, reward);
        }
    }

    /// @notice Public function for collecting and distributing contract accumulated CSR
    function withdrawFromTurnstile() external virtual nonReentrant {
        uint256 amountToClaim = turnstileBalance();
        require(amountToClaim > 0, "CsrRewardsERC20: No CSR to claim");

        TURNSTILE.withdraw(csrID, payable(address(this)), amountToClaim);

        if (usingWithdrawCallFee) {
            uint256 feeAmount = _withdrawFeeAmount(amountToClaim);
            _registerRewardDelivery(amountToClaim - feeAmount);
            _transferCANTO(msg.sender, feeAmount);
        } else {
            _registerRewardDelivery(amountToClaim);
        }
    }
}
