// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {KonohaToken} from "../src/KonohaToken.sol";
import {KonohaDailyClaim} from "../src/KonohaDailyClaim.sol";

/// @notice Computes the CREATE2 addresses for deploying via the deterministic
///         deployment proxy (0x4e59b44847b379578588920cA78FbF26c0B4956C).
///         Read-only: no broadcast. Run with `forge script --sig run()`.
contract ComputeCreate2 is Script {
    address constant PROXY = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
    address constant AGENT_ID_MAINNET = 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F;

    function run() external {
        address recipient = 0xeD16208263f0Bba61aD01163d636B490C292881A; // Agentic Wallet
        bytes32 tokenSalt = keccak256("KonohaToken-v1");
        bytes32 claimSalt = keccak256("KonohaDailyClaim-v1");

        bytes memory tokenInit = abi.encodePacked(
            type(KonohaToken).creationCode, abi.encode(recipient)
        );
        address tokenAddr = _create2(PROXY, tokenSalt, tokenInit);

        bytes memory claimInit = abi.encodePacked(
            type(KonohaDailyClaim).creationCode,
            abi.encode(tokenAddr, AGENT_ID_MAINNET, uint256(100 ether), uint256(24 hours))
        );
        address claimAddr = _create2(PROXY, claimSalt, claimInit);

        console.log("TOKEN_SALT:    ", vm.toString(tokenSalt));
        console.log("TOKEN_INIT_LEN:", tokenInit.length);
        console.log("TOKEN_ADDR:    ", tokenAddr);
        console.log("CLAIM_SALT:    ", vm.toString(claimSalt));
        console.log("CLAIM_INIT_LEN:", claimInit.length);
        console.log("CLAIM_ADDR:    ", claimAddr);

        // Factory calldata: deploy(bytes _code, bytes32 _salt), selector 0x4af63f02
        bytes memory tokenCalldata = abi.encodeWithSignature("deploy(bytes,bytes32)", tokenInit, tokenSalt);
        bytes memory claimCalldata = abi.encodeWithSignature("deploy(bytes,bytes32)", claimInit, claimSalt);
        vm.writeFile("deploy-artifacts/token_init.txt", vm.toString(tokenInit));
        vm.writeFile("deploy-artifacts/claim_init.txt", vm.toString(claimInit));
        vm.writeFile("deploy-artifacts/token_deploy_calldata.txt", vm.toString(tokenCalldata));
        vm.writeFile("deploy-artifacts/claim_deploy_calldata.txt", vm.toString(claimCalldata));
        vm.writeFile(
            "deploy-artifacts/deploy_summary.json",
            string(
                abi.encodePacked(
                    '{"token":"', vm.toString(tokenAddr),
                    '","claim":"', vm.toString(claimAddr),
                    '","tokenSalt":"', vm.toString(tokenSalt),
                    '","claimSalt":"', vm.toString(claimSalt),
                    '","proxy":"', vm.toString(PROXY), '"}'
                )
            )
        );
    }

    function _create2(address factory, bytes32 salt, bytes memory init) internal pure returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), factory, salt, keccak256(init))))));
    }
}
