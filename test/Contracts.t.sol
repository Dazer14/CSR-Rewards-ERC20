// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseTest.sol";

contract Contracts is BaseTest {
    function testBasicTransferToExistingContract(uint16 fractionToTransfer) external {
        // Ensure fractions are between 0 and 10000
        vm.assume(fractionToTransfer >= 0 && fractionToTransfer <= 10000);
        
        uint256 balanceToTransfer = token.balanceOf(user1) * fractionToTransfer / 10000;
        
        // Capture the total eligible supply before the transfer
        uint256 totalEligibleSupplyBefore = token.totalRewardEligibleSupply();
        
        // Prank a transfer from user1 to turnstile
        vm.prank(user1);
        token.transfer(turnstile, balanceToTransfer);
        
        // Capture the total eligible supply after the transfer
        uint256 totalEligibleSupplyAfter = token.totalRewardEligibleSupply();
        
        // Assert that the balance of user1 and turnstile are as expected
        assertEq(token.rewardEligibleBalanceOf(user1), token.balanceOf(user1));
        assertEq(token.rewardEligibleBalanceOf(turnstile), 0);
        
        // Assert that the total eligible supply has been updated properly
        assertEq(totalEligibleSupplyBefore - totalEligibleSupplyAfter, token.balanceOf(turnstile));
    }

    function testTransferToAndFromExistingContract(uint16 fractionToTransfer1, uint16 fractionToTransfer2) external {
        // Ensure fractions are between 0 and 10000
        vm.assume(fractionToTransfer1 >= 0 && fractionToTransfer1 <= 10000);
        vm.assume(fractionToTransfer2 >= 0 && fractionToTransfer2 <= 10000);
        
        // Calculate the balance to transfer
        uint256 balanceToTransfer1 = token.balanceOf(user1) * fractionToTransfer1 / 10000;
        
        // Capture the total eligible supply before the transfers
        uint256 totalEligibleSupplyBefore = token.totalRewardEligibleSupply();
        
        // Prank a transfer from user1 to existingContract
        vm.prank(user1);
        token.transfer(turnstile, balanceToTransfer1);
        
        // Calculate the balance to transfer
        uint256 balanceToTransfer2 = token.balanceOf(turnstile) * fractionToTransfer2 / 10000;
        
        // Prank a transfer from existingContract to user2
        vm.prank(turnstile);
        token.transfer(user2, balanceToTransfer2);
        
        // Capture the total eligible supply after the transfers
        uint256 totalEligibleSupplyAfter = token.totalRewardEligibleSupply();
        
        // Compute the fraction of the eligible supply each user has and compare to fraction of rewards received
        assertEq(token.rewardEligibleBalanceOf(user1), token.balanceOf(user1));
        assertEq(token.rewardEligibleBalanceOf(turnstile), 0);
        assertEq(token.rewardEligibleBalanceOf(user2), token.balanceOf(user2));

        // Assert that the total eligible supply has been updated properly
        assertEq(totalEligibleSupplyBefore - totalEligibleSupplyAfter, token.balanceOf(turnstile));
    }

}
