// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25 <0.9.0;

contract Counter {
    uint256 public count;

    function increase() public {
        count = count + 1;
    }
}
