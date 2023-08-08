// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Probably the easist way to do this
// Setup a simple faucet
// Public function that sends a single wei of the CsrRewardsToken to any caller
// Can fetch remainder
// Easy to call in constructor
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract EligibilityFaucet {
    IERC20 public immutable csrRewardsToken;

    constructor(address _csrRewardsToken) {
        csrRewardsToken = IERC20(_csrRewardsToken);
    }

    function tokenBalance() public view returns (uint) {
        return csrRewardsToken.balanceOf(address(this));
    }

    function drip() external {
        require(tokenBalance() > 0, "EligibilityFaucet: Out of tokens");
        csrRewardsToken.transfer(msg.sender, 1);
    }

    function retrieveTokens(address recipient) external {
        csrRewardsToken.transfer(recipient, tokenBalance());
    }
}
