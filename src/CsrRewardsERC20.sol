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
 * @author DAZER
 * ERC20 extended to evenly distribute CSR to non-contract token holders
 * Logic is borrowed and modified from Synthetix Staking Rewards
 */
contract CsrRewardsERC20 is ERC20, ReentrancyGuard {
    // Distribute over 1 day to prevent claim manipulation
    uint public rewardsDuration = 1 days;
    uint public periodFinish;

    uint public rewardRate;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;

    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;

    uint private _totalRewardEligibleSupply;
    mapping(address => uint) private _rewardEligibleBalances;

    uint public immutable csrID;

    Turnstile public turnstile = Turnstile(0xEcf044C5B4b867CFda001101c617eCd347095B44);

    constructor(
        string memory _name, 
        string memory _symbol,
        uint _totalSupply
    ) ERC20(_name, _symbol) {
        _mint(msg.sender, _totalSupply);
        csrID = turnstile.register(address(this));
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
        return rewardPerTokenStored + 
            ((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18 / _totalRewardEligibleSupply);
    }

    function earned(address account) public view returns (uint) {
        return (_rewardEligibleBalances[account] * (rewardPerToken() - userRewardPerTokenPaid[account]) / 1e18) + rewards[account];
    }

    function getRewardForDuration() external view returns (uint) {
        return rewardRate * rewardsDuration;
    }

    function claimableAmountCSR() public view returns (uint) {
        return turnstile.balances(csrID);
    }

    /// INTERNAL FUNCTIONS

    function _beforeTokenTransfer(address from, address to, uint amount) internal virtual override {
        // Transferring to EOA
        if (to.code.length == 0) {
            _totalRewardEligibleSupply += amount;
            _rewardEligibleBalances[to] += amount;
            _updateReward(to);
        }

        // Transferring from EOA or contract holding from deploy, ignore mint
        bool transferringFromEOA = from.code.length == 0;
        if ((from != address(0)) && (transferringFromEOA || (!transferringFromEOA && _rewardEligibleBalances[from] > 0))) { 
            _totalRewardEligibleSupply -= amount;
            _rewardEligibleBalances[from] -= amount;
            _updateReward(from);
            _getReward(from);
        }
    }

    function _updateReward(address account) internal {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
    }

    function _getReward(address account) internal {
        uint reward = rewards[account];
        if (reward > 0) {
            rewards[account] = 0;
            (bool success, ) = payable(account).call{value: reward}("");
            require(success, "CsrRewardsERC20: unable to send value, recipient may have reverted");
        }
    }

    function _notifyRewardAmount(uint reward) internal {
        _updateReward(address(0));

        if (block.timestamp >= periodFinish) {
            rewardRate = reward / rewardsDuration;
        } else {
            uint remaining = periodFinish - block.timestamp;
            uint leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / rewardsDuration;
        }

        uint balance = address(this).balance;
        require(rewardRate <= balance / rewardsDuration, "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration;
    }

    /// EXTERNAL FUNCTIONS

    /// @notice Token holder function for claiming CSR rewards
    function getReward() external nonReentrant {
        _updateReward(msg.sender);
        _getReward(msg.sender);
    }

    /// @notice Public function for collecting and distributing contract accumulated CSR
    function collectCSR() external nonReentrant {
        uint amountToClaim = claimableAmountCSR();
        turnstile.withdraw(csrID, payable(address(this)), amountToClaim);
        uint kickbackAmount = amountToClaim / 100; // 1%
        _notifyRewardAmount(amountToClaim - kickbackAmount);
        (bool success, ) = payable(msg.sender).call{value: kickbackAmount}("");
        require(success, "CsrRewardsERC20: unable to send value, recipient may have reverted");
    }

}
