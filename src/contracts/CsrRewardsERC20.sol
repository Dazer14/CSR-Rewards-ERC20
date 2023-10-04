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
    uint256 internal _rewardPerEligibleToken;
    mapping(address => uint256) internal _accountRewardPerTokenPaid;
    mapping(address => uint256) internal _rewardsEarned;

    uint256 internal _totalRewardEligibleSupply;
    mapping(address => uint256) internal _rewardEligibleBalances;
    mapping(address => bool) internal _rewardEligibleAddress;

    uint256 public scalar;

    event RewardsDelivered(uint256 amount);
    event RewardsClaimed(address indexed account, uint256 amount);

    constructor(uint8 _scalar) TurnstileRegister() {
        scalar = 10 ** _scalar;
    }

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
        return _rewardsEarned[account]
            + (_rewardEligibleBalances[account] * (_rewardPerEligibleToken - _accountRewardPerTokenPaid[account]) / scalar);
    }

    function turnstileBalance() public view virtual returns (uint256) {
        return TURNSTILE.balances(csrID);
    }

    /// INTERNAL FUNCTIONS

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        /// @dev First time transfer to address with code size 0 will register as reward eligible
        /// Contract addresses will have code size 0 before and during construction
        /// Any method that sends this token to that address during its construction will make that contract reward eligible
        /// Self-minting in this contracts constructor makes this contract reward eligible
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

    function _increaseRewardEligibleBalance(address to, uint256 amount) internal virtual {
        _updateReward(to);
        _totalRewardEligibleSupply += amount;
        _rewardEligibleBalances[to] += amount;
    }

    function _updateReward(address account) internal virtual {
        _rewardsEarned[account] = earned(account);
        _accountRewardPerTokenPaid[account] = _rewardPerEligibleToken;
    }

    function _registerRewardDelivery(uint256 rewardAmount) internal virtual {
        _rewardPerEligibleToken += rewardAmount * scalar / _totalRewardEligibleSupply;

        emit RewardsDelivered(rewardAmount);
    }

    function _transferCANTO(address to, uint256 amount) internal virtual {
        (bool success,) = payable(to).call{value: amount}("");
        require(success, "CsrRewardsERC20: Unable to transfer CANTO, recipient may have reverted");
    }

    /// EXTERNAL MUTABLE FUNCTIONS

    /// @notice Token holder function for claiming CSR rewards
    function getReward() external virtual {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            _rewardsEarned[msg.sender] = 0;
            _accountRewardPerTokenPaid[msg.sender] = _rewardPerEligibleToken;
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

