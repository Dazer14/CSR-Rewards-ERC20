// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseTest.sol";

contract CsrRewardsERC20Test is BaseTest {
    function testUserHasEligibleBalance() external {
        assertEq(token.balanceOf(user1), userBalance);
        assertEq(token.rewardEligibleBalanceOf(user1), userBalance);
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
        uint256 user1EligibleBalance = token.rewardEligibleBalanceOf(user1);
        uint256 totalEligibleSupply = token.totalRewardEligibleSupply();
        // Assert that user1 has earned their proportion of the amount distributed
        // This assumes user1 received a proportion of the supply, based on their eligible balance
        assertEq(token.earned(user1), amountToDistribute * user1EligibleBalance / totalEligibleSupply);
    }

    function testUserCanClaimRewards(uint256 amountToDistribute) external {
        _distributeAmount(amountToDistribute);
        token.withdrawFromTurnstile();
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
        // Ensure fractionToTransfer is between 0 and 10000
        vm.assume(fractionToTransfer >= 0 && fractionToTransfer <= 10000);
        uint256 balanceToTransfer = token.balanceOf(user1) * fractionToTransfer / 10000;
        // Prank a transfer from user1 to user2, sending a fraction of user1's balance
        vm.prank(user1);
        token.transfer(user2, balanceToTransfer);
        // Distribute and withdraw rewards from turnstile
        _distributeAmount(amountToDistribute);
        token.withdrawFromTurnstile();
        // Compute the fraction of the eligible supply both users have and compare to fraction of rewards received
        // Assert that expected fraction of rewards are received
        assertEq(token.earned(user1), amountToDistribute * token.rewardEligibleBalanceOf(user1) / token.totalRewardEligibleSupply());
        assertEq(token.earned(user2), amountToDistribute * token.rewardEligibleBalanceOf(user2) / token.totalRewardEligibleSupply());
    }

    function testMultipleTransfers(uint256 amountToDistribute, uint16 fractionToTransfer1, uint16 fractionToTransfer2) external {
        // Ensure fractions are between 0 and 10000
        vm.assume(fractionToTransfer1 >= 0 && fractionToTransfer1 <= 10000);
        vm.assume(fractionToTransfer2 >= 0 && fractionToTransfer2 <= 10000);
        
        uint256 balanceToTransfer1 = token.balanceOf(user1) * fractionToTransfer1 / 10000;

        // Prank a transfer from user1 to user2
        vm.prank(user1);
        token.transfer(user2, balanceToTransfer1);
        
        uint256 balanceToTransfer2 = token.balanceOf(user2) * fractionToTransfer2 / 10000;
        
        // Prank a transfer from user2 to user3
        vm.prank(user2);
        token.transfer(user3, balanceToTransfer2);
        
        // Distribute and withdraw rewards from turnstile
        _distributeAmount(amountToDistribute);
        token.withdrawFromTurnstile();
        
        // Compute the fraction of the eligible supply each user has and compare to fraction of rewards received
        // Assert that expected fraction of rewards are received by each user
        assertEq(token.earned(user1), amountToDistribute * token.rewardEligibleBalanceOf(user1) / token.totalRewardEligibleSupply());
        assertEq(token.earned(user2), amountToDistribute * token.rewardEligibleBalanceOf(user2) / token.totalRewardEligibleSupply());
        assertEq(token.earned(user3), amountToDistribute * token.rewardEligibleBalanceOf(user3) / token.totalRewardEligibleSupply());
    }

    function testMultipleDistributionsWithTransfers(uint256 amountToDistribute1, uint256 amountToDistribute2, uint16 fractionToTransfer1, uint16 fractionToTransfer2) external {
        // Ensure fractions are between 0 and 10000
        vm.assume(fractionToTransfer1 >= 0 && fractionToTransfer1 <= 10000);
        vm.assume(fractionToTransfer2 >= 0 && fractionToTransfer2 <= 10000);

        // Calculate the balance to transfer
        uint256 balanceToTransfer1 = token.balanceOf(user1) * fractionToTransfer1 / 10000;

        // Prank a transfer from user1 to user2
        vm.prank(user1);
        token.transfer(user2, balanceToTransfer1);

        // Distribute and withdraw rewards from turnstile
        _distributeAmount(amountToDistribute1);
        token.withdrawFromTurnstile();

        uint256 user1RewardsDist1 = amountToDistribute1 * token.rewardEligibleBalanceOf(user1) / token.totalRewardEligibleSupply();
        uint256 user2RewardsDist1 = amountToDistribute1 * token.rewardEligibleBalanceOf(user2) / token.totalRewardEligibleSupply();
        assertEq(token.earned(user1), user1RewardsDist1);
        assertEq(token.earned(user2), user2RewardsDist1);

        uint256 balanceToTransfer2 = token.balanceOf(user1) * fractionToTransfer2 / 10000;
        
        // Prank a transfer from user1 to user2
        vm.prank(user1);
        token.transfer(user2, balanceToTransfer2);

        // Distribute and withdraw rewards from turnstile
        _distributeAmount(amountToDistribute2);
        token.withdrawFromTurnstile();

        uint256 user1RewardsDist2 = amountToDistribute2 * token.rewardEligibleBalanceOf(user1) / token.totalRewardEligibleSupply();
        uint256 user2RewardsDist2 = amountToDistribute2 * token.rewardEligibleBalanceOf(user2) / token.totalRewardEligibleSupply();
        assertEq(token.earned(user1), user1RewardsDist1 + user1RewardsDist2);
        assertEq(token.earned(user2), user2RewardsDist1 + user2RewardsDist2);
    }
    
}
