// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IRouterClient } from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import { Client } from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Initializable } from "solady/src/utils/Initializable.sol";
import { IERC6551L1Registry } from "src/interfaces/IERC6551L1Registry.sol";
import { IERC6551L1Account } from "src/interfaces/IERC6551L1Account.sol";

contract CCIPERC6551Sender is Initializable {
    using SafeERC20 for IERC20;

    error NotOwner(address);
    // Event emitted when a message is sent to another chain.
    // The chain selector of the destination chain.
    // The address of the receiver on the destination chain.
    // the token address used to pay CCIP fees.

    event MessageSent( // The unique ID of the CCIP message.
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address receiver,
        address feeToken,
        uint256 fees,
        address nft,
        uint256 tokenId
    );

    address public ccipRouter;
    address public ccipReceiver;
    address public erc6551Registry;
    IERC20 private s_linkToken;

    /// @notice Constructor initializes the contract with the router address.
    /// @param _router The address of the router contract.
    /// @param _link The address of the link contract.
    function init(address _router, address _ccipReceiver, address _link, address _registry) public initializer {
        s_linkToken = IERC20(_link);
        ccipRouter = _router;
        ccipReceiver = _ccipReceiver;
        erc6551Registry = _registry;
        s_linkToken.approve(address(_router), type(uint256).max);
    }

    function createAccount(address owner, address nft, uint256 tokenId, bytes calldata extraArgs) external {
        address erc6551Account = IERC6551L1Registry(erc6551Registry).createAccount(nft, tokenId);

        if (IERC6551L1Account(payable(erc6551Account)).owner() != msg.sender) revert NotOwner(msg.sender);

        uint64 _destinationChainSelector = abi.decode(extraArgs, (uint64));
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        Client.EVM2AnyMessage memory evm2AnyMessage =
            _buildCCIPMessage(ccipReceiver, address(s_linkToken), abi.encodePacked(owner, nft, tokenId));

        // Initialize a router client instance to interact with cross-chain router
        IRouterClient router = IRouterClient(ccipRouter);

        // Get the fee required to send the CCIP message
        uint256 fees = router.getFee(_destinationChainSelector, evm2AnyMessage);

        s_linkToken.safeTransferFrom(msg.sender, address(this), fees + 1);

        // Send the CCIP message through the router and store the returned CCIP message ID
        bytes32 messageId = router.ccipSend(_destinationChainSelector, evm2AnyMessage);

        // Emit an event with message details
        emit MessageSent(messageId, _destinationChainSelector, ccipReceiver, address(s_linkToken), fees, nft, tokenId);
    }

    function _buildCCIPMessage(
        address _receiver,
        address _feeTokenAddress,
        bytes memory args
    )
        private
        pure
        returns (Client.EVM2AnyMessage memory)
    {
        return Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver),
            data: args,
            tokenAmounts: new Client.EVMTokenAmount[](0), // Empty array aas no tokens are transferred
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({ gasLimit: 2_000_000 })),
            feeToken: _feeTokenAddress
        });
    }

    /// @notice Fallback function to allow the contract to receive Ether.
    /// @dev This function has no function body, making it a default function for receiving Ether.
    /// It is automatically called when Ether is sent to the contract without any data.
    receive() external payable { }
}
