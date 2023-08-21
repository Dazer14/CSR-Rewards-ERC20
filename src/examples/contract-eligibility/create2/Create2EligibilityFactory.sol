// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Create2} from "lib/openzeppelin-contracts/contracts/utils/Create2.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Create2EligibleExample} from "./Create2EligibleExample.sol";

/// https://ethereum.stackexchange.com/questions/9142/how-to-convert-a-string-to-bytes32
function stringToBytes32(string memory source) pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
        return 0x0;
    }

    assembly {
        result := mload(add(source, 32))
    }
}

/// @dev Have to send some tokens to this contract
/// Use Create2 to compute and deploy to contract address
/// Tokens are transferred there prior to deploy to make the eventual contract address reward eligible
contract Create2EligibilityFactory {
    IERC20 public immutable csrRewardsToken;

    constructor(address _csrRewardsToken) {
        csrRewardsToken = IERC20(_csrRewardsToken);
    }

    function makeAddressEligibleAndDeploy(string memory salt) external {
        bytes32 saltBytes32 = stringToBytes32(salt);
        bytes memory bytecode = abi.encodePacked(
            type(Create2EligibleExample).creationCode,
            abi.encode(address(csrRewardsToken)),
            abi.encode(address(msg.sender)) // Owner of deployed contract
        );
        require(csrRewardsToken.balanceOf(address(this)) > 0, "No tokens to send, transfer some here");
        address dest = Create2.computeAddress(saltBytes32, keccak256(bytecode));
        csrRewardsToken.transfer(dest, 1); // Made eligible
        Create2.deploy(0, saltBytes32, bytecode);
    }

    function retrieveTokens(address receiver) external {
        uint256 balance = csrRewardsToken.balanceOf(address(this));
        csrRewardsToken.transfer(receiver, balance);
    }
}
