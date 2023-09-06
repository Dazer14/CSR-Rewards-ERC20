// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Base.sol";

// Goal of these tests is to check that expected rewards are received 
// after a variety of transfer flows between EOA and both contract types
contract TransferTests is Base {
    function testFuzz_BasicTransfer(
        uint256 totalSupply, 
        uint16 fraction1, 
        uint16 fraction2, 
        uint16 fraction3, 
        uint256 amountToDistribute
    ) public {
        _setUpToken(totalSupply, fraction1, fraction2);
        _validateFraction(fraction3);

        _transfer(user1, user2, _amountToTransfer(user1, fraction3));

        _distributeAndWithdraw(amountToDistribute);

        // Check that users have received approximate expected rewards
        _assertApproxRewardsFromDistribution(user1, amountToDistribute);
        _assertApproxRewardsFromDistribution(user2, amountToDistribute);        
    }

    function testFuzz_TransferEntireBalanceEOAtoEOA(
        uint256 totalSupply, 
        uint16 fraction1, 
        uint16 fraction2, 
        uint256 amountToDistribute
    ) public {
        _setUpToken(totalSupply, fraction1, fraction2);

        _transfer(user1, user2, token.balanceOf(user1));

        _distributeAndWithdraw(amountToDistribute);

        // Check that users have received approximate expected rewards
        _assertApproxRewardsFromDistribution(user1, amountToDistribute);
        _assertApproxRewardsFromDistribution(user2, amountToDistribute);        
    }

    function testFuzz_TransferToExistingContract(
        uint256 totalSupply, 
        uint16 fraction1, 
        uint16 fraction2, 
        uint16 fraction3, 
        uint256 amountToDistribute
    ) public {
        _setUpToken(totalSupply, fraction1, fraction2);
        _validateFraction(fraction3);

        // Transfer from user1 to existingContract using the third fraction
        _transfer(user1, existingContract, _amountToTransfer(user1, fraction3));

        _distributeAndWithdraw(amountToDistribute);

        // Check that user1 has received approximate expected rewards
        _assertApproxRewardsFromDistribution(user1, amountToDistribute);
        // existingContract should not receive any rewards
        assertEq(token.earned(existingContract), 0);
    }

    function testFuzz_TransferToRewardEligibleContract(
        uint256 totalSupply, 
        uint16 fraction1, 
        uint16 fraction2, 
        uint16 fraction3, 
        uint256 amountToDistribute
    ) public {
        _setUpToken(totalSupply, fraction1, fraction2);
        _validateFraction(fraction3);

        // Transfer from user1 to rewardEligibleContract using the third fraction
        _transfer(user1, rewardEligibleContract, _amountToTransfer(user1, fraction3));

        _distributeAndWithdraw(amountToDistribute);

        // Check that user1 and rewardEligibleContract have received approximate expected rewards
        _assertApproxRewardsFromDistribution(user1, amountToDistribute);
        _assertApproxRewardsFromDistribution(rewardEligibleContract, amountToDistribute);
    }

    function testFuzz_TransferToBothContractTypesAndBackToEOA(
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
        _validateFraction(fraction3);
        _validateFraction(fraction4);
        _validateFraction(fraction5);
        _validateFraction(fraction6);

        // Transfer from user1 to rewardEligibleContract using the third fraction
        _transfer(user1, rewardEligibleContract, _amountToTransfer(user1, fraction3));

        // Transfer from user1 to existingContract using the fourth fraction
        _transfer(user1, existingContract, _amountToTransfer(user1, fraction4));

        // Transfer from rewardEligibleContract to user2 using the fifth fraction
        _transfer(rewardEligibleContract, user2, _amountToTransfer(rewardEligibleContract, fraction5));

        // Transfer from existingContract to user2 using the sixth fraction
        _transfer(existingContract, user2, _amountToTransfer(existingContract, fraction6));

        _distributeAndWithdraw(amountToDistribute);

        // Check that user1, user2, rewardEligibleContract and existingContract have received approximate expected rewards
        _assertApproxRewardsFromDistribution(user1, amountToDistribute);
        _assertApproxRewardsFromDistribution(user2, amountToDistribute);
        _assertApproxRewardsFromDistribution(rewardEligibleContract, amountToDistribute);
        assertEq(token.earned(existingContract), 0);
    }

    function testFuzz_TransferBetweenMultipleExistingContracts(
        uint256 totalSupply, 
        uint16 fraction1, 
        uint16 fraction2, 
        uint16 fraction3, 
        uint16 fraction4, 
        uint256 amountToDistribute
    ) public {
        _setUpToken(totalSupply, fraction1, fraction2);
        _validateFraction(fraction3);
        _validateFraction(fraction4);

        // Setup extra existing contracts using helpers in Base.sol
        address existingContract2 = _setUpExistingContract();

        // Transfer from user1 to existingContract using the third fraction
        _transfer(user1, existingContract, _amountToTransfer(user1, fraction3));

        // Transfer from existingContract to existingContract2 using the third fraction
        _transfer(existingContract, existingContract2, _amountToTransfer(existingContract, fraction4));

        _distributeAndWithdraw(amountToDistribute);

        // Check that user1, existingContract and existingContract2 have received approximate expected rewards
        _assertApproxRewardsFromDistribution(user1, amountToDistribute);
        assertEq(token.earned(existingContract), 0);
        assertEq(token.earned(existingContract2), 0);
    }

    function testFuzz_TransferBetweenMultipleRewardEligibleContracts(
        uint256 totalSupply, 
        uint16 fraction1, 
        uint16 fraction2, 
        uint16 fraction3, 
        uint16 fraction4, 
        uint256 amountToDistribute
    ) public {
        _setUpToken(totalSupply, fraction1, fraction2);
        _validateFraction(fraction3);
        _validateFraction(fraction4);

        // Setup extra reward eligible contracts using helpers in Base.sol
        address rewardEligibleContract2 = _setUpRewardEligibleContract();

        // Transfer from user1 to rewardEligibleContract using the third fraction
        _transfer(user1, rewardEligibleContract, _amountToTransfer(user1, fraction3));

        // Transfer from rewardEligibleContract to rewardEligibleContract2 using the third fraction
        _transfer(rewardEligibleContract, rewardEligibleContract2, _amountToTransfer(rewardEligibleContract, fraction4));

        _distributeAndWithdraw(amountToDistribute);

        // Check that user1, rewardEligibleContract and rewardEligibleContract2 have received approximate expected rewards
        _assertApproxRewardsFromDistribution(user1, amountToDistribute);
        _assertApproxRewardsFromDistribution(rewardEligibleContract, amountToDistribute);
        _assertApproxRewardsFromDistribution(rewardEligibleContract2, amountToDistribute);
    }
    
}
