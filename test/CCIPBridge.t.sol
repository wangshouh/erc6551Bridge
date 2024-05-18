// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Test } from "forge-std/src/Test.sol";
import { CCIPLocalSimulator } from "chainlink-local/src/ccip/CCIPLocalSimulator.sol";
import { IRouterClient } from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import { LinkToken } from "chainlink-local/src/shared/LinkToken.sol";
import { CCIPERC6551Sender } from "src/bridges/CCIPERC6551Sender.sol";
import { CCIPERC6551Receiver } from "src/bridges/CCIPERC6551Receiver.sol";
import { CreateX } from "createx/src/CreateX.sol";
import { ERC6551L2Account } from "src/ERC6551L2Account.sol";
import { ERC6551L2Registry } from "src/ERC6551L2Registry.sol";

contract CCIPBridgeTest is Test {
    CreateX public createX;
    CCIPERC6551Sender public sender;
    CCIPERC6551Receiver public receiver;
    CCIPLocalSimulator public ccipLocalSimulator;
    IRouterClient public sourceRouter;
    IRouterClient public destinationRouter;
    LinkToken public linkToken;
    ERC6551L2Account public l2Account;
    ERC6551L2Registry internal l2Registry;
    uint64 public chainSelector;

    function setUp() public {
        ccipLocalSimulator = new CCIPLocalSimulator();
        l2Account = new ERC6551L2Account();
        l2Registry = new ERC6551L2Registry();
        createX = new CreateX();

        CreateX.Values memory values;

        bytes memory receiverCode = abi.encodePacked(type(CCIPERC6551Receiver).creationCode);
        bytes memory senderCode = abi.encodePacked(type(CCIPERC6551Sender).creationCode);

        bytes32 receiverSalt = bytes32(abi.encodePacked(msg.sender, hex"00", bytes11(uint88(1))));
        bytes32 senderSalt = bytes32(abi.encodePacked(msg.sender, hex"00", bytes11(uint88(2))));

        address computeReceiverAddress = createX.computeCreate2Address(receiverSalt, keccak256(receiverCode));
        address computeSenderAddress = createX.computeCreate2Address(senderSalt, keccak256(senderCode));

        (chainSelector, sourceRouter, destinationRouter,, linkToken,,) = ccipLocalSimulator.configuration();

        address payable receiverDeployAddress = payable(
            createX.deployCreate2AndInit(
                receiverSalt,
                receiverCode,
                abi.encodeWithSignature(
                    "init(address,address,uint64,address,address)",
                    address(destinationRouter),
                    computeSenderAddress,
                    uint64(chainSelector),
                    address(l2Account),
                    address(l2Registry)
                ),
                values
            )
        );
        receiver = CCIPERC6551Receiver(receiverDeployAddress);
        assertEq(receiverDeployAddress, computeReceiverAddress);
        address payable senderDeployAddress = payable(
            createX.deployCreate2AndInit(
                senderSalt,
                senderCode,
                abi.encodeWithSignature(
                    "init(address,address,address)", address(sourceRouter), computeReceiverAddress, address(linkToken)
                ),
                values
            )
        );
        sender = CCIPERC6551Sender(senderDeployAddress);
        ccipLocalSimulator.requestLinkFromFaucet(address(this), 100 ether);
    }

    function test_Send() public {
        linkToken.approve(address(sender), 100 ether);
        sender.createAccount(address(1), address(2), 5, abi.encode(chainSelector));
        // (, address owner, address nft, uint256 tokenId) = receiver.getLastReceivedMessageDetails();
        ERC6551L2Account l2TestAccount = ERC6551L2Account(payable(l2Registry.account(address(l2Account), keccak256("l2"), 1, address(2), 5)));
        assertEq(l2TestAccount.owner(), address(1));

        sender.createAccount(address(11), address(2), 5, abi.encode(chainSelector));
        l2TestAccount = ERC6551L2Account(payable(l2Registry.account(address(l2Account), keccak256("l2"), 1, address(2), 5)));
        assertEq(l2TestAccount.owner(), address(11));
    }

    function test_dupInit() public {
        vm.expectRevert();
        sender.init(address(sourceRouter), address(receiver), address(linkToken));
    }
}
