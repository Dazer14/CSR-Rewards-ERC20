// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseTest.sol";

contract CsrRewardsERC20Test is BaseTest {
    function testUserHasEligibleBalance() external {
        _assertBalance(user1, userBalance);
        _assertRewardEligibleBalance(user1, userBalance);
    }

    function testTurnstileBalance(uint256 amountToDistribute) external {
        _distributeAmount(amountToDistribute);
        assertEq(token.turnstileBalance(), amountToDistribute);
    }

    function testWithdrawFromTurnstile(uint256 amountToDistribute) external {
        _distributeAmount(amountToDistribute);
        // Assert that the turnstile balance is as expected
        assertEq(token.turnstileBalance(), amountToDistribute);
        // Call the withdrawFromTurnstile function
        token.withdrawFromTurnstile();
        // Assert that the turnstile balance is now zero
        assertEq(token.turnstileBalance(), 0);
        // Compute the fraction of the eligible supply user1 has and compare to fraction of rewards received
        // This assumes user1 received a proportion of the supply, based on their eligible balance
        _assertEarnedRewards(user1, amountToDistribute);
    }

    function testUserCanClaimRewards(uint256 amountToDistribute) external {
        _distributeAndWithdraw(amountToDistribute);
        // Ensure that the user has some rewards to claim
        uint256 rewards = token.earned(user1);
        assertTrue(rewards > 0);
        // Store the initial balance of the user
        uint256 initialBalance = address(user1).balance;
        // Prank user1 to claim their rewards
        vm.prank(user1);
        token.getReward();
        // Assert that the rewards have been transferred to the user's balance
        uint256 finalBalance = address(user1).balance;
        assertEq(finalBalance, initialBalance + rewards);
    }

    function testUserGetsCorrectRewardsAfterTransfer(uint256 amountToDistribute, uint16 fractionToTransfer) external {
        // Validate the fractionToTransfer
        _validateFraction(fractionToTransfer);
        // Calculate the amount to transfer
        uint256 amountToTransfer = _amountToTransfer(user1, fractionToTransfer);
        // Prank a transfer from user1 to user2, sending a fraction of user1's balance
        _transfer(user1, user2, amountToTransfer);
        // Distribute and withdraw rewards from turnstile
        _distributeAndWithdraw(amountToDistribute);
        // Compute the fraction of the eligible supply both users have and compare to fraction of rewards received
        // Assert that expected fraction of rewards are received
        _assertEarnedRewards(user1, amountToDistribute);
        _assertEarnedRewards(user2, amountToDistribute);
    }

    function testMultipleTransfers(uint256 amountToDistribute, uint16 fractionToTransfer1, uint16 fractionToTransfer2) external {
        // Validate the fractions
        _validateFraction(fractionToTransfer1);
        _validateFraction(fractionToTransfer2);
        
        // Calculate the amount to transfer
        uint256 amountToTransfer1 = _amountToTransfer(user1, fractionToTransfer1);

        // Prank a transfer from user1 to user2
        _transfer(user1, user2, amountToTransfer1);
        
        // Calculate the amount to transfer
        uint256 amountToTransfer2 = _amountToTransfer(user2, fractionToTransfer2);
        
        // Prank a transfer from user2 to user3
        _transfer(user2, user3, amountToTransfer2);
        
        // Distribute and withdraw rewards from turnstile
        _distributeAndWithdraw(amountToDistribute);
        
        // Compute the fraction of the eligible supply each user has and compare to fraction of rewards received
        // Assert that expected fraction of rewards are received by each user
        _assertEarnedRewards(user1, amountToDistribute);
        _assertEarnedRewards(user2, amountToDistribute);
        _assertEarnedRewards(user3, amountToDistribute);
    }

    function testMultipleDistributionsWithTransfers(uint256 amountToDistribute1, uint256 amountToDistribute2, uint16 fractionToTransfer1, uint16 fractionToTransfer2) external {
        // Validate the fractions
        _validateFraction(fractionToTransfer1);
        _validateFraction(fractionToTransfer2);

        // Calculate the amount to transfer
        uint256 amountToTransfer1 = _amountToTransfer(user1, fractionToTransfer1);

        // Prank a transfer from user1 to user2
        _transfer(user1, user2, amountToTransfer1);

        // Distribute and withdraw rewards from turnstile
        _distributeAndWithdraw(amountToDistribute1);

        uint256 user1RewardsDist1 = _calculateRewardsByEligibleBalance(amountToDistribute1, user1);
        uint256 user2RewardsDist1 = _calculateRewardsByEligibleBalance(amountToDistribute1, user2);
        assertEq(token.earned(user1), user1RewardsDist1);
        assertEq(token.earned(user2), user2RewardsDist1);

        // Calculate the amount to transfer
        uint256 amountToTransfer2 = _amountToTransfer(user1, fractionToTransfer2);
        
        // Prank a transfer from user1 to user2
        _transfer(user1, user2, amountToTransfer2);

        // Distribute and withdraw rewards from turnstile
        _distributeAndWithdraw(amountToDistribute2);

        uint256 user1RewardsDist2 = _calculateRewardsByEligibleBalance(amountToDistribute2, user1);
        uint256 user2RewardsDist2 = _calculateRewardsByEligibleBalance(amountToDistribute2, user2);
        assertEq(token.earned(user1), user1RewardsDist1 + user1RewardsDist2);
        assertEq(token.earned(user2), user2RewardsDist1 + user2RewardsDist2);
    }
    
}
