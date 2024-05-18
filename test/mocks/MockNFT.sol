// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25 <0.9.0;

import { MockERC721 } from "forge-std/src/mocks/MockERC721.sol";

contract MockNFT is MockERC721 {
    constructor(string memory name_, string memory symbol_) {
        initialize(name_, symbol_);
    }

    function mint(address receiver, uint256 id) public {
        _mint(receiver, id);
    }
}
