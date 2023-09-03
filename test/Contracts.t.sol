// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseTest.sol";

contract Contracts is BaseTest {
    function testBasicTransferToExistingContract(uint256 amountToDistribute, uint16 fractionToTransfer) external {
        // Ensure fractions are between 0 and 10000
        vm.assume(fractionToTransfer >= 0 && fractionToTransfer <= 10000);
        
        // Deploy a new contract for this test
        // This contract is just used to simulate transfers to and from a reward ineligible contract
        address existingContract = turnstile;
        
        uint256 balanceToTransfer = token.balanceOf(user1) * fractionToTransfer / 10000;
        
        // Prank a transfer from user1 to existingContract
        vm.prank(user1);
        token.transfer(existingContract, balanceToTransfer);
        
        // Distribute and withdraw rewards from turnstile
        _distributeAmount(amountToDistribute);
        token.withdrawFromTurnstile();
        
        // Compute the fraction of the eligible supply each user has and compare to fraction of rewards received
        uint256 user1EligibleBalance = token.rewardEligibleBalanceOf(user1);
        uint256 existingContractEligibleBalance = token.rewardEligibleBalanceOf(existingContract);
        
        assertEq(user1EligibleBalance, token.balanceOf(user1));
        assertEq(existingContractEligibleBalance, 0);
    }

    function testTransferToAndFromExistingContract(uint256 amountToDistribute, uint16 fractionToTransfer1, uint16 fractionToTransfer2) external {
        // Ensure fractions are between 0 and 10000
        vm.assume(fractionToTransfer1 >= 0 && fractionToTransfer1 <= 10000);
        vm.assume(fractionToTransfer2 >= 0 && fractionToTransfer2 <= 10000);
        
        // Calculate the balance to transfer
        uint256 balanceToTransfer1 = token.balanceOf(user1) * fractionToTransfer1 / 10000;
        
        // Prank a transfer from user1 to existingContract
        vm.prank(user1);
        token.transfer(turnstile, balanceToTransfer1);
        
        // Calculate the balance to transfer
        uint256 balanceToTransfer2 = token.balanceOf(turnstile) * fractionToTransfer2 / 10000;
        
        // Prank a transfer from existingContract to user2
        vm.prank(turnstile);
        token.transfer(user2, balanceToTransfer2);
        
        // Distribute and withdraw rewards from turnstile
        _distributeAmount(amountToDistribute);
        token.withdrawFromTurnstile();
        
        // Compute the fraction of the eligible supply each user has and compare to fraction of rewards received
        assertEq(token.rewardEligibleBalanceOf(user1), token.balanceOf(user1));
        assertEq(token.rewardEligibleBalanceOf(turnstile), 0);
        assertEq(token.rewardEligibleBalanceOf(user2), token.balanceOf(user2));
    }

}
