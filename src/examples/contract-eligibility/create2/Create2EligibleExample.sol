// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/access/Ownable.sol";
import "openzeppelin/access/Ownable.sol";

import "../RewardEligibleContract.sol";

/// @dev This would be deployed by the Create2 factory
contract Create2EligibleExample is RewardEligibleContract, Ownable {
    constructor(
        address _csrRewardsToken, 
        address _owner
    ) RewardEligibleContract(_csrRewardsToken) {
        _transferOwnership(_owner);
    }

    function getReward(address receiver) public override onlyOwner {
        super.getReward(receiver);
    }

    function retrieveTokens(address receiver) public override onlyOwner {
        super.retrieveTokens(receiver);
    }

}
