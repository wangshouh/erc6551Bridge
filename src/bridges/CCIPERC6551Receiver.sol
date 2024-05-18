// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IRouterClient } from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import { Client } from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import { CCIPReceiver } from "./CCIPInitReceiver.sol";
import { Initializable } from "solady/src/utils/Initializable.sol";
import { IERC6551L2Registry } from "src/interfaces/IERC6551L2Registry.sol";

contract CCIPERC6551Receiver is CCIPReceiver, Initializable {
    error SenderNotAllowlisted(address sender);
    error SourceChainNotAllowlisted(uint64 sourceChainSelector);

    event MessageReceived(bytes32 indexed messageId, uint64 indexed sourceChainSelector, address sender, bytes text);

    bytes32 private s_lastReceivedMessageId; // Store the last received messageId.
    bytes private s_lastReceivedData; // Store the last received text.

    address public l1Bridge;
    uint64 public l1ChainSelector;
    address public accountImpl;
    address public factory;
    bytes32 public constant salt = keccak256("l2");

    function init(
        address _router,
        address _l1Bridge,
        uint64 _l1ChainSelector,
        address _accountImpl,
        address _factory
    )
        public
        initializer
    {
        i_ccipRouter = _router;
        l1Bridge = _l1Bridge;
        l1ChainSelector = _l1ChainSelector;
        accountImpl = _accountImpl;
        factory = _factory;
    }

    modifier onlyAllowL1Bridge(uint64 sourceChainSelector, address messgeSender) {
        if (sourceChainSelector != l1ChainSelector) revert SourceChainNotAllowlisted(sourceChainSelector);
        if (messgeSender != l1Bridge) revert SenderNotAllowlisted(messgeSender);
        _;
    }
    /// handle a received message

    function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage)
        internal
        override
        onlyAllowL1Bridge(any2EvmMessage.sourceChainSelector, abi.decode(any2EvmMessage.sender, (address)))
    {
        s_lastReceivedMessageId = any2EvmMessage.messageId; // fetch the messageId
        s_lastReceivedData = any2EvmMessage.data; // abi-decoding of the sent text
        (address owner, address nft, uint256 tokenId) = _decodeArgs(s_lastReceivedData);
        IERC6551L2Registry(factory).createAccount(accountImpl, salt, nft, tokenId, owner);

        emit MessageReceived(
            any2EvmMessage.messageId,
            any2EvmMessage.sourceChainSelector, // fetch the source chain identifier (aka selector)
            abi.decode(any2EvmMessage.sender, (address)), // abi-decoding of the sender address,
            any2EvmMessage.data
        );
    }

    function _decodeArgs(bytes memory data) internal pure returns (address owner, address nft, uint256 tokenId) {
        assembly {
            owner := shr(0x60, mload(add(data, 0x20)))
            nft := shr(0x60, mload(add(data, 0x34)))
            tokenId := mload(add(data, 0x48))
        }
    }

    /// @notice Fallback function to allow the contract to receive Ether.
    /// @dev This function has no function body, making it a default function for receiving Ether.
    /// It is automatically called when Ether is sent to the contract without any data.
    receive() external payable { }
}
