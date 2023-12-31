// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseTest.sol";

contract Contracts is BaseTest {
    function testBasicTransferToExistingContract(uint16 fractionToTransfer) external {
        _validateFraction(fractionToTransfer);
        // Capture the total eligible supply before the transfer
        uint256 totalEligibleSupplyBefore = token.totalRewardEligibleSupply();
        // Define a local existingContract variable
        address existingContract = turnstile;
        // Prank a transfer from user1 to existingContract
        _transfer(user1, existingContract, _amountToTransfer(user1, fractionToTransfer));
        // Capture the total eligible supply after the transfer
        uint256 totalEligibleSupplyAfter = token.totalRewardEligibleSupply();
        // Assert that the balance of user1 and existingContract are as expected
        _assertRewardEligibleBalance(user1, token.balanceOf(user1));
        _assertRewardEligibleBalance(existingContract, 0);
        // Assert that the total eligible supply has been updated properly
        assertEq(totalEligibleSupplyBefore - totalEligibleSupplyAfter, token.balanceOf(turnstile));
    }

    function testTransferToAndFromExistingContract(uint16 fractionToTransfer1, uint16 fractionToTransfer2) external {
        _validateFraction(fractionToTransfer1);
        _validateFraction(fractionToTransfer2);
        // Capture the total eligible supply before the transfers
        uint256 totalEligibleSupplyBefore = token.totalRewardEligibleSupply();
        // Prank a transfer from user1 to existingContract
        _transfer(user1, turnstile, _amountToTransfer(user1, fractionToTransfer1));
        // Prank a transfer from existingContract to user2
        _transfer(turnstile, user2, _amountToTransfer(turnstile, fractionToTransfer2));
        // Capture the total eligible supply after the transfers
        uint256 totalEligibleSupplyAfter = token.totalRewardEligibleSupply();
        // Compute the fraction of the eligible supply each user has and compare to fraction of rewards received
        _assertRewardEligibleBalance(user1, token.balanceOf(user1));
        _assertRewardEligibleBalance(turnstile, 0);
        _assertRewardEligibleBalance(user2, token.balanceOf(user2));
        // Assert that the total eligible supply has been updated properly
        assertEq(totalEligibleSupplyBefore - totalEligibleSupplyAfter, token.balanceOf(turnstile));
    }

    function testCorrectRewardsReceivedAfterTransfer(
        uint256 amountToDistribute, 
        uint16 fractionToTransfer1, 
        uint16 fractionToTransfer2
    ) external {
        _validateFraction(fractionToTransfer1);
        _validateFraction(fractionToTransfer2);
        // Prank a transfer from user1 to turnstile
        _transfer(user1, turnstile, _amountToTransfer(user1, fractionToTransfer1));
        // Prank a transfer from turnstile to user2
        _transfer(turnstile, user2, _amountToTransfer(turnstile, fractionToTransfer2));
        // Distribute and withdraw rewards from turnstile
        _distributeAndWithdraw(amountToDistribute);
        // Compute the fraction of the eligible supply each user has and compare to fraction of rewards received
        _assertEarnedRewards(user1, amountToDistribute);
        _assertEarnedRewards(user2, amountToDistribute);
        assertEq(token.earned(turnstile), 0); // turnstile should not earn rewards
    }

    function testCanSetupRewardEligibleContract() external {
        // Deploy a new instance of RewardEligibleContract
        address rewardEligibleContract = address(new RewardEligibleContract(address(faucet)));
        // Assert that the new contract has a balance of 1 token
        _assertBalance(rewardEligibleContract, 1);
    }

    function testRewardEligibleContractCanEarnRewards(uint256 amountToDistribute, uint16 fractionToTransfer) external {
        _validateFraction(fractionToTransfer);
        // Deploy a new instance of RewardEligibleContract
        address rewardEligibleContract = address(new RewardEligibleContract(address(faucet)));
        // Prank a transfer from user1 to rewardEligibleContract
        _transfer(user1, rewardEligibleContract, _amountToTransfer(user1, fractionToTransfer));
        // Distribute and withdraw rewards from turnstile
        _distributeAndWithdraw(amountToDistribute);
        // Compute the fraction of the eligible supply the contract has and compare to fraction of rewards received
        _assertRewardEligibleBalance(rewardEligibleContract, token.balanceOf(rewardEligibleContract));
        _assertEarnedRewards(rewardEligibleContract, amountToDistribute);
        // Compute the fraction of the eligible supply user1 has and compare to fraction of rewards received
        _assertRewardEligibleBalance(user1, token.balanceOf(user1));
        _assertEarnedRewards(user1, amountToDistribute);
    }

    function testTransfersBetweenEOAandBothContractTypes(
        uint256 amountToDistribute, 
        uint16 fractionToTransfer1, 
        uint16 fractionToTransfer2
    ) external {
        _validateFraction(fractionToTransfer1);
        _validateFraction(fractionToTransfer2);
        // Deploy a new instance of RewardEligibleContract
        address rewardEligibleContract = address(new RewardEligibleContract(address(faucet)));
        address existingContract = turnstile;
        // Prank a transfer from user1 to existingContract
        _transfer(user1, existingContract, _amountToTransfer(user1, fractionToTransfer1));
        // Prank a transfer from existingContract to rewardEligibleContract
        _transfer(existingContract, rewardEligibleContract, _amountToTransfer(existingContract, fractionToTransfer2));
        // Distribute and withdraw rewards from turnstile
        _distributeAndWithdraw(amountToDistribute);
        // Compute the fraction of the eligible supply each account has and compare to fraction of rewards received
        _assertRewardEligibleBalance(user1, token.balanceOf(user1));
        _assertEarnedRewards(user1, amountToDistribute);

        _assertRewardEligibleBalance(existingContract, 0);
        assertEq(token.earned(existingContract), 0);

        _assertRewardEligibleBalance(rewardEligibleContract, token.balanceOf(rewardEligibleContract));
        _assertEarnedRewards(rewardEligibleContract, amountToDistribute);
    }

    function testEOAtoBothContractTypesToEOA(
        uint256 amountToDistribute, 
        uint16 fractionToTransfer1, 
        uint16 fractionToTransfer2, 
        uint16 fractionToTransfer3, 
        uint16 fractionToTransfer4
    ) external {
        _validateFraction(fractionToTransfer1);
        _validateFraction(fractionToTransfer2);
        _validateFraction(fractionToTransfer3);
        _validateFraction(fractionToTransfer4);
        // Deploy a new instance of RewardEligibleContract
        address rewardEligibleContract = address(new RewardEligibleContract(address(faucet)));
        address existingContract = turnstile;
        // Prank a transfer from user1 to existingContract
        _transfer(user1, existingContract, _amountToTransfer(user1, fractionToTransfer1));
        // Prank a transfer from user1 to rewardEligibleContract
        _transfer(user1, rewardEligibleContract, _amountToTransfer(user1, fractionToTransfer2));
        // Prank a transfer from existingContract to user2
        _transfer(existingContract, user2, _amountToTransfer(existingContract, fractionToTransfer3));
        // Prank a transfer from rewardEligibleContract to user2
        _transfer(rewardEligibleContract, user2, _amountToTransfer(rewardEligibleContract, fractionToTransfer4));
        // Distribute and withdraw rewards from turnstile
        _distributeAndWithdraw(amountToDistribute);
        // Compute the fraction of the eligible supply each account has and compare to fraction of rewards received
        _assertRewardEligibleBalance(user1, token.balanceOf(user1));
        _assertEarnedRewards(user1, amountToDistribute);

        _assertRewardEligibleBalance(existingContract, 0);
        assertEq(token.earned(existingContract), 0);

        _assertRewardEligibleBalance(rewardEligibleContract, token.balanceOf(rewardEligibleContract));
        _assertEarnedRewards(rewardEligibleContract, amountToDistribute);

        _assertRewardEligibleBalance(user2, token.balanceOf(user2));
        _assertEarnedRewards(user2, amountToDistribute);
    }

}
