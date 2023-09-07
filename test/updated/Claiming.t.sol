// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Base.sol";

// Goal of these tests is to check that every eligble address is able to 
// claim all rewards after distributions.
// The purpose is to ensure that reward accounting is accurate and users are 
// always able to claim their rewards.
// These tests will rely on there being 3 users setup in the Base.sol file.
// If more are added these tests should be updated or use a different token setup function.
contract ClaimingTests is Base {
    function testFuzz_AllUsersCanClaimNoTransfers(
        uint256 totalSupply, 
        uint16 fraction1, 
        uint16 fraction2, 
        uint256 amountToDistribute
    ) public {
        _setUpToken(totalSupply, fraction1, fraction2);
        // Distribute and withdraw rewards
        _distributeAndWithdraw(amountToDistribute);
        // Store rewards earned by users in local variables
        uint256 user1Rewards = token.earned(user1);
        uint256 user2Rewards = token.earned(user2);
        uint256 user3Rewards = token.earned(user3);
        // Assert that the contract balance is equal to the amount distributed
        assertEq(address(token).balance, amountToDistribute);
        // Assert that the sum of the user rewards earned is less or equal to the amount distributed
        assertLe(user1Rewards + user2Rewards + user3Rewards, amountToDistribute);
    }

    function testFuzz_AllUsersCanClaimBasicTransfers(
        uint256 totalSupply, 
        uint16 fraction1, 
        uint16 fraction2, 
        uint16 fraction3, 
        uint256 amountToDistribute
    ) public {
        _setUpToken(totalSupply, fraction1, fraction2);

        _transfer(user1, user2, _amountToTransfer(user1, fraction3));

        // Distribute and withdraw rewards
        _distributeAndWithdraw(amountToDistribute);
        // Store rewards earned by users in local variables
        uint256 user1Rewards = token.earned(user1);
        uint256 user2Rewards = token.earned(user2);
        uint256 user3Rewards = token.earned(user3);
        // Assert that the contract balance is equal to the amount distributed
        assertEq(address(token).balance, amountToDistribute);
        // Assert that the sum of the user rewards earned is less or equal to the amount distributed
        assertLe(user1Rewards + user2Rewards + user3Rewards, amountToDistribute);
    }

    function testFuzz_AllUsersCanClaimContractTransfers(
        uint256 totalSupply, 
        uint16 fraction1, 
        uint16 fraction2, 
        uint16 fraction3, 
        uint16 fraction4, 
        uint16 fraction5, 
        uint16 fraction6, 
        uint256 amountToDistribute
    ) public {
        _setUpToken(totalSupply, fraction1, fraction2);

        _transfer(user1, existingContract, _amountToTransfer(user1, fraction3));
        _transfer(user2, rewardEligibleContract, _amountToTransfer(user2, fraction4));
        _transfer(existingContract, user2, _amountToTransfer(existingContract, fraction5));
        _transfer(rewardEligibleContract, user1, _amountToTransfer(rewardEligibleContract, fraction6));

        // Distribute and withdraw rewards
        _distributeAndWithdraw(amountToDistribute);
        // Store rewards earned by users in local variables
        uint256 user1Rewards = token.earned(user1);
        uint256 user2Rewards = token.earned(user2);
        uint256 user3Rewards = token.earned(user3);
        uint256 rewardEligibleContractRewards = token.earned(rewardEligibleContract);
        // Assert that the contract balance is equal to the amount distributed
        assertEq(address(token).balance, amountToDistribute);
        // Assert that exiting is zero rewards
        assertEq(token.earned(existingContract), 0);
        // Assert that the sum of the user rewards earned is less or equal to the amount distributed
        assertLe(user1Rewards + user2Rewards + user3Rewards + rewardEligibleContractRewards, amountToDistribute);
    }

    
}