# MediChain Pay

> **The bridge between home health agencies and CMS.**
> Blockchain-powered payment acceleration for Medicare & Medicaid providers.

[![Solidity](https://img.shields.io/badge/Solidity-0.8.20-363636?logo=solidity)](https://soliditylang.org)
[![Base Network](https://img.shields.io/badge/Base-Network-0052FF?logo=coinbase)](https://base.org)
[![USDC](https://img.shields.io/badge/USDC-Circle-2775CA)](https://www.circle.com)
[![Auth0](https://img.shields.io/badge/Auth0-Healthcare_CIAM-EB5424?logo=auth0)](https://auth0.com/healthcare)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Live Architecture Diagram:** [darnharris37.github.io/medichain-pay](https://darnharris37.github.io/medichain-pay)

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
| **HIPAA Compliance** | Varies | Auth0 Healthcare CIAM |

---

## How It Works

### The Claim Lifecycle

| Step | Who | What Happens |
|---|---|---|
| 1 | Agency | Logs in via Auth0 — MFA verified |
| 2 | Auth0 | Role assigned — HIPAA compliant session started |
| 3 | Agency | Submits verified clean claim via portal |
| 4 | Clearinghouse | Availity API validates claim eligibility |
| 5 | Owner | Reviews and approves advance |
| 6 | Smart Contract | 85% of claim value sent in USDC within minutes |
| 7 | Smart Contract | 5% reserve held in escrow for 180 days |
| 8 | CMS | Remits payment to agency (14–90 days later) |
| 9 | Platform | Collects principal + 1.5% fee |
| 10 | Smart Contract | Reserve released to agency after 180-day window |

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

## System Architecture

**5 layers — view the interactive diagram at [darnharris37.github.io/medichain-pay](https://darnharris37.github.io/medichain-pay)**

| Layer | Components |
|---|---|
| Client Layer | Agency Portal (React) · MetaMask · Admin Dashboard |
| Identity Layer | Auth0 Universal Login · MFA · Role Management · HIPAA BAA |
| Middleware Layer | Availity API · KYB / BAA · Chainlink Oracle · CMS |
| Smart Contract | MediChainPay.sol · USDC (ERC-20) · Claim Escrow · On-Chain Audit |
| Blockchain Infra | Base Network · Consensus Layer · Distributed Ledger · Basescan |

---

## Identity & Compliance — Auth0 Healthcare CIAM

Auth0 by Okta provides the HIPAA-compliant identity layer for MediChain Pay — sitting between users and the platform to enforce authentication, authorization, and compliance before any blockchain transaction occurs.

| Auth0 Feature | MediChain Pay Benefit |
|---|---|
| Universal Login | Branded login page for all agency users |
| Multi-Factor Auth | TOTP, SMS, email — required for HIPAA |
| Single Sign-On | Connect to Epic, Cerner, Homecare Homebase |
| Role Management | Agency Admin, Staff, Auditor, Owner |
| HIPAA BAA | Business Associate Agreement available |
| Fine-Grained Authorization | Granular access control per user |
| AI Agent Auth | Secure Chainlink oracle identity (Phase 4) |
| Actions Engine | Custom KYB verification at login |

---

## Why Blockchain?

| Traditional Factoring | MediChain Pay |
|---|---|
| Enforced by lawyers and trust | Enforced by code — self-executing |
| Opaque transactions | Every transaction publicly verifiable |
| Manual reconciliation | Automatic on-chain settlement |
| Business hours only | 24/7/365 — no downtime |
| Centralized — single point of failure | Distributed — no single point of failure |

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

### MediChainPay.sol — v2.0

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

**Claim Status Lifecycle**

| Path | Statuses |
|---|---|
| Normal | Submitted → Advanced → Repaid → ReserveReleased |
| Pre-advance denial | Submitted → Denied |
| Post-advance denial | Submitted → Advanced → Clawback |
| CMS audit | Submitted → Advanced → Repaid → Recoupment |

### MockUSDC.sol — Test Token

Used only in local development. Implements the full ERC-20 standard. Replaced by real Circle USDC on Base mainnet: `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913`

---

## Recoupment Protection

Traditional factoring companies ignore recoupment risk and simply charge higher fees. MediChain Pay builds recoupment protection directly into the smart contract.

| Scenario | What Happens |
|---|---|
| No clawback after 180 days | Full reserve returned to agency |
| CMS claws back less than reserve | Reserve absorbs loss, remainder returned to agency |
| CMS claws back more than reserve | Reserve absorbs what it can, shortfall logged for Phase 4 |

---

## Data Architecture

This platform was built by a former Microsoft Data Solutions Architect. Every design decision maps to a proven enterprise pattern.

| Enterprise Pattern | Microsoft Tool | MediChain Pay |
|---|---|---|
| Customer identity | Azure AD B2C | Auth0 Healthcare CIAM |
| Event streaming | Azure Event Hub | Smart contract events |
| API integration | Azure Logic Apps | Chainlink Functions |
| ETL pipeline | Azure Data Factory | ERA/835 → Oracle feed |
| Workflow automation | Power Automate | Chainlink Automation |
| Immutable audit log | Append-only storage | Blockchain ledger |
| Access control | Azure RBAC | onlyOwner + Auth0 roles |

Full data architecture documentation: [docs/DATA_ARCHITECTURE.md](docs/DATA_ARCHITECTURE.md)

---

## Project Roadmap

- [x] **Phase 1** — Market validation with home health agency network
- [x] **Phase 2** — Smart contract development (Solidity on Base)
  - [x] Core claim lifecycle — submit, advance, repay, clawback
  - [x] Reserve escrow system — 5% held per claim
  - [x] Recoupment protection — applyRecoupment() and releaseReserve()
  - [x] Full test suite in Remix IDE
  - [x] Enterprise data architecture documentation
- [ ] **Phase 3** — MVP frontend
  - [x] Auth0 Healthcare CIAM — identity layer
  - [ ] React agency portal with MetaMask integration
  - [ ] Admin dashboard for claim review
  - [ ] Deploy to Base Sepolia testnet
- [ ] **Phase 4** — Production hardening
  - [ ] Clearinghouse integration (Availity / Change Healthcare)
  - [ ] Chainlink oracle for automated repayment
  - [ ] Auth0 SSO — Epic, Cerner, Homecare Homebase
  - [ ] Auth0 AI Agent Authentication for Chainlink
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
- [Remix IDE](https://remix.ethereum.org)
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
submitClaim(5000000000)              Submit $5,000 claim
advanceFunds(1)                      Advance $4,250 to agency
approve(mediChainPay, 4313750000)    Agency authorizes repayment
repayAdvance(1)                      Collect $4,313.75
releaseReserve(1, true)              Release $250 reserve (bypass=true for testing)
applyRecoupment(1, 150000000)        Apply $150 CMS clawback against reserve
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
| Identity & HIPAA | Auth0 Healthcare CIAM (Okta) |
| Smart Contract | Solidity ^0.8.20 |
| Blockchain | Base Network (Coinbase L2) |
| Stablecoin | USDC (Circle ERC-20) |
| Oracle | Chainlink (Phase 4) |
| Frontend | React + ethers.js (Phase 3) |
| Wallet | MetaMask |
| Dev Environment | Remix IDE |
| Block Explorer | Basescan |

---

## Documentation

| Document | Description |
|---|---|
| [README.md](README.md) | This file — full product overview |
| [docs/DATA_ARCHITECTURE.md](docs/DATA_ARCHITECTURE.md) | Enterprise data architecture mapped to blockchain |
| [docs/MediChainArchitecture.jsx](docs/MediChainArchitecture.jsx) | Interactive architecture diagram (React) |
| [index.html](index.html) | Live architecture diagram — GitHub Pages |

---

## About The Builder

This project is built by a **home health agency owner and former Microsoft Data Solutions Architect** with 5+ years of firsthand experience navigating Medicare and Medicaid payment cycles.

The cash flow problem MediChain Pay solves is not theoretical — it was lived daily before becoming the foundation of this platform. The enterprise data architecture patterns applied here come from years of building production-grade data pipelines, API integrations, and event-driven systems at Microsoft.

The combination of deep healthcare domain expertise, enterprise architecture experience, and blockchain development is the core differentiator of this project.

---

## License

MIT — see [LICENSE](LICENSE) for details.

---

**Live Architecture:** [darnharris37.github.io/medichain-pay](https://darnharris37.github.io/medichain-pay)

**GitHub:** [github.com/darnharris37/medichain-pay](https://github.com/darnharris37/medichain-pay)

*MediChain Pay — Confidential Project in Active Development*
*Built on firsthand healthcare payment experience and enterprise data architecture*
