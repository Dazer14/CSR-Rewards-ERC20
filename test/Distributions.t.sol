// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseTest.sol";

// 1. Multiple Distributions Without Transfers: Test the case where multiple distributions occur without any transfers in between. This will help ensure that the contract correctly handles multiple distributions.

// 2. Multiple Distributions With Transfers In Between: Test the case where multiple distributions occur with transfers in between. This will help ensure that the contract correctly handles distributions and transfers in combination.

// 3. Multiple Distributions With Various Amounts: Test the case where multiple distributions occur with varying amounts. This will help ensure that the contract correctly handles distributions of different sizes.

// 4. Multiple Distributions With Various Fractions: Test the case where multiple distributions occur with varying fractions. This will help ensure that the contract correctly handles distributions with different fractions.

// 5. Multiple Distributions With Various Users: Test the case where multiple distributions occur involving different users. This will help ensure that the contract correctly handles distributions involving different users.

// 6. Multiple Distributions With Various Contracts: Test the case where multiple distributions occur involving different contracts. This will help ensure that the contract correctly handles distributions involving different contracts.

// 7. Multiple Distributions With Various Timing: Test the case where multiple distributions occur at different times. This will help ensure that the contract correctly handles distributions that occur at different times.

// 8. Multiple Distributions With Various Order of Operations: Test the case where multiple distributions occur with different orders of operations. This will help ensure that the contract correctly handles distributions that occur in different orders.
contract Distributions is BaseTest {
    function testMultipleDistributionsWithoutTransfers(uint256 amountToDistribute1, uint256 amountToDistribute2, uint256 amountToDistribute3) external {
        // Distribute and withdraw rewards from turnstile
        _distributeAndWithdraw(amountToDistribute1);
        _distributeAndWithdraw(amountToDistribute2);
        _distributeAndWithdraw(amountToDistribute3);

        // Compute the fraction of the eligible supply user1 has and compare to fraction of rewards received
        _assertEarnedRewards(user1, amountToDistribute1 + amountToDistribute2 + amountToDistribute3);
    }

    function testDistributionsWithTransfers(uint256 amountToDistribute1, uint256 amountToDistribute2, uint16 fractionToTransfer1, uint16 fractionToTransfer2) external {
        _validateFraction(fractionToTransfer1);
        _validateFraction(fractionToTransfer2);

        uint256[] memory distributionAmounts1 = new uint256[](1);
        distributionAmounts1[0] = amountToDistribute1;
        (uint256 user1RewardsDist1, uint256 user2RewardsDist1,) = _transferAndDistributeMultiple(user1, user2, fractionToTransfer1, distributionAmounts1);

        uint256[] memory distributionAmounts2 = new uint256[](1);
        distributionAmounts2[0] = amountToDistribute2;
        (uint256 user1RewardsDist2, uint256 user2RewardsDist2,) = _transferAndDistributeMultiple(user1, user2, fractionToTransfer2, distributionAmounts2);
        
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
        (uint256 user1RewardsDist1, uint256 user2RewardsDist1,) = _transferAndDistributeMultiple(user1, user2, fractionToTransfer1, distributionAmounts1);

        uint256[] memory distributionAmounts2 = new uint256[](2);
        distributionAmounts2[0] = amountToDistribute3;
        distributionAmounts2[1] = amountToDistribute4;
        (uint256 user1RewardsDist2, uint256 user2RewardsDist2,) = _transferAndDistributeMultiple(user1, user2, fractionToTransfer2, distributionAmounts2);

        assertEq(token.earned(user1), user1RewardsDist1 + user1RewardsDist2);
        assertEq(token.earned(user2), user2RewardsDist1 + user2RewardsDist2);
    }

    // Multiple Distributions With Various Contracts
    // function testMultipleDistributionsBetweenTransfersFromEOAandBothContractTypes(
    //     uint256 amountToDistribute1, 
    //     uint256 amountToDistribute2, 
    //     uint256 amountToDistribute3, 
    //     uint256 amountToDistribute4, 
    //     uint16 fractionToTransfer1, 
    //     uint16 fractionToTransfer2
    // ) external {
    //     _validateFraction(fractionToTransfer1);
    //     _validateFraction(fractionToTransfer2);

    //     // Deploy a new instance of RewardEligibleContract
    //     address rewardEligibleContract = address(new RewardEligibleContract(address(faucet)));
    //     // Define a local existingContract variable
    //     address existingContract = turnstile;        

    //     // User1 to existing contract
    //     uint256[] memory distributionAmounts1 = new uint256[](2);
    //     distributionAmounts1[0] = amountToDistribute1;
    //     distributionAmounts1[1] = amountToDistribute2;
    //     (uint256 user1RewardsDist1, , uint256 totalDistributed1) = _transferAndDistributeMultiple(user1, existingContract, fractionToTransfer1, distributionAmounts1);
    //     uint256 rewardEligibleContractRewardsDist1 = _calculateRewardsByEligibleBalance(totalDistributed1, rewardEligibleContract);

    //     // Existing to Eligible
    //     uint256[] memory distributionAmounts2 = new uint256[](2);
    //     distributionAmounts2[0] = amountToDistribute3;
    //     distributionAmounts2[1] = amountToDistribute4;
    //     (, uint256 rewardEligibleContractRewardsDist2, uint256 totalDistributed2) = _transferAndDistributeMultiple(existingContract, rewardEligibleContract, fractionToTransfer2, distributionAmounts2);
    //     uint256 user1RewardsDist2 = _calculateRewardsByEligibleBalance(totalDistributed2, user1);

    //     assertEq(token.earned(user1), user1RewardsDist1 + user1RewardsDist2);
    //     assertEq(token.earned(existingContract), 0);
    //     assertEq(token.earned(rewardEligibleContract), rewardEligibleContractRewardsDist1 + rewardEligibleContractRewardsDist2);
    // }

    // Multiple Distributions With Various Order of Operations
}