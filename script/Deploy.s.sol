// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { BaseScript } from "./Base.s.sol";
import { ERC6551Account } from "src/ERC6551Account.sol";
import { ERC6551L1Registry } from "src/ERC6551L1Registry.sol";
import { CCIPERC6551Sender } from "src/bridges/CCIPERC6551Sender.sol";
import { MockNFT } from "test/mocks/MockNFT.sol";
import { Counter } from "test/mocks/Counter.sol";
import { ERC6551L2Account } from "src/ERC6551L2Account.sol";
import { ERC6551L2Registry } from "src/ERC6551L2Registry.sol";
import { CCIPERC6551Receiver } from "src/bridges/CCIPERC6551Receiver.sol";

contract L1Deploy is BaseScript {
    address internal linkCoin = address(0x779877A7B0D9E8603169DdbD7836e478b4624789);
    address internal ccipRouter = address(0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59);

    function run() public broadcast returns (ERC6551L1Registry l1Registry, MockNFT nft, CCIPERC6551Sender sender) {
        ERC6551Account l1Account = new ERC6551Account();
        l1Registry = new ERC6551L1Registry(address(l1Account));

        nft = new MockNFT("NFT", "NFT");

        sender = new CCIPERC6551Sender();
        sender.init(ccipRouter, address(0xde627cDeD2A7241B1f3679821588dB42B62f7699), linkCoin, address(l1Registry));
    }
}

contract L2Deploy is BaseScript {
    address internal baseRouter = address(0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93);

    function run()
        public
        broadcast
        returns (ERC6551L2Registry l2Registry, CCIPERC6551Receiver receiver, Counter counter)
    {
        ERC6551L2Account l2Account = new ERC6551L2Account();
        l2Registry = new ERC6551L2Registry();

        receiver = new CCIPERC6551Receiver();
        receiver.init(
            baseRouter,
            address(0x35eE77607d9466E75072f62D58683Bb697eB2181),
            16_015_286_601_757_825_753,
            address(l2Account),
            address(l2Registry)
        );

        counter = new Counter();
    }
}

contract BridgeTranscation is BaseScript {
    address internal owner = address(0xAFD48f565e1aC63f3e547227c9AD5243990f3D40);

    function run() public broadcast {
        CCIPERC6551Sender sender = CCIPERC6551Sender(payable(address(0x35eE77607d9466E75072f62D58683Bb697eB2181)));
        sender.createAccount(
            owner,
            address(0x2643cD7c2BD7364d3778495CC910e0Cd41d44602),
            1,
            abi.encode(uint64(10_344_971_235_874_465_080))
        );
    }
}
