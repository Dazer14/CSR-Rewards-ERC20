// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {RewardEligibleContract} from "../RewardEligibleContract.sol";

interface IEligibilityFaucet {
    function drip() external;
}

/// @dev Example contract that can hold CsrRewardERC20 tokens and be reward eligible
/// The faucet will need to be setup
/// Calling drip will make this contract eligible by transferring in 1 wei
contract FaucetEligibleExample is RewardEligibleContract, Ownable {
    constructor(address _csrRewardsToken, address _faucet) RewardEligibleContract(_csrRewardsToken) {
        IEligibilityFaucet(_faucet).drip(); // Made eligible
    }

    function getReward(address receiver) public override onlyOwner {
        super.getReward(receiver);
    }

    function retrieveTokens(address receiver) public override onlyOwner {
        super.retrieveTokens(receiver);
    }
}
