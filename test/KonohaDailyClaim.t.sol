// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {KonohaToken} from "../src/KonohaToken.sol";
import {KonohaDailyClaim} from "../src/KonohaDailyClaim.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @notice Minimal stand-in for the real Agent ID contract (ERC-721, mintable).
contract MockAgentID is ERC721 {
    uint256 private _nextId = 1;

    constructor() ERC721("Agent ID", "AI") {}

    function mint(address to) external returns (uint256 id) {
        id = _nextId++;
        _mint(to, id);
    }
}

contract KonohaDailyClaimTest is Test {
    KonohaToken token;
    KonohaDailyClaim claimContract;
    MockAgentID agentId;

    address holder = address(0xA11CE);
    address holder2 = address(0xBEEF);
    address nonHolder = address(0xB0B);

    uint256 constant CLAIM_AMOUNT = 100 ether; // 100 KNO
    uint256 constant COOLDOWN = 24 hours;
    uint256 constant POOL_FUND = 900_000 ether; // 900,000 KNO

    function setUp() public {
        agentId = new MockAgentID();
        token = new KonohaToken(address(this));
        claimContract = new KonohaDailyClaim(address(token), address(agentId), CLAIM_AMOUNT, COOLDOWN);
        token.transfer(address(claimContract), POOL_FUND);
        agentId.mint(holder);
    }

    function testTokenSupplyAndMetadata() public view {
        assertEq(token.totalSupply(), 1_000_000 ether);
        assertEq(token.name(), "Konoha");
        assertEq(token.symbol(), "KNO");
        assertEq(token.decimals(), 18);
        assertEq(token.balanceOf(address(claimContract)), POOL_FUND);
    }

    function testHolderCanClaim() public {
        vm.prank(holder);
        claimContract.claim();
        assertEq(token.balanceOf(holder), CLAIM_AMOUNT);
        assertEq(claimContract.totalClaims(), 1);
        assertEq(claimContract.uniqueClaimers(), 1);
        assertEq(claimContract.totalClaimedBy(holder), CLAIM_AMOUNT);
        assertEq(claimContract.lastClaimAt(holder), block.timestamp);
    }

    function testNonHolderCannotClaim() public {
        vm.prank(nonHolder);
        vm.expectRevert(KonohaDailyClaim.NotAgentIdHolder.selector);
        claimContract.claim();
    }

    function testCannotClaimTwiceWithin24h() public {
        vm.prank(holder);
        claimContract.claim();
        uint256 next = vm.getBlockTimestamp() + COOLDOWN;
        vm.prank(holder);
        vm.expectRevert(abi.encodeWithSelector(KonohaDailyClaim.CooldownActive.selector, next));
        claimContract.claim();
    }

    function testCanClaimAgainAfter24h() public {
        vm.prank(holder);
        claimContract.claim();
        vm.warp(block.timestamp + COOLDOWN);
        vm.prank(holder);
        claimContract.claim();
        assertEq(token.balanceOf(holder), 2 * CLAIM_AMOUNT);
        assertEq(claimContract.totalClaims(), 2);
        assertEq(claimContract.uniqueClaimers(), 1); // same person, still 1 unique
        assertEq(claimContract.totalClaimedBy(holder), 2 * CLAIM_AMOUNT);
    }

    function testStillCooldownOneSecondBefore24h() public {
        vm.prank(holder);
        claimContract.claim();
        vm.warp(vm.getBlockTimestamp() + COOLDOWN - 1);
        uint256 next = vm.getBlockTimestamp() + 1;
        vm.prank(holder);
        vm.expectRevert(abi.encodeWithSelector(KonohaDailyClaim.CooldownActive.selector, next));
        claimContract.claim();
    }

    function testClaimEmitsEvent() public {
        vm.prank(holder);
        vm.expectEmit(true, false, false, true, address(claimContract));
        emit KonohaDailyClaim.Claimed(holder, CLAIM_AMOUNT, block.timestamp);
        claimContract.claim();
    }

    function testCanClaimReason() public view {
        (bool ok, string memory reason) = claimContract.canClaim(nonHolder);
        assertFalse(ok);
        assertEq(reason, "This address does not hold an Agent ID");

        (bool ok2, string memory reason2) = claimContract.canClaim(holder);
        assertTrue(ok2);
        assertEq(reason2, "");
    }

    function testCanClaimReasonAfterClaim() public {
        vm.prank(holder);
        claimContract.claim();
        (bool ok, string memory reason) = claimContract.canClaim(holder);
        assertFalse(ok);
        assertEq(reason, "Already claimed - come back after 24 hours");
    }

    function testSecondHolderCountsUnique() public {
        agentId.mint(holder2);
        vm.prank(holder);
        claimContract.claim();
        vm.prank(holder2);
        claimContract.claim();
        assertEq(claimContract.uniqueClaimers(), 2);
        assertEq(claimContract.totalClaims(), 2);
    }

    function testRevertsWhenPoolEmpty() public {
        KonohaDailyClaim poor = new KonohaDailyClaim(
            address(token), address(agentId), 1_000_000 ether, COOLDOWN
        );
        vm.prank(holder);
        vm.expectRevert(
            abi.encodeWithSelector(KonohaDailyClaim.InsufficientPool.selector, 0, 1_000_000 ether)
        );
        poor.claim();
    }

    function testNextClaimAt() public {
        assertEq(claimContract.nextClaimAt(holder), 0); // never claimed
        vm.prank(holder);
        claimContract.claim();
        assertEq(claimContract.nextClaimAt(holder), block.timestamp + COOLDOWN);
    }
}
