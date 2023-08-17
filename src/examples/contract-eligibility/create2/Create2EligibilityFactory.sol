// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Create2.sol";

import "./Create2EligibleExample.sol";

/// @dev Have to send some tokens to this contract
/// Use Create2 to calculate contract deploy address
/// Tokens are transferred there to make the eventual contract address reward eligible
/// Create2 used to deploy
contract Create2EligibilityFactory {
    IERC20 public immutable csrRewardsToken;

    constructor(address _csrRewardsToken) {
        csrRewardsToken = IERC20(_csrRewardsToken);
    }

    function makeAddressEligibleAndDeploy(bytes32 salt) external {
        bytes memory bytecode = abi.encodePacked(
            type(Create2EligibleExample).creationCode,
            abi.encode(address(csrRewardsToken)),
            abi.encode(address(msg.sender)) // Owner of deployed contract
        );
        require(csrRewardsToken.balanceOf(address(this)) > 0, "No tokens to send, transfer some here");
        address dest = Create2.computeAddress(salt, keccak256(bytecode));
        csrRewardsToken.transfer(dest, 1); // Made eligible
        Create2.deploy(0, salt, bytecode);
    }

    function retrieveTokens(address receiver) external {
        uint256 balance = csrRewardsToken.balanceOf(address(this));
        csrRewardsToken.transfer(receiver, balance);
    }
}
