// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Test } from "forge-std/src/Test.sol";
import { console2 } from "forge-std/src/console2.sol";

import { ERC6551L1Registry } from "../src/ERC6551L1Registry.sol";
import { ERC6551Account } from "../src/ERC6551Account.sol";
import { MockNFT } from "./mocks/MockNFT.sol";
import { ERC6551 } from "solady/src/accounts/ERC6551.sol";

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract ERC6551AccountTest is Test {
    ERC6551L1Registry internal registry;
    ERC6551Account internal account;
    MockNFT internal nft;

    /// @dev A function invoked before each test case is run.
    function setUp() public virtual {
        account = new ERC6551Account();
        registry = new ERC6551L1Registry(address(account));
        nft = new MockNFT("NFT", "NFT");
    }

    /// @dev Basic test. Run it with `forge test -vvv` to see the console log.
    function test_CreateAccount() external {
        vm.startPrank(vm.addr(1));
        nft.mint(address(this), 1);
        address exampleAccount = registry.createAccount(address(nft), 1);
        vm.stopPrank();

        (uint256 chainId, address tokenContract, uint256 tokenId) = ERC6551(payable(exampleAccount)).token();
        assertEq(tokenContract, address(nft));
        assertEq(tokenId, 1);
        assertEq(chainId, 31_337);

        assertEq(ERC6551(payable(exampleAccount)).owner(), address(this));
    }
}
