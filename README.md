# MediChain Pay

> **The bridge between home health agencies and CMS.**
> Blockchain-powered payment acceleration for Medicare & Medicaid providers.

[![Solidity](https://img.shields.io/badge/Solidity-0.8.20-363636?logo=solidity)](https://soliditylang.org)
[![Base Network](https://img.shields.io/badge/Base-Network-0052FF?logo=coinbase)](https://base.org)
[![USDC](https://img.shields.io/badge/USDC-Circle-2775CA)](https://www.circle.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## The Problem

Home health agencies and other Medicare/Medicaid providers face a structural cash flow crisis rooted in slow government reimbursement cycles:

- **Medicare** pays in 14–30 days on clean claims
- **Medicaid managed care** stretches to 60–90 days
- **Traditional factoring companies** charge 3–6% per claim to bridge the gap
- The **RAP (Request for Anticipated Payment)** program was eliminated in 2022 — removing the only early payment mechanism that existed
- Agencies routinely take on **lines of credit** just to cover payroll while waiting on reimbursement
- Over **$100 billion** is lost annually across the healthcare system to payment delays and inefficiency

This is not a theoretical problem. This platform was built by a home health agency owner with 5+ years of firsthand experience navigating these exact cash flow constraints.

---

## The Solution — MediChain Pay Is The Bridge

```
CMS / Medicaid                MediChain Pay              Home Health Agency
──────────────                ─────────────              ──────────────────
Slow payer        →           The Bridge          →      Needs cash now
14–90 day wait                Advances instantly          Payroll due Friday
ACH remittance                Holds the risk              Submits clean claims
Pays eventually               Collects when paid          Gets paid in minutes
```

MediChain Pay replaces the factoring company with a smart contract — cheaper, faster, and fully transparent.

| | Traditional Factoring | MediChain Pay |
|---|---|---|
| **Fee** | 3–6% per claim | 1.5% per claim |
| **Speed** | 24–72 hours | Minutes |
| **Transparency** | Opaque | Full on-chain audit trail |
| **Minimum size** | Often $10,000+ | $100 |
| **Availability** | Business hours | 24/7/365 |

---

## How It Works

### The Claim Lifecycle

```
STEP 1 — Agency Submits Claim
Agency submits verified clean claim via portal
        ↓
Smart contract records claim on-chain
Calculates: 85% advance + 5% reserve + 1.5% fee
Status → "Submitted"

STEP 2 — Platform Reviews & Approves
Owner reviews claim via admin dashboard
Clearinghouse API validates claim eligibility
        ↓
advanceFunds() triggered
Status → "Advanced"

STEP 3 — Agency Receives USDC Instantly
85% of claim value sent to agency wallet in minutes
5% reserve held in smart contract escrow
        ↓
Agency makes payroll — no lines of credit needed

STEP 4 — CMS Remits Payment (14–90 days later)
CMS sends ACH remittance to agency bank account
Agency converts to USDC and authorizes repayment
        ↓
repayAdvance() triggered
Platform collects: advance principal + 1.5% fee
Status → "Repaid"

STEP 5 — Reserve Released (180 days after advance)
If no CMS recoupment within 180 days:
        ↓
releaseReserve() triggered
$250 reserve returned to agency
Status → "Reserve Released"

IF CMS CLAWS BACK — Recoupment Protection
CMS audits and demands funds back (months later):
        ↓
applyRecoupment() triggered
5% reserve absorbs the loss
Remaining reserve returned to agency
Status → "Recoupment Applied"
```

### The Math on a $5,000 Claim

| Component | Calculation | Amount |
|---|---|---|
| Full claim value | — | $5,000.00 |
| Advance to agency (85%) | $5,000 × 85% | $4,250.00 |
| Reserve held in escrow (5%) | $5,000 × 5% | $250.00 |
| Platform fee (1.5% of advance) | $4,250 × 1.5% | $63.75 |
| **Agency net cost** | | **$63.75** |
| **vs. factoring at 3%** | $5,000 × 3% | $150.00 |
| **Agency savings** | | **$86.25 per claim** |

---

## Why Blockchain?

A traditional factoring company bridge is built on trust, legal contracts, manual reconciliation, and phone calls to resolve disputes.

The MediChain Pay bridge is built on code:

- **Self-enforcing** — smart contracts execute automatically when conditions are met
- **Immutable** — no one can alter a transaction after it occurs
- **Transparent** — every transaction is publicly verifiable on Basescan
- **Trustless** — agencies don't need to trust a factoring company — they trust the code
- **Cheap** — Base Network transactions cost fractions of a cent
- **Always on** — no business hours, no holidays, no delays

---

## Why Base Network?

| Feature | Benefit |
|---|---|
| EVM compatible | Standard Solidity development applies directly |
| Sub-cent gas fees | Transaction costs are negligible |
| Backed by Coinbase | Strongest compliance credibility in crypto |
| Native USDC support | Circle deeply integrated — no bridging needed |
| High throughput | Can handle volume as platform scales |

---

## Smart Contract Architecture

### MediChainPay.sol — The Core Contract

The heart of the platform. Contains all business logic and enforces every rule automatically.

**State Variables**
```
owner           — Founder wallet. Only address that can approve advances.
usdc            — Reference to USDC token contract.
advancePercent  — 85% (how much of claim gets advanced)
reservePercent  — 5%  (held as recoupment buffer)
feeBasisPoints  — 150 (1.5% platform fee)
reserveWindowDays — 180 (days before reserve is released)
claimCounter    — Auto-incrementing unique claim ID
```

**Claim Status Lifecycle**
```
Submitted → Advanced → Repaid → ReserveReleased
                ↓
            Clawback (CMS denial before repayment)
                
Submitted → Denied (rejected before funds move)

Repaid → Recoupment (CMS audit after repayment)
```

**Core Functions**

| Function | Access | Description |
|---|---|---|
| `submitClaim(amount)` | Agency | Submit verified claim for review |
| `advanceFunds(claimId)` | Owner | Release 85% USDC to agency instantly |
| `repayAdvance(claimId)` | Owner | Collect principal + fee when CMS remits |
| `clawback(claimId)` | Owner | Recover funds if CMS denies before repayment |
| `getClaimStatus(claimId)` | Public | Query current status of any claim |
| `releaseReserve(claimId, bypass)` | Owner | Return 5% reserve after 180 days |
| `applyRecoupment(claimId, amount)` | Owner | Apply CMS clawback against reserve |
| `denySubmittedClaim(claimId)` | Owner | Reject claim before funds move |
| `withdrawUSDC(amount)` | Owner | Manage liquidity pool |
| `updateFee(basisPoints)` | Owner | Adjust platform fee (max 5%) |
| `updateReserveWindow(days)` | Owner | Adjust reserve window (90–365 days) |
| `getContractBalance()` | Public | Check available USDC liquidity |

### MockUSDC.sol — Test Token

A fake USDC token used only in local development. Implements the full ERC-20 standard including `mint()`, `transfer()`, `transferFrom()`, `approve()`, `allowance()`, and `balanceOf()`.

In production this is replaced by real Circle USDC on Base mainnet:
`0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913`

---

## Recoupment Protection — The Key Innovation

Traditional factoring companies ignore recoupment risk and simply charge higher fees to compensate. MediChain Pay builds recoupment protection directly into the smart contract.

**What is recoupment?**
CMS can audit a claim months or even years after paying it. If they determine the claim was improperly billed or documented, they offset (claw back) the payment from future remittances.

**How MediChain Pay handles it:**

```
Claim repaid ✅
        ↓
5% reserve held in escrow for 180 days
        ↓
Scenario A — No clawback after 180 days:
Reserve released back to agency ✅

Scenario B — CMS claws back less than reserve:
Reserve absorbs the loss ✅
Remaining reserve returned to agency ✅

Scenario C — CMS claws back more than reserve:
Reserve absorbs what it can ✅
Shortfall logged on-chain for collection ✅
```

---

## System Architecture

```
┌─────────────────────────────────────────────────────────┐
│ CLIENT LAYER                                            │
│  Agency Portal (React)  ·  Admin Dashboard  ·  Basescan│
└────────────────────────┬────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────┐
│ MIDDLEWARE LAYER                                        │
│  Availity API  ·  Chainlink Oracle  ·  KYB / BAA       │
└────────────────────────┬────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────┐
│ SMART CONTRACT LAYER                                    │
│  MediChainPay.sol  ·  USDC (ERC-20)  ·  Claim Escrow  │
└────────────────────────┬────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────┐
│ BLOCKCHAIN INFRASTRUCTURE                               │
│  Base Network  ·  Consensus Layer  ·  Distributed Ledger│
└─────────────────────────────────────────────────────────┘
```

---

## Project Roadmap

- [x] **Phase 1** — Market validation with home health agency network
- [x] **Phase 2** — Smart contract development (Solidity on Base)
  - [x] Core claim lifecycle — submit, advance, repay, clawback
  - [x] Reserve escrow system — 5% held per claim
  - [x] Recoupment protection — applyRecoupment() and releaseReserve()
  - [x] Full test suite in Remix IDE
- [ ] **Phase 3** — MVP frontend
  - [ ] React agency portal with MetaMask integration
  - [ ] Admin dashboard for claim review
  - [ ] Deploy to Base Sepolia testnet
- [ ] **Phase 4** — Production hardening
  - [ ] Clearinghouse integration (Availity / Change Healthcare)
  - [ ] Chainlink oracle for automated repayment
  - [ ] HIPAA compliance — BAA agreements
  - [ ] Smart contract audit (Trail of Bits / Sherlock)
  - [ ] KYB onboarding for agencies
- [ ] **Phase 5** — Market expansion
  - [ ] Skilled Nursing Facilities (SNFs)
  - [ ] Durable Medical Equipment (DME) suppliers
  - [ ] Behavioral health providers
  - [ ] Rural Health Clinics (RHCs)

---

## Getting Started

### Prerequisites
- [MetaMask](https://metamask.io) browser extension
- [Remix IDE](https://remix.ethereum.org) or local Foundry setup
- Base Sepolia testnet ETH ([faucet](https://docs.base.org/docs/tools/network-faucets/))

### Local Development in Remix IDE

**Step 1 — Deploy MockUSDC**
```
1. Open MockUSDC.sol in Remix
2. Compile with Solidity ^0.8.20
3. Deploy — no constructor arguments needed
4. Copy the MockUSDC contract address
```

**Step 2 — Deploy MediChainPay**
```
1. Open MediChainPay.sol in Remix
2. Compile with Solidity ^0.8.20
3. Paste MockUSDC address as constructor argument
4. Deploy
```

**Step 3 — Fund the Contract**
```
1. Go to MockUSDC → mint()
2. _to: MediChainPay contract address
3. _amount: 10000000000 (= $10,000 USDC)
4. Transact
```

**Step 4 — Test the Full Lifecycle**
```
submitClaim(5000000000)         — Submit $5,000 claim
advanceFunds(1)                 — Advance $4,250 to agency
approve(mediChainPay, 4313750000) — Agency authorizes repayment
repayAdvance(1)                 — Collect $4,313.75
releaseReserve(1, true)         — Release $250 reserve (bypass=true for testing)
```

### USDC Amount Reference

| Dollar Amount | Contract Value |
|---|---|
| $100.00 | `100000000` |
| $1,000.00 | `1000000000` |
| $5,000.00 | `5000000000` |
| $10,000.00 | `10000000000` |

> USDC uses 6 decimal places. Multiply any dollar amount by 1,000,000.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Smart Contract | Solidity ^0.8.20 |
| Blockchain | Base Network (Coinbase L2) |
| Stablecoin | USDC (Circle ERC-20) |
| Oracle | Chainlink (Phase 4) |
| Frontend | React + ethers.js (Phase 3) |
| Wallet | MetaMask |
| Dev Environment | Remix IDE |
| Block Explorer | Basescan |

---

## About The Builder

This project is built by a **home health agency owner with 5+ years of firsthand experience** navigating Medicare and Medicaid payment cycles. The cash flow problem MediChain Pay solves is not theoretical — it was lived daily before becoming the foundation of this platform.

The combination of deep healthcare domain expertise and blockchain technical development is the core differentiator of this project.

---

## License

MIT — see [LICENSE](LICENSE) for details.

---

*MediChain Pay — Confidential Project in Active Development*
*Built on firsthand healthcare payment experience*
*github.com/darnharris37/medichain-pay*
