// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseTest.sol";

contract Distributions is BaseTest {
    function testMultipleDistributionsWithoutTransfers(
        uint256 amountToDistribute1, 
        uint256 amountToDistribute2, 
        uint256 amountToDistribute3
    ) external {
        // Distribute and withdraw rewards from turnstile
        _distributeAndWithdraw(amountToDistribute1);
        _distributeAndWithdraw(amountToDistribute2);
        _distributeAndWithdraw(amountToDistribute3);

        // Compute the fraction of the eligible supply user1 has and compare to fraction of rewards received
        _assertEarnedRewards(user1, amountToDistribute1 + amountToDistribute2 + amountToDistribute3);
    }

    function testDistributionsWithTransfers(
        uint256 amountToDistribute1, 
        uint256 amountToDistribute2, 
        uint16 fractionToTransfer1, 
        uint16 fractionToTransfer2
    ) external {
        _validateFraction(fractionToTransfer1);
        _validateFraction(fractionToTransfer2);

        uint256[] memory distributionAmounts1 = new uint256[](1);
        distributionAmounts1[0] = amountToDistribute1;
        (
            uint256 user1RewardsDist1, 
            uint256 user2RewardsDist1
        ) = _transferAndDistributeMultiple(
            user1, 
            user2, 
            fractionToTransfer1, 
            distributionAmounts1
        );

        uint256[] memory distributionAmounts2 = new uint256[](1);
        distributionAmounts2[0] = amountToDistribute2;
        (
            uint256 user1RewardsDist2, 
            uint256 user2RewardsDist2
        ) = _transferAndDistributeMultiple(
            user1, 
            user2, 
            fractionToTransfer2, 
            distributionAmounts2
        );
        assertEq(token.earned(user1), user1RewardsDist1 + user1RewardsDist2);
        assertEq(token.earned(user2), user2RewardsDist1 + user2RewardsDist2);
    }

    function testMultipleDistributionsBetweenTransfers(
        uint256 amountToDistribute1, 
        uint256 amountToDistribute2, 
        uint256 amountToDistribute3, 
        uint256 amountToDistribute4, 
        uint16 fractionToTransfer1, 
        uint16 fractionToTransfer2
    ) external {
        _validateFraction(fractionToTransfer1);
        _validateFraction(fractionToTransfer2);

        uint256[] memory distributionAmounts1 = new uint256[](2);
        distributionAmounts1[0] = amountToDistribute1;
        distributionAmounts1[1] = amountToDistribute2;
        (
            uint256 user1RewardsDist1, 
            uint256 user2RewardsDist1
        ) = _transferAndDistributeMultiple(
            user1, 
            user2, 
            fractionToTransfer1, 
            distributionAmounts1
        );

        uint256[] memory distributionAmounts2 = new uint256[](2);
        distributionAmounts2[0] = amountToDistribute3;
        distributionAmounts2[1] = amountToDistribute4;
        (
            uint256 user1RewardsDist2, 
            uint256 user2RewardsDist2
        ) = _transferAndDistributeMultiple(
            user1, 
            user2, 
            fractionToTransfer2, 
            distributionAmounts2
        );

        assertEq(token.earned(user1), user1RewardsDist1 + user1RewardsDist2);
        assertEq(token.earned(user2), user2RewardsDist1 + user2RewardsDist2);
    }

    // Multiple Distributions With Various Contracts
    function testMultipleDistributionsBetweenTransfersFromEOAandBothContractTypes(
        uint256 amountToDistribute1, 
        uint256 amountToDistribute2, 
        uint256 amountToDistribute3, 
        uint256 amountToDistribute4, 
        uint16 fractionToTransfer1, 
        uint16 fractionToTransfer2
    ) external {
        _validateFraction(fractionToTransfer1);
        _validateFraction(fractionToTransfer2);

        // Deploy a new instance of RewardEligibleContract
        address rewardEligibleContract = address(new RewardEligibleContract(address(faucet)));
        // Define a local existingContract variable
        address existingContract = turnstile;        

        // User1 to existing contract
        uint256[] memory distributionAmounts1 = new uint256[](2);
        distributionAmounts1[0] = amountToDistribute1;
        distributionAmounts1[1] = amountToDistribute2;
        (uint256 user1RewardsDist1,) = _transferAndDistributeMultiple(
            user1, 
            existingContract, 
            fractionToTransfer1, 
            distributionAmounts1
        );
        assertEq(token.earned(user1), user1RewardsDist1);

        // Existing to Eligible
        uint256[] memory distributionAmounts2 = new uint256[](2);
        distributionAmounts2[0] = amountToDistribute3;
        distributionAmounts2[1] = amountToDistribute4;
        (, uint256 rewardEligibleContractRewardsDist2) = _transferAndDistributeMultiple(
            existingContract, 
            rewardEligibleContract, 
            fractionToTransfer2, 
            distributionAmounts2
        );

        assertEq(token.earned(existingContract), 0);
        assertEq(token.earned(rewardEligibleContract), rewardEligibleContractRewardsDist2);
    }

    // Test sending CANTO to contract
    function testUserEarnsRewardsFromExternalCANTOSend(uint256 amountToSend) external {
        _sendCANTOToTokenContract(amountToSend);

        // Compute the fraction of the eligible supply user1 has and compare to fraction of rewards received
        _assertEarnedRewards(user1, amountToSend);
    }

    function testUsersEarnRewardsFromMultipleExternalCANTOSends(
        uint256 amountToSend1, 
        uint256 amountToSend2, 
        uint256 amountToSend3
    ) external {
        // Send CANTO to the contract three times
        _sendCANTOToTokenContract(amountToSend1);
        _sendCANTOToTokenContract(amountToSend2);
        _sendCANTOToTokenContract(amountToSend3);

        // Compute the fraction of the eligible supply each user has and compare to fraction of rewards received
        uint256 totalSent = amountToSend1 + amountToSend2 + amountToSend3;
        _assertEarnedRewards(user1, totalSent);
        _assertEarnedRewards(user2, totalSent);
    }
}