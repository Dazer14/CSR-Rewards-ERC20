// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/utils/Create2.sol";
import "./RewardEligibleContract.sol";

/// @dev Have to send some tokens and CANTO to this contract
contract Create2EligibilityFactory {
    IERC20 _csrRewardsToken = IERC20(address(0x888));

    function makeAddressEligibleAndDeploy(bytes32 salt) external {
        bytes memory bytecode = abi.encode(type(RewardEligibleContract).creationCode, _csrRewardsToken);
        require(_csrRewardsToken.balanceOf(address(this)) > 0, "No tokens to send, transfer some here");
        address dest = Create2.computeAddress(salt, keccak256(bytecode));
        _csrRewardsToken.transfer(dest, 1);
        Create2.deploy(0, salt, bytecode);
    }
}
