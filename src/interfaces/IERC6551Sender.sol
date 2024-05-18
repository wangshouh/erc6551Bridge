// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IERC6551Sender {
    function createAccount(address owner, address nft, uint256 tokenId, bytes calldata extraArgs) external;
}
