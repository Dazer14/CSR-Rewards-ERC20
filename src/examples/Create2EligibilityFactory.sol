// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/utils/Create2.sol";
// import "@openzeppelin/contracts/utils/Create2.sol";
import "./RewardEligibleContract.sol";

/// @dev Have to send some tokens to this contract
/// Use Create2 to calculate contract deploy address
/// Tokens are transferred there to make the eventual contract address reward eligible
/// Create2 used to deploy 
contract Create2EligibilityFactory {
    IERC20 _csrRewardsToken = IERC20(address(0x888));

    function makeAddressEligibleAndDeploy(bytes32 salt) external {
        bytes memory bytecode = abi.encodePacked(
            type(RewardEligibleContract).creationCode, 
            abi.encode(address(_csrRewardsToken)),
            abi.encode(address(msg.sender))
        );
        require(_csrRewardsToken.balanceOf(address(this)) > 0, "No tokens to send, transfer some here");
        address dest = Create2.computeAddress(salt, keccak256(bytecode));
        _csrRewardsToken.transfer(dest, 1); // Made eligible
        Create2.deploy(0, salt, bytecode);
    }

    function retrieveTokens(address receiver) external {
        uint balance = _csrRewardsToken.balanceOf(address(this));
        _csrRewardsToken.transfer(receiver, balance);
    }

}
