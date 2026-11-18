// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {KonohaToken} from "../src/KonohaToken.sol";
import {KonohaDailyClaim} from "../src/KonohaDailyClaim.sol";

/// @notice Deploys KonohaToken, then KonohaDailyClaim, then funds the reward
///         pool with 900,000 KNO (the other 100,000 KNO stay with the deployer).
/// @dev Env vars (all optional):
///      AGENT_ID     — Agent ID contract (default: BNB mainnet Agent ID)
///      CLAIM_AMOUNT — KNO per claim, in wei (default: 100 ether)
///      POOL_FUND    — KNO sent to the claim contract, in wei (default: 900000 ether)
contract Deploy is Script {
    address constant AGENT_ID_MAINNET = 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F;

    function run() external {
        address agentId = vm.envOr("AGENT_ID", AGENT_ID_MAINNET);
        uint256 claimAmount = vm.envOr("CLAIM_AMOUNT", uint256(100 ether));
        uint256 poolFund = vm.envOr("POOL_FUND", uint256(900_000 ether));

        vm.startBroadcast();
        KonohaToken token = new KonohaToken(msg.sender);
        KonohaDailyClaim claimContract =
            new KonohaDailyClaim(address(token), agentId, claimAmount, 24 hours);
        token.transfer(address(claimContract), poolFund);
        vm.stopBroadcast();

        console.log("KonohaToken:      ", address(token));
        console.log("KonohaDailyClaim: ", address(claimContract));
        console.log("Agent ID:         ", agentId);
        console.log("Claim amount KNO: ", claimAmount / 1 ether);
        console.log("Pool funded KNO:  ", poolFund / 1 ether);
    }
}
