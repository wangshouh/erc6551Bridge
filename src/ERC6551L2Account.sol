// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Initializable } from "solady/src/utils/Initializable.sol";
import { ERC6551 } from "solady/src/accounts/ERC6551.sol";

contract ERC6551L2Account is ERC6551, Initializable {
    address public factory;
    address private _owner;

    error NotFactory(address sender);

    modifier onlyFactory() {
        if (msg.sender != factory) revert NotFactory(msg.sender);
        _;
    }
    
    function init(address factory_, address owner_) external initializer {
        factory = factory_;
        _owner = owner_;
    }

    function setOwner(address owner_) public onlyFactory {
        _owner = owner_;
    }

    function owner() public view override returns (address result) {
        result = _owner;
    }

    function _domainNameAndVersion() internal pure override returns (string memory, string memory) {
        return ("Mock", "1.0.0");
    }
}
