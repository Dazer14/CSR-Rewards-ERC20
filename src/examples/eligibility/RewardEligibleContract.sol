// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import "../../contracts/ICsrRewardsERC20.sol";

abstract contract RewardEligibleContract {
    address public immutable csrRewardsToken;

    constructor(address _csrRewardsToken) {
        csrRewardsToken = _csrRewardsToken;
    }

    receive() external payable {}

    /// VIEW

    function rewardAmountEarned() public view returns (uint) {
        return ICsrRewardsERC20(csrRewardsToken).earned(address(this));
    }

    function tokenBalance() public view returns (uint) {
        return IERC20(csrRewardsToken).balanceOf(address(this));
    }

    /// MUTATE

    function getReward(address receiver) public virtual {
        ICsrRewardsERC20(csrRewardsToken).getReward();
        (bool success, ) = payable(receiver).call{value: address(this).balance}("");
        require(success, "Unable to send value, recipient may have reverted");
    }

    function retrieveTokens(address receiver) public virtual {
        IERC20(csrRewardsToken).transfer(receiver, tokenBalance());
    }

}