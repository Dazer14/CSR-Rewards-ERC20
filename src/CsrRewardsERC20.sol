// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface Turnstile {
    function register(address) external returns (uint);
    function balances(uint) external view returns (uint);
    function withdraw(uint _tokenId, address payable _recipient, uint _amount) external returns (uint);
}

/**
 * @title CSR Reward Accumulating Token
 * Distributes all CSR earned to reward eligible holders
 * Logic is borrowed and modified from Synthetix Staking Rewards
 */
abstract contract CsrRewardsERC20 is ERC20, ReentrancyGuard {
    uint public rewardsDuration = 1 seconds;
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
        usingFee = _usingFee;
        feeBasisPoints = _feeBasisPoints;

        csrID = turnstile.register(address(this));
    }

    receive() external payable {
        require(msg.sender == address(turnstile), "CsrRewardsERC20: Only turnstile transfers will be processed for rewards");
    }

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

    function turnstileBalance() public view returns (uint) {
        return turnstile.balances(csrID);
    }

    /// INTERNAL FUNCTIONS

    function _transferCANTO(address to, uint amount) internal {
        (bool success, ) = payable(to).call{value: amount}("");
        require(success, "CsrRewardsERC20: Unable to send value, recipient may have reverted");
    }

    function _afterTokenTransfer(address from, address to, uint amount) internal virtual override {
        /**
         * @dev First time transfer to address with code size 0 will register as reward eligible
         * Contracts will have code size 0 while being deployed so can auto-whitelist by receiving tokens in constructor
         */
        if (_rewardEligibleAddress[to]) {
            _increaseRewardEligibleBalance(to, amount);
        } else {
            if (to.code.length == 0) {
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

    function _increaseRewardEligibleBalance(address to, uint amount) private {
        _updateReward(to);
        _totalRewardEligibleSupply += amount;
        _rewardEligibleBalances[to] += amount;
    }

    function _notifyRewardAmount(uint reward) private {
        // Should be able to replace this with just {rewardPerTokenStored = rewardPerToken();} to avoid extra write
        _updateReward(address(0));

        // SafeMath => checked arithmatic, needs review
        if (block.timestamp >= periodFinish) {
            rewardRate = reward / rewardsDuration;
        } else {
            // Dead code??
            uint remaining = periodFinish - block.timestamp;
            uint leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / rewardsDuration;
        }

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration;
    }

    function _updateReward(address account) private {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
    }

    /// MUTABLE EXTERNAL FUNCTIONS

    /// @notice Token holder function for claiming CSR rewards
    function getReward() external nonReentrant {
        _updateReward(msg.sender);
        uint reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            _transferCANTO(msg.sender, reward);
        }
    }

    /// @notice Public function for collecting and distributing contract accumulated CSR
    function withdrawFromTurnstile() external nonReentrant {
        require(msg.sender == tx.origin, "CsrRewardsERC20: Only EOA can withdraw from turnstile");
        uint amountToClaim = turnstileBalance();
        require(amountToClaim > 0, "CsrRewardsERC20: No CSR to claim");

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
