// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

interface Turnstile {
    function register(address) external returns (uint);
    function balances(uint) external view returns (uint);
    function withdraw(uint _tokenId, address payable _recipient, uint _amount) external returns (uint);
}

/**
 * @title CSR Reward Accumulating Token
 * Evenly distributes all CSR earned to reward eligible holders
 * Logic is borrowed and modified from Synthetix Staking Rewards
 */
abstract contract CsrRewardsERC20 is ERC20, ReentrancyGuard {
    uint public rewardsDuration = 1 minutes;
    uint public periodFinish;
    uint public rewardRate;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;

    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;

    uint private _totalRewardEligibleSupply;
    mapping(address => uint) private _rewardEligibleBalances;
    mapping(address => bool) private _rewardEligibleAddress;

    uint public immutable csrID;
    bool public immutable usingFee;
    uint8 public immutable feeBasisPoints;

    Turnstile public turnstile = Turnstile(0xEcf044C5B4b867CFda001101c617eCd347095B44);

    constructor(
        bool _usingFee,
        uint8 _feeBasisPoints
    ) {
        csrID = turnstile.register(address(this));

        if (_usingFee) {
            usingFee = true;
            feeBasisPoints = _feeBasisPoints;
        }
    }

    receive() external payable {}

    /// VIEW FUNCTIONS

    function totalRewardEligibleSupply() external view returns (uint) {
        return _totalRewardEligibleSupply;
    }

    function rewardEligibleBalanceOf(address account) external view returns (uint) {
        return _rewardEligibleBalances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken() public view returns (uint) {
        if (_totalRewardEligibleSupply == 0) {
            return rewardPerTokenStored;
        }
        // SafeMath => checked arithmatic, needs review
        return rewardPerTokenStored + 
            ((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18 / _totalRewardEligibleSupply);
    }

    function earned(address account) public view returns (uint) {
        // SafeMath => checked arithmatic, needs review
        return (_rewardEligibleBalances[account] * (rewardPerToken() - userRewardPerTokenPaid[account]) / 1e18) + rewards[account];
    }

    function getRewardForDuration() external view returns (uint) {
        return rewardRate * rewardsDuration;
    }

    function turnstileBalance() public view returns (uint) {
        return turnstile.balances(csrID);
    }

    /// INTERNAL FUNCTIONS

    function _increaseRewardEligibleBalance(address to, uint amount) private {
        _totalRewardEligibleSupply += amount;
        _rewardEligibleBalances[to] += amount;
        _updateReward(to);
    }

    function _beforeTokenTransfer(address from, address to, uint amount) internal virtual override {
        /**
         * @dev First time transfer to address with code size 0 will register as reward eligible
         * Contracts will have code size 0 while being deployed so can auto-whitelist by receiving tokens in constructor
         */

        if (_rewardEligibleAddress[to]) {
            _increaseRewardEligibleBalance(to, amount);
        } else {
            if (to.code.length == 0 && to != address(this)) {
                _increaseRewardEligibleBalance(to, amount);
                _rewardEligibleAddress[to] = true;
            }
        }

        if (_rewardEligibleAddress[from]) {
            _totalRewardEligibleSupply -= amount;
            _rewardEligibleBalances[from] -= amount;
            _updateReward(from);
        }
    }

    function _updateReward(address account) private {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
    }

    function _transferCANTO(address to, uint amount) internal {
        (bool success, ) = payable(to).call{value: amount}("");
        require(success, "CsrRewardsERC20: Unable to send value, recipient may have reverted");
    }

    function _getReward(address account) private {
        uint reward = rewards[account];
        if (reward > 0) {
            rewards[account] = 0;
            _transferCANTO(account, reward);
        }
    }

    function _notifyRewardAmount(uint reward) private {
        _updateReward(address(0));

        // SafeMath => checked arithmatic, needs review
        if (block.timestamp >= periodFinish) {
            rewardRate = reward / rewardsDuration;
        } else {
            uint remaining = periodFinish - block.timestamp;
            uint leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / rewardsDuration;
        }

        uint balance = address(this).balance;
        // This check might not be needed
        require(rewardRate <= balance / rewardsDuration, "CsrRewardsERC20: Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration;
    }

    /// MUTABLE FUNCTIONS

    /// @notice Token holder function for claiming CSR rewards
    function getReward() external nonReentrant {
        _updateReward(msg.sender);
        _getReward(msg.sender);
    }

    /// @notice Public function for collecting and distributing contract accumulated CSR
    function collectCSR() external nonReentrant {
        uint amountToClaim = turnstileBalance();

        turnstile.withdraw(csrID, payable(address(this)), amountToClaim);

        if (usingFee) {
            uint feeAmount = amountToClaim * feeBasisPoints / 10000;
            _notifyRewardAmount(amountToClaim - feeAmount);
            _transferCANTO(msg.sender, feeAmount);
        } else {
            _notifyRewardAmount(amountToClaim);
        }
    }

}
