// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IERC6551Sender } from "src/interfaces/IERC6551Sender.sol";

contract ERC6551Bridge {
    function bridgeToL2(
        address bridgeModule,
        address owner,
        address nft,
        uint256 tokenId,
        bytes calldata extraArgs
    )
        public
    {
        IERC6551Sender(bridgeModule).createAccount(owner, nft, tokenId, extraArgs);
    }
}
