// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Assume CsrRewardsERC20 token is already deployed
// This contract wants to become reward eligible
// Using Create2 opcode, will be able to get the deploy address
// Ideally, store the address and have function that sends a single wei of the token
// Would need to load small amount

interface ICsrRewardsERC20 {
    function earned(address account) external view returns (uint);
    function getReward() external;
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract RewardEligibleContract {
    address private immutable _csrRewardsToken;
    address public immutable owner;

    constructor(address csrRewardsToken_) {
        _csrRewardsToken = csrRewardsToken_;
        owner = msg.sender;
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
