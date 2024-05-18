// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IERC6551L2Registry } from "./interfaces/IERC6551L2Registry.sol";
import { IERC6551L2Account } from "./interfaces/IERC6551L2Account.sol";

contract ERC6551L2Registry is IERC6551L2Registry {
    error ReceiverNotAllowlisted(address receiver);

    mapping(address user => mapping(address receiver => bool)) public allowlistedBridge;

    function setAllowistedBridge(address receiver, bool flag) public {
        allowlistedBridge[msg.sender][receiver] = flag;
    }

    function createAccount(
        address implementation,
        bytes32 salt,
        address tokenContract,
        uint256 tokenId,
        address owner
    )
        public
        override
        returns (address result)
    {
        if (!allowlistedBridge[owner][msg.sender]) revert ReceiverNotAllowlisted(msg.sender);
        uint256 chainId = 1;
        assembly {
            // Silence unused variable warnings
            let m := mload(0x40) // Grab the free memory pointer.
            pop(chainId)

            mstore(add(m, 0xec), tokenId)
            mstore(add(m, 0xcc), tokenContract)
            mstore(add(m, 0xac), chainId)
            mstore(add(m, 0x8c), salt)
            mstore(add(m, 0x6c), 0x5af43d82803e903d91602b57fd5bf3) // ERC-1167 footer
            mstore(add(m, 0x5d), implementation) // implementation
            mstore(add(m, 0x49), 0x3d60ad80600a3d3981f3363d3d373d3d3d363d73) // ERC-1167 constructor + header

            // Copy create2 computation data to memory
            mstore(add(m, 0x35), keccak256(add(m, 0x55), 0xb7)) // keccak256(bytecode)
            mstore(add(m, 0x01), shl(96, address())) // registry address
            mstore(add(m, 0x15), salt) // salt
            mstore8(m, 0xff) // 0xFF

            // Compute account address
            let computed := keccak256(m, 0x55)

            // If the account has not yet been deployed
            switch iszero(extcodesize(computed))
            case 1 {
                // Deploy account contract
                let deployed := create2(0, add(m, 0x55), 0xb7, salt)

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
                    implementation,
                    tokenContract,
                    tokenId
                )

                let initSelector := 0xf09a4016
                mstore(m, initSelector)
                mstore(add(m, 0x20), address())
                mstore(add(m, 0x40), shr(96, shl(96, owner)))

                if iszero(call(gas(), mload(add(m, 0x6c)), 0, add(m, 0x1c), 0x44, m, 0x20)) {
                    if returndatasize() {
                        // Bubble up the revert if the call reverts.
                        returndatacopy(m, 0x00, returndatasize())
                        revert(m, returndatasize())
                    }
                }

                // Return the account address
                mstore(m, shl(96, deployed))
            }
            default {
                // Otherwise, return the computed account address
                let setOwnerSelector := 0x13af4035
                mstore(m, setOwnerSelector)
                mstore(add(m, 0x20), shr(96, shl(96, owner)))

                if iszero(call(gas(), shr(96, shl(96, computed)), 0, add(m, 0x1c), 0x44, m, 0x20)) {
                    if returndatasize() {
                        // Bubble up the revert if the call reverts.
                        returndatacopy(m, 0x00, returndatasize())
                        revert(m, returndatasize())
                    }
                }

                mstore(m, shl(96, computed))
            }
            result := shr(96, mload(m)) // Load the result.
            mstore(0x40, add(m, 0x14)) // Restore the free memory pointer.
        }

        // IERC6551L2Account(result).init(address(this), owner);
    }

    function account(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    )
        external
        view
        override
        returns (address)
    {
        // uint256 chainId = 1;
        assembly {
            // Silence unused variable warnings
            pop(chainId)
            pop(tokenContract)
            pop(tokenId)

            // Copy bytecode + constant data to memory
            calldatacopy(0x8c, 0x24, 0x80) // salt, chainId, tokenContract, tokenId
            mstore(0x6c, 0x5af43d82803e903d91602b57fd5bf3) // ERC-1167 footer
            mstore(0x5d, implementation) // implementation
            mstore(0x49, 0x3d60ad80600a3d3981f3363d3d373d3d3d363d73) // ERC-1167 constructor + header

            // Copy create2 computation data to memory
            mstore8(0x00, 0xff) // 0xFF

            mstore(0x01, shl(96, address())) // registry address
            mstore(0x15, salt) // salt
            mstore(0x35, keccak256(0x55, 0xb7)) // keccak256(bytedcode)

            // Store computed account address in memory
            mstore(0x00, shr(96, shl(96, keccak256(0x00, 0x55))))

            // Return computed account address
            return(0x00, 0x20)
        }
    }
}
