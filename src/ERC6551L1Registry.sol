// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IERC6551L1Registry } from "./interfaces/IERC6551L1Registry.sol";

contract ERC6551L1Registry is IERC6551L1Registry {
    address public immutable implementation;
    uint256 public immutable chainId;
    bytes32 public constant salt = keccak256("l1");

    constructor(address _impl) {
        implementation = _impl;
        chainId = block.chainid;
    }

    function createAccount(address tokenContract, uint256 tokenId) public override returns (address result) {
        address _implementation = implementation;
        bytes32 _salt = salt;
        uint256 _chainId = chainId;
        assembly {
            // Silence unused variable warnings
            let m := mload(0x40) // Grab the free memory pointer.
            // pop(chainId)

            mstore(add(m, 0xec), tokenId)
            mstore(add(m, 0xcc), tokenContract)
            mstore(add(m, 0xac), _chainId)
            mstore(add(m, 0x8c), _salt)
            mstore(add(m, 0x6c), 0x5af43d82803e903d91602b57fd5bf3) // ERC-1167 footer
            mstore(add(m, 0x5d), _implementation) // implementation
            mstore(add(m, 0x49), 0x3d60ad80600a3d3981f3363d3d373d3d3d363d73) // ERC-1167 constructor + header

            // Copy create2 computation data to memory
            mstore(add(m, 0x35), keccak256(add(m, 0x55), 0xb7)) // keccak256(bytecode)
            mstore(add(m, 0x01), shl(96, address())) // registry address
            mstore(add(m, 0x15), _salt) // salt
            mstore8(m, 0xff) // 0xFF

            // Compute account address
            let computed := keccak256(m, 0x55)

            // If the account has not yet been deployed
            switch iszero(extcodesize(computed))
            case 1 {
                // Deploy account contract
                let deployed := create2(0, add(m, 0x55), 0xb7, _salt)

                // Revert if the deployment fails
                if iszero(deployed) {
                    mstore(m, 0x20188a59) // `AccountCreationFailed()`
                    revert(add(m, 0x1c), 0x04)
                }

                // Store account address in memory before salt and chainId
                mstore(add(m, 0x6c), deployed)

                // Emit the ERC6551AccountCreated event
                log4(
                    add(m, 0x6c),
                    0x60,
                    // `ERC6551AccountCreated(address,address,bytes32,uint256,address,uint256)`
                    0x79f19b3655ee38b1ce526556b7731a20c8f218fbda4a3990b6cc4172fdf88722,
                    _implementation,
                    tokenContract,
                    tokenId
                )

                // Return the account address
                mstore(m, shl(96, deployed))
            }
            default {
                // Otherwise, return the computed account address
                mstore(m, shl(96, computed))
            }
            result := shr(96, mload(m)) // Load the result.
            mstore(0x40, add(m, 0x14)) // Restore the free memory pointer.
        }
    }

    function account(address tokenContract, uint256 tokenId) external view override returns (address) {
        address _implementation = implementation;
        bytes32 _salt = salt;
        assembly {
            // Silence unused variable warnings
            // pop(chainId)
            pop(tokenContract)
            pop(tokenId)

            // Copy bytecode + constant data to memory
            calldatacopy(0x8c, 0x24, 0x80) // salt, chainId, tokenContract, tokenId
            mstore(0x6c, 0x5af43d82803e903d91602b57fd5bf3) // ERC-1167 footer
            mstore(0x5d, _implementation) // implementation
            mstore(0x49, 0x3d60ad80600a3d3981f3363d3d373d3d3d363d73) // ERC-1167 constructor + header

            // Copy create2 computation data to memory
            mstore8(0x00, 0xff) // 0xFF

            mstore(0x01, shl(96, address())) // registry address
            mstore(0x15, _salt) // salt
            mstore(0x35, keccak256(0x55, 0xb7)) // keccak256(bytedcode)

            // Store computed account address in memory
            mstore(0x00, shr(96, shl(96, keccak256(0x00, 0x55))))

            // Return computed account address
            return(0x00, 0x20)
        }
    }
}
