// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Test } from "forge-std/src/Test.sol";
import { console2 } from "forge-std/src/console2.sol";

import { ERC6551L2Registry } from "src/ERC6551L2Registry.sol";
import { ERC6551L2Account } from "src/ERC6551L2Account.sol";
import { Counter } from "./mocks/Counter.sol";

contract ERC6551L2AccountTest is Test {
    ERC6551L2Registry internal registry;
    ERC6551L2Account internal account;
    Counter internal counter;

    function setUp() public {
        registry = new ERC6551L2Registry();
        account = new ERC6551L2Account();
        counter = new Counter();
    }

    function test_createAccount() public {
        address accountOwner = vm.addr(1);
        address payable erc6551Account =
            payable(registry.createAccount(address(account), keccak256("test"), address(1), 1, accountOwner));

        assertEq(ERC6551L2Account(erc6551Account).owner(), accountOwner);
    }

    function test_AccountCall() public {
        address accountOwner = vm.addr(1);
        address payable erc6551Account =
            payable(registry.createAccount(address(account), keccak256("test"), address(1), 1, accountOwner));

        vm.startPrank(accountOwner);
        ERC6551L2Account(erc6551Account).execute(address(counter), 0, abi.encodeWithSelector(hex"e8927fbc", ""), 0);
        vm.stopPrank();

        assertEq(counter.count(), 1);
    }
}
