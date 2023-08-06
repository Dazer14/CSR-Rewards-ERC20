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
        // Transferring to EOA or contract constructor, ignore if minting in this contracts constructor
        // First time transfer to non existing contract address will make that address an eligible reward receiver
        bool eligibleTo = _rewardEligibleAddress[to];
        if (eligibleTo || (to.code.length == 0 && to != address(this))) {
            if (!eligibleTo) {
                _rewardEligibleAddress[to] = true;
            }
            _totalRewardEligibleSupply += amount;
            _rewardEligibleBalances[to] += amount;
            _updateReward(to);
        }

        // Transferring from EOA or contract holding from deploy
        if (_rewardEligibleAddress[from]) {
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

    function _transferCANTO(address to, uint amount) internal {
        (bool success, ) = payable(to).call{value: amount}("");
        require(success, "CsrRewardsERC20: Unable to send value, recipient may have reverted");
    }

    function _getReward(address account) internal {
        uint reward = rewards[account];
        if (reward > 0) {
            rewards[account] = 0;
            _transferCANTO(account, reward);
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
        require(rewardRate <= balance / rewardsDuration, "CsrRewardsERC20: Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration;
    }

    /// EXTERNAL FUNCTIONS

    /// @notice Token holder function for claiming CSR rewards
    function getReward() external nonReentrant {
        require(msg.sender == tx.origin, "CsrRewardsERC20: Only EOA");
        _updateReward(msg.sender);
        _getReward(msg.sender);
    }

    /// @notice Public function for collecting and distributing contract accumulated CSR
    function collectCSR() external nonReentrant {
        uint amountToClaim = claimableAmountCSR();
        turnstile.withdraw(csrID, payable(address(this)), amountToClaim);
        uint kickbackAmount = amountToClaim / 100;
        _notifyRewardAmount(amountToClaim - kickbackAmount);
        _transferCANTO(msg.sender, kickbackAmount);
    }

}
