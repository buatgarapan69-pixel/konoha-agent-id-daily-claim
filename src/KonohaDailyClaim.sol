// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice Minimal interface for the Agent ID ERC-721 contract.
///         Only balanceOf is needed: an address holds an Agent ID iff balanceOf > 0.
interface IAgentID {
    function balanceOf(address owner) external view returns (uint256);
}

/// @title Konoha Agent ID Daily Claim
/// @notice Agent ID holders claim a fixed daily KNO reward, once per 24 hours.
///         Agent ID is the identity gate: only addresses that hold an Agent ID
///         (balanceOf > 0 on the Agent ID contract) can claim. The dApp genuinely
///         uses Agent ID as access control, not just as a display badge.
///         Built for the Binance Agent ID Hackathon by Garapan Konoha.
contract KonohaDailyClaim {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    IAgentID public immutable agentId;
    uint256 public immutable claimAmount;
    uint256 public immutable claimCooldown;

    uint256 public totalClaims;
    uint256 public uniqueClaimers;

    mapping(address => uint256) public lastClaimAt;
    mapping(address => uint256) public totalClaimedBy;
    mapping(address => bool) public hasClaimedBefore;

    event Claimed(address indexed claimer, uint256 amount, uint256 timestamp);

    error NotAgentIdHolder();
    error CooldownActive(uint256 nextClaimAt);
    error InsufficientPool(uint256 available, uint256 needed);

    constructor(address _token, address _agentId, uint256 _claimAmount, uint256 _claimCooldown) {
        require(_token != address(0), "token zero");
        require(_agentId != address(0), "agentId zero");
        require(_claimAmount > 0, "amount zero");
        require(_claimCooldown > 0, "cooldown zero");
        token = IERC20(_token);
        agentId = IAgentID(_agentId);
        claimAmount = _claimAmount;
        claimCooldown = _claimCooldown;
    }

    /// @notice True if `account` holds at least one Agent ID.
    function isAgentIdHolder(address account) public view returns (bool) {
        return agentId.balanceOf(account) > 0;
    }

    /// @notice Timestamp when `account` can claim again (0 if never claimed).
    function nextClaimAt(address account) public view returns (uint256) {
        uint256 last = lastClaimAt[account];
        if (last == 0) return 0;
        return last + claimCooldown;
    }

    /// @notice Human-readable eligibility check used by the frontend.
    /// @return ok True when the account can claim right now.
    /// @return reason Empty when ok, otherwise why the claim button is disabled.
    function canClaim(address account) public view returns (bool ok, string memory reason) {
        if (!isAgentIdHolder(account)) {
            return (false, "This address does not hold an Agent ID");
        }
        if (block.timestamp < nextClaimAt(account)) {
            return (false, "Already claimed - come back after 24 hours");
        }
        if (token.balanceOf(address(this)) < claimAmount) {
            return (false, "Reward pool is empty");
        }
        return (true, "");
    }

    /// @notice Claim the daily KNO reward. Caller must hold an Agent ID and
    ///         must not have claimed within the last `claimCooldown` seconds.
    function claim() external {
        if (!isAgentIdHolder(msg.sender)) revert NotAgentIdHolder();
        uint256 next = nextClaimAt(msg.sender);
        if (block.timestamp < next) revert CooldownActive(next);
        uint256 pool = token.balanceOf(address(this));
        if (pool < claimAmount) revert InsufficientPool(pool, claimAmount);

        if (!hasClaimedBefore[msg.sender]) {
            hasClaimedBefore[msg.sender] = true;
            uniqueClaimers += 1;
        }
        lastClaimAt[msg.sender] = block.timestamp;
        totalClaimedBy[msg.sender] += claimAmount;
        totalClaims += 1;

        emit Claimed(msg.sender, claimAmount, block.timestamp);
        token.safeTransfer(msg.sender, claimAmount);
    }
}
