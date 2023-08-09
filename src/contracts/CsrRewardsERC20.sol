// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

interface ITurnstile {
    function register(address) external returns (uint);
    function balances(uint) external view returns (uint);
    function withdraw(uint, address payable, uint) external returns (uint);
}

/**
 * @title CSR Reward Accumulating Token
 * Distributes all CSR earned to reward eligible holders
 * Logic is borrowed and modified from Synthetix StakingRewards.sol
 */
abstract contract CsrRewardsERC20 is ERC20, ReentrancyGuard {
    uint public rewardPerTokenStored; // Accumulator
    uint public rewardAmountDelivered;
    bool public rewardsDelivered;

    uint public immutable csrID;
    bool public immutable usingFee;
    uint8 public immutable feeBasisPoints;

    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;

    uint private _totalRewardEligibleSupply;
    mapping(address => uint) private _rewardEligibleBalances;
    mapping(address => bool) private _rewardEligibleAddress;

    ITurnstile public turnstile = ITurnstile(0xEcf044C5B4b867CFda001101c617eCd347095B44);

    constructor(
        bool _usingFee,
        uint8 _feeBasisPoints
    ) {
        usingFee = _usingFee;
        feeBasisPoints = _feeBasisPoints;

        csrID = turnstile.register(address(this));
    }

    receive() external payable {
        require(
            msg.sender == address(turnstile), 
            "CsrRewardsERC20: Only turnstile transfers will be processed for rewards"
        );
    }

    /// VIEW FUNCTIONS

    function totalRewardEligibleSupply() external view returns (uint) {
        return _totalRewardEligibleSupply;
    }

    function rewardEligibleBalanceOf(address account) external view returns (uint) {
        return _rewardEligibleBalances[account];
    }

    function rewardPerToken() public view returns (uint) {
        if (_totalRewardEligibleSupply == 0) {
            return rewardPerTokenStored;
        }

        if (rewardsDelivered) {
            // This condition is only true briefly between reward delivery and the next transfer or reward delivery call (could happen if only approves occur)
            // Perhaps the new accumulator value can be updated once on delivery and this function is simplified to just return the accumulator 
            // Then this function can be eliminated in favor of just referencing the accumulator
            return rewardPerTokenStored + (rewardAmountDelivered * 1e18 / _totalRewardEligibleSupply);
        } else {
            return rewardPerTokenStored;
        }

    }

    function earned(address account) public view returns (uint) {
        return rewards[account] +
        (
            _rewardEligibleBalances[account]
            * (rewardPerToken() - userRewardPerTokenPaid[account])
            / 1e18
        );
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
         * Contract addresses will have code size 0 before and during deploy
         * Any method that sends this token to that address will make the contract reward eligible
         * NB Self-minting in constructor makes this contract reward eligible
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

    function _updateReward(address account) private {
        // Users would not need to be responsible for updating the accumulator then
        // It would update only when rewards are added
        // This function would just update a users {reward} entry and their stored accumulator value
        rewardPerTokenStored = rewardPerToken();
        if (rewardsDelivered) rewardsDelivered = false;
        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }

    function _registerRewardDelivery(uint rewardAmount) private {
        // Is this absolutely needed?
        // I think the reality of this line is that {rewardPerToken} is always returning the current value of {rewardPerTokenStored}
        // Possibly, if withdraw from turnstile is called twice before update is called, then the wrong reward delivery amount would be stored, would overwrite it
        // 
        // What can possibly be done instead is to run the accumulator update here
        // Wouldn't need to store rewardAmountDelivered either
        rewardPerTokenStored = rewardPerToken();
        rewardAmountDelivered = rewardAmount;
        // Possible to do away with flag and do update logic here?
        // Do we have to wait until next block/transfer?
        rewardsDelivered = true;
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
            _registerRewardDelivery(amountToClaim - feeAmount);
            _transferCANTO(msg.sender, feeAmount);
        } else {
            _registerRewardDelivery(amountToClaim);
        }
    }

}
