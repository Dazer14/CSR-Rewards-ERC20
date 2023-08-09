// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @dev Simple faucet for making contracts CsrRewardsERC20 reward eligible
/// USE: Deploy with token address and send a small amount of tokens in
/// Then call drip from the constructor of the contract you want to make reward eligible
contract EligibilityFaucet {
    IERC20 public immutable csrRewardsToken;

    constructor(address _csrRewardsToken) {
        csrRewardsToken = IERC20(_csrRewardsToken);
    }

    function tokenBalance() public view returns (uint) {
        return csrRewardsToken.balanceOf(address(this));
    }

    /// @dev Call in contract constructor
    function drip() external {
        require(tokenBalance() > 0, "EligibilityFaucet: Out of tokens");
        csrRewardsToken.transfer(msg.sender, 1);
    }

    function retrieveTokens(address recipient) external {
        csrRewardsToken.transfer(recipient, tokenBalance());
    }
}
