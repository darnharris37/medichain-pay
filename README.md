MediChain Pay

Blockchain-powered payment acceleration for Medicare & Medicaid providers — built by a home health agency owner who lived the problem firsthand.


The Problem
Home health agencies and other Medicare/Medicaid providers face a structural cash flow crisis:

Medicare pays in 14–30 days on clean claims. Medicaid managed care stretches to 60–90 days
Traditional medical factoring costs 3–6% per claim — a significant hit for thin-margin businesses
The RAP (Request for Anticipated Payment) program was eliminated in 2022, removing the only early payment mechanism
Agencies routinely take on lines of credit just to cover payroll while waiting on reimbursement
Over $100 billion is lost annually across the healthcare system to payment delays and inefficiency

The Solution
MediChain Pay is a smart contract-based payment acceleration platform that:

Accepts verified clean claim submissions from agencies
Automatically advances 90% of the claim value in USDC within minutes
Holds funds in escrow and collects repayment + a small fee when CMS remits
Creates an immutable on-chain audit trail for compliance and fraud prevention
Operates cheaper and faster than any traditional factoring company

How It Works
Agency submits claim
        ↓
MediChain Pay reviews & approves
        ↓
90% of claim value sent in USDC (minutes, not weeks)
        ↓
CMS remits payment to agency
        ↓
Platform collects principal + fee automatically
Tech Stack
LayerTechnologySmart ContractSolidity ^0.8.20BlockchainBase Network (EVM compatible)StablecoinUSDC (Circle)Dev EnvironmentRemix IDEWalletMetaMaskBlock ExplorerBasescan
Smart Contract Functions
FunctionAccessDescriptionsubmitClaim()AgencySubmit a verified claim for reviewadvanceFunds()OwnerRelease 90% of claim value in USDC to agencyrepayAdvance()OwnerCollect principal + fee when CMS remitsclawback()OwnerRecover funds if CMS denies a claimgetClaimStatus()PublicQuery the current status of any claimdenySubmittedClaim()OwnerReject a claim before funds are advancedwithdrawUSDC()OwnerManage contract liquidity poolupdateFee()OwnerAdjust platform fee (capped at 5%)
Claim Lifecycle
Submitted → Advanced → Repaid
                ↓
            Clawback (if CMS denies)
Project Roadmap

 Phase 1 — Market validation with home health agency network
 Phase 2 — Smart contract development (Solidity on Base)
 Phase 3 — MVP frontend (React + MetaMask integration)
 Phase 4 — Clearinghouse integration (Availity / Change Healthcare), Chainlink oracle, HIPAA compliance
 Phase 5 — Expand to SNFs, DME suppliers, behavioral health providers

Why Base Network

EVM compatible — standard Solidity development applies directly
Extremely low fees — fractions of a cent per transaction
Backed by Coinbase — strongest compliance credibility in crypto
USDC native — Circle deeply integrated with Base

About the Builder
This project is built by a home health agency owner with 5+ years of firsthand experience navigating Medicare and Medicaid payment cycles. The cash flow problem MediChain Pay solves is not theoretical — it was lived daily before becoming the foundation of this platform.

Getting Started (Local Development)
Prerequisites

MetaMask browser extension
Remix IDE or local Foundry/Hardhat setup
Base Sepolia testnet ETH (faucet)

Deploy to Base Sepolia Testnet

Clone the repo

bashgit clone https://github.com/darnharris37/medichain-pay.git

Open src/MediChainPay.sol in Remix IDE
Compile with Solidity ^0.8.20
In Remix, select "Injected Provider - MetaMask" as the environment
Connect MetaMask to Base Sepolia testnet
Deploy with the Base Sepolia USDC test address as the constructor argument


License
MIT

Built on firsthand healthcare payment experience. MediChain Pay — confidential project in active development.
