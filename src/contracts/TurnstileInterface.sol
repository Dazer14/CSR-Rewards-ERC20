// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface TurnstileInterface {
    function register(address) external returns (uint256);
    function assign(uint256 _tokenId) external;
    function balances(uint256) external view returns (uint256);
    function withdraw(uint256, address payable, uint256) external returns (uint256);
}
