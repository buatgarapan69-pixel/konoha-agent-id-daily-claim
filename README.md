# Konoha Agent ID Daily Claim

A dApp where **Agent ID holders claim a free daily reward of 100 KNO** — once every
24 hours, no deposit, no fees. Built by **Garapan Konoha** for the
[Binance Agent ID Hackathon](https://www.binance.com/en/support/announcement/detail/95f5dbe0ea674a48a739b59e046648bf)
(submission window: 18 Nov – 9 Dec 2026).

## How Agent ID is used

Agent ID is the **identity gate** of this dApp, not a display badge:

- The claim contract calls `balanceOf(msg.sender)` on the Agent ID contract
  (`0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`, SPACE ID Agent ID, ERC-721,
  BNB Chain mainnet). Only addresses holding an Agent ID (`balanceOf > 0`) can
  call `claim()`. Everyone else reverts with `NotAgentIdHolder`.
- One claim per address per 24 hours, enforced on-chain (`lastClaimAt` +
  `claimCooldown`). The frontend shows the exact reason a claim is unavailable
  via the read-only `canClaim(address)` helper.
- Every claim emits a `Claimed(claimer, amount, timestamp)` event. The frontend
  reads these events to build the **leaderboard of top claimers** and the live
  stats (total claims, unique Agent ID claimers).

## Contracts

| Contract | Description |
|---|---|
| `src/KonohaToken.sol` | ERC-20 `Konoha` (KNO), 18 decimals, fixed supply 1,000,000 KNO minted once to the deployer. No mint function — supply can never increase. OpenZeppelin ERC20. |
| `src/KonohaDailyClaim.sol` | Daily claim faucet. Immutable: token, Agent ID contract, claim amount (100 KNO), cooldown (24h). Tracks `totalClaims`, `uniqueClaimers`, `totalClaimedBy`, `lastClaimAt`. Uses SafeERC20. |

Economics: 900,000 KNO funds the reward pool (9,000 daily claims), 100,000 KNO
stay with the deployer. At 100 KNO/day, the pool lasts ~24 years for one daily
claimer, or ~9,000 claim-days total.

## Project structure

```
dapp/
├── src/
│   ├── KonohaToken.sol        # ERC-20 reward token
│   └── KonohaDailyClaim.sol   # daily claim contract (Agent ID gated)
├── test/
│   └── KonohaDailyClaim.t.sol # 12 forge tests, incl. MockAgentID (ERC-721)
├── script/
│   ├── Deploy.s.sol           # mainnet deployment script
│   └── MeasureGas.s.sol       # local-only gas measurement (anvil)
├── frontend/
│   └── index.html             # static web app, no build step (ethers v6 CDN)
├── foundry.toml
└── README.md
```

## Build & test

Requires [Foundry](https://getfoundry.sh) (`forge`, `cast`, `anvil`).

```bash
forge build
forge test
```

Expected: `12 tests passed, 0 failed`. The tests use a `MockAgentID` ERC-721
stand-in for the real Agent ID contract and cover: holder claims, non-holder
revert, 24h cooldown (including 1-second-before-boundary), claim after 24h,
event emission, `canClaim` reasons, unique-claimer counting, empty-pool revert,
and token supply/metadata.

## Deployment (BNB Chain mainnet, chain 56)

> **Deployed 18 Nov 2026.** Both contracts are live on BNB Chain mainnet.
>
> | Contract | Address |
> |---|---|
> | KonohaToken (KNO) | `0xf48BAA77d67d3d5De6E60aF354DDd0d5deEaD47b` |
> | KonohaDailyClaim | `0x1F9a91fc0965Cb03aBD65035665329681141dcEd` |
>
> Deployment txs: token `0xca83cf4bc8029b3388bbc28fe121ecac63fa2bc12caf3443dce0c7319bfc09e2`
> (block 134331772); claim `0xb71c69a90b53f99b8e6f3fa7127abf11d4925f7f61dfcbd978aac71b4e7e2739`
> (block 134331914). Both verified on Sourcify (exact_match). The deployer is the
> Agentic Wallet `0xeD16208263f0Bba61aD01163d636B490C292881A` (Agent ID `hatake.ai`).
> Because the Agentic Wallet signs through the Binance `baw` CLI (no exportable
> private key), the contracts were deployed via the deterministic deployment
> proxy (CREATE2, `0x4e59b44847b379578588920cA78FbF26c0B4956C`) — see
> `script/ComputeCreate2.s.sol` for the address computation. `KonohaToken`
> mints to a constructor-supplied recipient so the supply lands on the Agentic
> Wallet even when deployed through the factory.
>
> **Pool funding pending:** the 900,000 KNO transfer to the claim contract is
> awaiting in-app confirmation in the Binance app (the wallet flags the new
> contract as medium-risk). The deployer currently holds the full 1,000,000 KNO.

### Steps

1. **Top up BNB** on the deployer (the Agentic Wallet,
   `0xeD16208263f0Bba61aD01163d636B490C292881A`). Recommended **0.005 BNB**
   (~$2.95 at $589.72/BNB) — covers deployment at gas prices up to ~4.3 gwei.
2. **Set the deployer key** (never commit it):
   ```bash
   export PRIVATE_KEY=<deployer private key>
   ```
3. **Deploy both contracts + fund the pool** (one script, three transactions):
   ```bash
   forge script script/Deploy.s.sol --tc Deploy \
     --rpc-url https://bsc-dataseed.binance.org/ \
     --private-key $PRIVATE_KEY --broadcast
   ```
   Order inside the script: (1) deploy `KonohaToken`, (2) deploy
   `KonohaDailyClaim(token, agentId, 100 ether, 24 hours)`, (3) transfer
   900,000 KNO to the claim contract. Copy the two contract addresses from the
   output.
4. **Verify both contracts on BscScan** (makes them "verifiable" per the
   hackathon rules):
   ```bash
   forge verify-contract <TOKEN_ADDRESS> src/KonohaToken.sol:KonohaToken \
     --chain 56 --etherscan-api-key $BSCSCAN_API_KEY
   forge verify-contract <CLAIM_ADDRESS> src/KonohaDailyClaim.sol:KonohaDailyClaim \
     --chain 56 --etherscan-api-key $BSCSCAN_API_KEY \
     --constructor-args $(cast abi-encode "constructor(address,address,uint256,uint256)" <TOKEN_ADDRESS> 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F 100000000000000000000 86400)
   ```
5. **Configure the frontend**: in `frontend/index.html`, set
   `CLAIM_CONTRACT_ADDRESS`, `TOKEN_ADDRESS`, and `START_BLOCK` (the claim
   contract's deployment block, so the leaderboard scan starts there).
6. **Host the frontend** as a static site (GitHub Pages, Netlify, or Vercel —
   no build step, just serve `frontend/index.html`).
7. **Smoke-test on mainnet**: connect the Agentic Wallet (Agent ID `hatake.ai`,
   verified holder: `balanceOf` = 1 on 18 Nov 2026), claim once, confirm the
   `Claimed` event on BscScan and the leaderboard update.
8. **Submit** to the hackathon with the materials in `SUBMISSION.md`.

### Gas cost (real mainnet receipts, 18 Nov 2026)

BNB price ~$586 (Binance, 18 Nov 2026). BSC gas price at deployment:
~0.07–0.08 gwei.

| Step | Gas used |
|---|---|
| Deploy `KonohaToken` (via CREATE2 factory) | 555,412 |
| Deploy `KonohaDailyClaim` (via CREATE2 factory) | 571,580 |
| Fund pool (transfer 900,000 KNO) | pending (awaiting in-app confirmation) |
| **Total deployment so far** | **1,126,992** |
| One `claim()` (first claim, cold storage) | not yet measured on mainnet |

| Gas price | Deployment cost | Claim cost |
|---|---|---|
| 0.05 gwei (current) | 0.000059 BNB (~$0.03) | 0.000008 BNB |
| 0.1 gwei | 0.000117 BNB (~$0.07) | 0.000016 BNB |
| 1 gwei | 0.001172 BNB (~$0.69) | 0.000157 BNB (~$0.09) |
| 3 gwei | 0.003517 BNB (~$2.07) | 0.000470 BNB |
| 5 gwei | 0.005861 BNB (~$3.46) | 0.000783 BNB |

## Frontend

`frontend/index.html` — a single static file, no build step. It uses
[ethers v6](https://cdn.jsdelivr.net/npm/ethers@6.13.4/dist/ethers.umd.min.js)
from a CDN and `window.ethereum` (MetaMask / Binance Wallet).

Features:

- Connect wallet, auto-detect BNB Chain (chain 56) with a switch-network button.
- Shows whether the connected address holds an Agent ID, KNO balance, and next
  claim time (countdown).
- Claim button is disabled with the exact reason when ineligible
  (`canClaim` — no Agent ID / already claimed / pool empty).
- Live stats: reward pool left, total claims, unique Agent ID claimers
  (refreshed every 30s).
- Leaderboard of top 10 claimers, aggregated from `Claimed` events
  (chunked `eth_getLogs` scan from `START_BLOCK`).
- Contract addresses + BscScan links.

## Security notes

- No owner/admin functions on either contract: no mint, no pause, no
  withdrawal. The deployer cannot drain the reward pool or change the rules
  after deployment.
- `KonohaDailyClaim` follows checks-effects-interactions and uses SafeERC20.
- The claim contract only reads `balanceOf` from the Agent ID contract; it
  never moves or touches Agent IDs (they are non-transferable anyway).
- No private keys, mnemonics, or session files are in this repo. The
  `MeasureGas` script uses only the public anvil test key.

## License

MIT — see `LICENSE`.
