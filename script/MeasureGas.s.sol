// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {KonohaToken} from "../src/KonohaToken.sol";
import {KonohaDailyClaim} from "../src/KonohaDailyClaim.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @notice Tiny stand-in for the real Agent ID contract, local use only.
contract MockAgentIDLocal is ERC721 {
    constructor() ERC721("Agent ID", "AI") {}

    function mint(address to) external {
        _mint(to, 1);
    }
}

/// @notice Local-only gas measurement: deploys everything on anvil and
///         executes one claim, so the run receipts show real gas usage.
///         NOT for mainnet use.
contract MeasureGas is Script {
    function run() external {
        vm.startBroadcast();
        MockAgentIDLocal agentId = new MockAgentIDLocal();
        KonohaToken token = new KonohaToken(msg.sender);
        KonohaDailyClaim claimContract =
            new KonohaDailyClaim(address(token), address(agentId), 100 ether, 24 hours);
        token.transfer(address(claimContract), 900_000 ether);
        agentId.mint(msg.sender);
        claimContract.claim();
        vm.stopBroadcast();

        console.log("MockAgentID:      ", address(agentId));
        console.log("KonohaToken:      ", address(token));
        console.log("KonohaDailyClaim: ", address(claimContract));
    }
}
