// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICsrRewardsERC20 {
    function earned(address account) external view returns (uint);
    function getReward() external;
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IEligibilityFaucet {
    function drip() external;
}

/// @dev This demonstates a custom contract that can hold CsrRewardERC20 tokens and be reward eligible
/// The eligibility faucet will have to be setup before then calling drip will make this contract eligible
contract FaucetEligibleContract {
    address private immutable _csrRewardsToken;
    address public immutable owner;

    constructor(address csrRewardsToken_, address _owner, address faucet) {
        _csrRewardsToken = csrRewardsToken_;
        owner = _owner;

        IEligibilityFaucet(faucet).drip(); // Made eligible
    }

    receive() external payable {}

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    function rewardAmountEarned() public view returns (uint) {
        return ICsrRewardsERC20(_csrRewardsToken).earned(address(this));
    }

    function tokenBalance() public view returns (uint) {
        return IERC20(_csrRewardsToken).balanceOf(address(this));
    }

    function getReward(address receiver) external onlyOwner {
        uint rewardAmount = rewardAmountEarned();
        ICsrRewardsERC20(_csrRewardsToken).getReward();
        (bool success, ) = payable(receiver).call{value: rewardAmount}("");
        require(success, "Unable to send value, recipient may have reverted");
    }

    function retrieveTokens(address receiver) external onlyOwner {
        uint balance = tokenBalance();
        IERC20(_csrRewardsToken).transfer(receiver, balance);
    }

}
