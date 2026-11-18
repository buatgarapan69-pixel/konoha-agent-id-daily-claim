# Hackathon Submission — Draft Materials

> Fill in contract addresses + website URL after deployment. Do not submit
> before the contracts are deployed, verified on BscScan, and smoke-tested.

## Project name

**Konoha Agent ID Daily Claim**

## One-paragraph description

Konoha Agent ID Daily Claim is a free daily faucet for Agent ID holders on BNB
Chain. Anyone holding an Agent ID can connect their wallet and claim 100 KNO
tokens once every 24 hours — no deposit, no fees, no sign-up. The dApp shows
live stats (reward pool, total claims, unique claimers) and a leaderboard of
top claimers built from on-chain claim events. It is built by Garapan Konoha,
a community that hunts free on-chain opportunities, and it gives every Agent
ID a daily reason to be used.

## Agent ID usage description (for the submission form)

Agent ID is the core access-control mechanism of this dApp. The
`KonohaDailyClaim` smart contract calls `balanceOf(msg.sender)` on the Agent
ID contract (0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F) on every claim: only
addresses that hold an Agent ID can claim the daily 100 KNO reward, and the
transaction reverts otherwise. The 24-hour cooldown is also enforced on-chain
per claiming address, and each claim emits a `Claimed` event that powers the
public leaderboard. Agent ID is therefore not a badge or a display field — it
is the identity check that gates the entire product: no Agent ID, no reward.

## Contracts (deployed 18 Nov 2026, BNB Chain mainnet)

| Contract | Address | BscScan |
|---|---|---|
| KonohaToken (KNO) | `0xf48BAA77d67d3d5De6E60aF354DDd0d5deEaD47b` | https://bscscan.com/address/0xf48BAA77d67d3d5De6E60aF354DDd0d5deEaD47b |
| KonohaDailyClaim | `0x1F9a91fc0965Cb03aBD65035665329681141dcEd` | https://bscscan.com/address/0x1F9a91fc0965Cb03aBD65035665329681141dcEd |

- Agent ID contract: `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`
- Chain: BNB Chain mainnet (56)
- Source code: this repo (MIT). Both contracts verified on Sourcify (exact_match, incl. creation match). BscScan verification pending (needs BscScan API key — not available yet).
- Deployment txs: token `0xca83cf4bc8029b3388bbc28fe121ecac63fa2bc12caf3443dce0c7319bfc09e2` (block 134331772, gas 555,412); claim `0xb71c69a90b53f99b8e6f3fa7127abf11d4925f7f61dfcbd978aac71b4e7e2739` (block 134331914, gas 571,580).
- Deployer: Agentic Wallet `0xeD16208263f0Bba61aD01163d636B490C292881A` (Agent ID `hatake.ai`), via the deterministic deployment proxy (CREATE2).
- KNO: 1,000,000 minted to the deployer; name `Konoha`, symbol `KNO`, 18 decimals.
- Claim params: 100 KNO per claim, 24h cooldown, token `0xf48BAA77d67d3d5De6E60aF354DDd0d5deEaD47b`, Agent ID `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`.

## Website (pending hosting)

Frontend (`frontend/index.html`) is configured with the deployed contract addresses and START_BLOCK 134331914. Hosting pending: serv00 registration (username `garapankonoha`) submitted 18 Nov 19:15 WIB, still awaiting review (no approval email in Gmail as of 18 Nov ~22:00 WIB). Fallback: GitHub Pages — repo creation via the GitHub App is blocked (403 "Resource not accessible by integration"), so the repo must be created via the GitHub website, then push + enable Pages.

`TODO` — public URL once hosted.

## Checklist before submitting

- [x] Both contracts deployed on BNB mainnet
- [x] Both contracts verified on Sourcify (exact_match) — BscScan verification still pending (needs API key)
- [ ] Reward pool funded with 900,000 KNO — **BLOCKED: transfer is pending in-app confirmation in the Binance app** (order 26111800002064345143; the Agentic Wallet flags the transfer to the new claim contract as medium-risk and requires the user to confirm it in the app). The deployer holds the full 1,000,000 KNO; once confirmed, the claim contract holds 900,000 KNO and the deployer keeps 100,000 KNO.
- [x] Frontend configured (contract addresses + START_BLOCK 134331914)
- [ ] Frontend hosted (public URL) — pending serv00 approval or GitHub Pages (repo must be created via the GitHub website)
- [ ] Smoke test: claim once from the Agentic Wallet (hatake.ai), confirm the
      `Claimed` event and the leaderboard update on the live site — **blocked until the pool is funded**
- [ ] GitHub repo public, README complete — repo creation blocked via the GitHub App (403); create via the GitHub website, then push
- [ ] Submission form filled with the materials above
