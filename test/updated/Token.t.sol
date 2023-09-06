// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Base.sol";

contract TokenTests is Base {
    function testFuzz_TotalRewardEligibleSupply(uint256 totalSupply, uint16 fraction1, uint16 fraction2) public {
        _setUpToken(totalSupply, fraction1, fraction2);

        uint256 initialTotalRewardEligibleSupply = token.totalRewardEligibleSupply();
        assertEq(initialTotalRewardEligibleSupply, token.totalSupply());

        // Transfers from user1 to user2 and user1 to existing contract
        _transfer(user1, user2, _amountToTransfer(user1, fraction1));
        _transfer(user1, existingContract, _amountToTransfer(user1, fraction2));

        // Assert that the tokens sent to an ineligble address are discounted from the totalRewardEligibleSupply
        assertEq(token.totalRewardEligibleSupply(), initialTotalRewardEligibleSupply - token.balanceOf(existingContract));
    }

    function testFuzz_RewardEligibleBalanceOf(uint256 totalSupply, uint16 fraction1, uint16 fraction2) public {
        _setUpToken(totalSupply, fraction1, fraction2);
        
        assertEq(token.balanceOf(user1), token.rewardEligibleBalanceOf(user1));
        assertEq(token.balanceOf(user2), token.rewardEligibleBalanceOf(user2));

        _transfer(user1, user2, _amountToTransfer(user1, fraction1));
        _transfer(user1, existingContract, _amountToTransfer(user1, fraction2));
        _transfer(user1, rewardEligibleContract, _amountToTransfer(user1, fraction2));

        assertEq(token.balanceOf(user1), token.rewardEligibleBalanceOf(user1));
        assertEq(token.balanceOf(user2), token.rewardEligibleBalanceOf(user2));
        assertEq(token.rewardEligibleBalanceOf(existingContract), 0);
        assertEq(token.balanceOf(rewardEligibleContract), token.rewardEligibleBalanceOf(rewardEligibleContract));
    }

    function testFuzz_IsRewardEligible(uint256 totalSupply, uint16 fraction1, uint16 fraction2) public {
        _setUpToken(totalSupply, fraction1, fraction2);
        
        address randomAddress = address(0x7777);
        assertTrue(token.isRewardEligible(user1));
        assertTrue(token.isRewardEligible(rewardEligibleContract));
        assertFalse(token.isRewardEligible(randomAddress));
        assertFalse(token.isRewardEligible(existingContract));

        // Transfer to each account from user1, runs hook
        _transfer(user1, randomAddress, 1);
        _transfer(user1, turnstile, 1);
        _transfer(user1, rewardEligibleContract, 1);

        // Should be true now
        assertTrue(token.isRewardEligible(randomAddress));
        // Still false
        assertFalse(token.isRewardEligible(existingContract));
        // Still true
        assertTrue(token.isRewardEligible(rewardEligibleContract));
    }

    function testFuzz_TurnstileBalance(uint256 totalSupply, uint16 fraction1, uint16 fraction2, uint256 amountToDistribute) public {
        _setUpToken(totalSupply, fraction1, fraction2);

        _distributeAmount(amountToDistribute);
        // Check that the turnstile balance is correct
        assertEq(token.turnstileBalance(), amountToDistribute);
        // Call withdrawFromTurnstile
        token.withdrawFromTurnstile();
        // Assert that the turnstile balance is now 0
        assertEq(token.turnstileBalance(), 0);
    }

    function testFuzz_GetReward(uint256 totalSupply, uint16 fraction1, uint16 fraction2, uint256 amountToDistribute) public {
        _setUpToken(totalSupply, fraction1, fraction2);

        // Check that there are no rewards earned before
        assertEq(token.earned(user1), 0);

        _distributeAndWithdraw(amountToDistribute);

        uint256 rewardsEarned = token.earned(user1);
        // Log user1 balance before get reward
        uint256 beforeBalance = address(user1).balance;
        vm.prank(user1);
        token.getReward();
        // Log user1 balance after get reward
        uint256 afterBalance = address(user1).balance;
        // Assert the balance difference is the same as rewards earned
        assertEq(afterBalance - beforeBalance, rewardsEarned);
    }
    
}
