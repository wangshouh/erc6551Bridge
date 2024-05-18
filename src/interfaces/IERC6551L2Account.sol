// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IERC6551L2Account {
    function init(address factory_, address owner_) external;
    function setOwner(address owner_) external;
}
