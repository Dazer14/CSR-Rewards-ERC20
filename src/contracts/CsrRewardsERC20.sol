// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {TurnstileRegister} from "./TurnstileRegister.sol";

/**
 * @title CSR Reward Accumulating Token
 * Distributes all CSR earned to reward eligible holders
 * Logic is borrowed and modified from Synthetix StakingRewards.sol
 */
abstract contract CsrRewardsERC20 is ERC20, TurnstileRegister {
    uint256 public rewardPerEligibleToken;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewardsEarned;

    uint256 internal _totalRewardEligibleSupply;
    mapping(address => uint256) internal _rewardEligibleBalances;
    mapping(address => bool) internal _rewardEligibleAddress;

    uint16 internal constant _BPS = 10000;

    event RewardsDelivered(uint256 amount);
    event RewardsClaimed(address indexed account, uint256 amount);

    constructor() TurnstileRegister() {}

    receive() external payable virtual {
        _registerRewardDelivery(msg.value);
    }

    /// VIEW FUNCTIONS

    function totalRewardEligibleSupply() external view virtual returns (uint256) {
        return _totalRewardEligibleSupply;
    }

    function rewardEligibleBalanceOf(address account) external view virtual returns (uint256) {
        return _rewardEligibleBalances[account];
    }

    function isRewardEligible(address account) external view virtual returns (bool) {
        return _rewardEligibleAddress[account];
    }

    function earned(address account) public view virtual returns (uint256) {
        return rewardsEarned[account]
            + (_rewardEligibleBalances[account] * (rewardPerEligibleToken - userRewardPerTokenPaid[account]) / 1e36);
    }

    function turnstileBalance() public view virtual returns (uint256) {
        return TURNSTILE.balances(csrID);
    }

    /// INTERNAL FUNCTIONS

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        /// @dev First time transfer to address with code size 0 will register as reward eligible
        /// Contract addresses will have code size 0 before and during deploy
        /// Any method that sends this token to that address will make the contract reward eligible
        /// Self-minting in constructor makes this contract reward eligible
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

    function _transferCANTO(address to, uint256 amount) internal virtual {
        (bool success,) = payable(to).call{value: amount}("");
        require(success, "CsrRewardsERC20: Unable to send value, recipient may have reverted");
    }

    function _updateReward(address account) internal virtual {
        rewardsEarned[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerEligibleToken;
    }

    function _registerRewardDelivery(uint256 rewardAmount) internal virtual {
        rewardPerEligibleToken += rewardAmount * 1e36 / _totalRewardEligibleSupply;

        emit RewardsDelivered(rewardAmount);
    }

    function _increaseRewardEligibleBalance(address to, uint256 amount) internal virtual {
        _updateReward(to);
        _totalRewardEligibleSupply += amount;
        _rewardEligibleBalances[to] += amount;
    }

    /// EXTERNAL MUTABLE FUNCTIONS

    /// @notice Token holder function for claiming CSR rewards
    function getReward() external virtual {
        _updateReward(msg.sender);
        uint256 reward = rewardsEarned[msg.sender];
        if (reward > 0) {
            rewardsEarned[msg.sender] = 0;
            _transferCANTO(msg.sender, reward);

            emit RewardsClaimed(msg.sender, reward);
        }
    }

    /// @notice Public function for collecting and distributing contract accumulated CSR
    function withdrawFromTurnstile() external virtual {
        uint256 amountToClaim = turnstileBalance();
        require(amountToClaim > 0, "CsrRewardsERC20: No CSR to claim");

        TURNSTILE.withdraw(csrID, payable(address(this)), amountToClaim);
    }
}

