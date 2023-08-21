// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface TurnstileInterface {
    function register(address _recipient) external returns (uint256 tokenId);
    function assign(uint256 _tokenId) external;
    function balances(uint256 _tokenId) external view returns (uint256 feesEarned);
    function withdraw(uint256 _tokenId, address payable _recipient, uint256 _amount) external returns (uint256 amount);
}
