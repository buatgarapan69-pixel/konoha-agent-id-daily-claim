// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Konoha — reward token for the Konoha Agent ID Daily Claim dApp.
/// @notice Fixed supply of 1,000,000 KNO, minted once to the recipient at deployment.
///         There is no mint function: supply can never increase.
///         The recipient is a constructor argument (instead of msg.sender) so
///         the token can be deployed through a CREATE2 factory while the
///         supply still lands on the intended holder (the Agentic Wallet).
///         Built for the Binance Agent ID Hackathon by Garapan Konoha.
contract KonohaToken is ERC20 {
    uint256 public constant TOTAL_SUPPLY = 1_000_000 * 10 ** 18;

    constructor(address recipient) ERC20("Konoha", "KNO") {
        require(recipient != address(0), "recipient zero");
        _mint(recipient, TOTAL_SUPPLY);
    }
}
