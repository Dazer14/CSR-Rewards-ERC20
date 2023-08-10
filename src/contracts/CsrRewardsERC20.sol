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
    uint public rewardPerTokenStored; // Global Accumulator

    uint public immutable csrID;
    bool public immutable usingWithdrawCallFee;
    uint16 public immutable withdrawCallFeeBasisPoints;

    mapping(address => uint) public userRewardPerTokenPaid; // Account Accumulator
    mapping(address => uint) public rewardsEarned;

    uint private _totalRewardEligibleSupply;
    mapping(address => uint) private _rewardEligibleBalances;
    mapping(address => bool) private _rewardEligibleAddress;

    ITurnstile public constant TURNSTILE = ITurnstile(0xEcf044C5B4b867CFda001101c617eCd347095B44);

    constructor(
        bool _usingWithdrawCallFee,
        uint16 _withdrawCallFeeBasisPoints
    ) {
        usingWithdrawCallFee = _usingWithdrawCallFee;
        withdrawCallFeeBasisPoints = _withdrawCallFeeBasisPoints;

        csrID = TURNSTILE.register(address(this));
    }

    receive() external payable {
        require(
            msg.sender == address(TURNSTILE), 
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

    function earned(address account) public view returns (uint) {
        return rewardsEarned[account] +
        (
            _rewardEligibleBalances[account]
            * _getAccountAccumulatorDifference(account)
            / 1e18
        );
    }

    function turnstileBalance() public view returns (uint) {
        return TURNSTILE.balances(csrID);
    }

    /// INTERNAL FUNCTIONS

    function _transferCANTO(address to, uint amount) internal {
        (bool success, ) = payable(to).call{value: amount}("");
        require(success, "CsrRewardsERC20: Unable to send value, recipient may have reverted");
    }

    function _afterTokenTransfer(address from, address to, uint amount) internal virtual override {
        /// @dev First time transfer to address with code size 0 will register as reward eligible
        /// Contract addresses will have code size 0 before and during deploy
        /// Any method that sends this token to that address will make the contract reward eligible
        /// NB Self-minting in constructor makes this contract reward eligible
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
        rewardsEarned[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }

    function _getAccountAccumulatorDifference(address account) private view returns (uint) {
        if (userRewardPerTokenPaid[account] <= rewardPerTokenStored) {
            return rewardPerTokenStored - userRewardPerTokenPaid[account];
        } else {
            /// @dev Overflow result is stored in global accumulator
            /// Account accumulator value will only be greater than global accumulator when overflow has occurred
            /// So have to return the 'difference' wrapping around maximum uint256 value
            return type(uint).max - userRewardPerTokenPaid[account] + rewardPerTokenStored;
        }
    }

    function _registerRewardDelivery(uint rewardAmount) private {
        /// @dev Accumulator should overflow
        unchecked { rewardPerTokenStored += rewardAmount * 1e18 / _totalRewardEligibleSupply; }
    }

    /// MUTABLE EXTERNAL FUNCTIONS

    /// @notice Token holder function for claiming CSR rewards
    function getReward() external nonReentrant {
        _updateReward(msg.sender);
        uint reward = rewardsEarned[msg.sender];
        if (reward > 0) {
            rewardsEarned[msg.sender] = 0;
            _transferCANTO(msg.sender, reward);
        }
    }

    /// @notice Public function for collecting and distributing contract accumulated CSR
    function withdrawFromTurnstile() external nonReentrant {
        uint amountToClaim = turnstileBalance();
        require(amountToClaim > 0, "CsrRewardsERC20: No CSR to claim");

        TURNSTILE.withdraw(csrID, payable(address(this)), amountToClaim);

        if (usingWithdrawCallFee) {
            uint feeAmount = amountToClaim * withdrawCallFeeBasisPoints / 10000;
            _registerRewardDelivery(amountToClaim - feeAmount);
            _transferCANTO(msg.sender, feeAmount);
        } else {
            _registerRewardDelivery(amountToClaim);
        }
    }

}
