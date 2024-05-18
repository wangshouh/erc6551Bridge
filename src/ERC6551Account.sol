// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { ERC6551 } from "solady/src/accounts/ERC6551.sol";

contract ERC6551Account is ERC6551 {
    function _domainNameAndVersion() internal pure override returns (string memory, string memory) {
        return ("Mock", "1.0.0");
    }
}
