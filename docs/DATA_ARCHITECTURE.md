Data architecture · MDCopyData Architecture — MediChain Pay

Written by a former Microsoft Data Solutions Architect.
This document maps enterprise data architecture patterns
to blockchain infrastructure — showing how MediChain Pay
applies proven enterprise integration design to
decentralized payment systems.


The Architect's Perspective
Most blockchain projects are built by developers who learned
smart contracts first and business logic second.
MediChain Pay is built the other way around.
The founder spent years designing enterprise data architectures
at Microsoft — event-driven pipelines, API integrations,
immutable audit logs, and real-time data processing — before
writing a single line of Solidity.
The result is a blockchain platform designed with the rigor
of enterprise software, not the improvisation of a side project.

Enterprise Patterns → Blockchain Equivalents
Every architectural decision in MediChain Pay maps directly
to a proven enterprise pattern. The infrastructure is different.
The design is the same.
Enterprise PatternMicrosoft ToolMediChain Pay EquivalentEvent streamingAzure Event HubSmart contract eventsAPI integrationAzure Logic AppsChainlink FunctionsETL pipelineAzure Data FactoryERA/835 → Oracle feedWorkflow automationPower AutomateChainlink AutomationAPI managementAzure API ManagementChainlink → AvailityImmutable audit logAppend-only storageBlockchain ledgerDatabase rowSQL Server / Cosmos DBClaim struct (on-chain)Primary key indexClustered indexMapping (claimId → Claim)Status columnConstrained enumClaimStatus enumChange data captureAzure CDCBlockchain eventsTransaction timestampDATETIME columnblock.timestampService Bus triggerAzure Service BusOn-chain event triggerRetry logicLogic App retry policyChainlink oracle retryData validationData Factory validationrequire() statementsAccess controlAzure RBAConlyOwner modifierMonitoringAzure MonitorBasescan event logs

The Data Model
On-Chain Schema Design
The MediChain Pay on-chain data model was designed with the
same principles used in enterprise database architecture —
normalized, indexed, and constrained.
CLAIM (Primary Entity)
─────────────────────────────────────────────────
id                  UINT256     Primary key (auto-increment)
agency              ADDRESS     Foreign key → agency wallet
claimAmount         UINT256     Full claim value (6 decimals)
advanceAmount       UINT256     85% of claimAmount
reserveAmount       UINT256     5% of claimAmount
feeAmount           UINT256     1.5% of advanceAmount
status              ENUM        Constrained status field
submittedAt         UINT256     Unix timestamp
advancedAt          UINT256     Unix timestamp
reserveReleasedAt   UINT256     Unix timestamp (0 = not released)

AGENCY_CLAIMS (Index Table)
─────────────────────────────────────────────────
agency              ADDRESS     Indexed lookup key
claimIds            UINT256[]   Array of claim IDs
Why This Maps to Enterprise Design
Primary Key Pattern
SQL Server:
CREATE TABLE Claims (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    ...
)

Solidity equivalent:
claimCounter++;
uint256 newClaimId = claimCounter;
claims[newClaimId] = Claim({...});
Index Pattern
SQL Server:
CREATE INDEX IX_Claims_Agency ON Claims(AgencyId);

Solidity equivalent:
mapping(address => uint256[]) public agencyClaims;
Constrained Status Column
SQL Server:
CREATE TYPE ClaimStatus AS ENUM (
    'Submitted', 'Advanced', 'Repaid',
    'Denied', 'Clawback', 'ReserveReleased', 'Recoupment'
);

Solidity equivalent:
enum ClaimStatus {
    Submitted, Advanced, Repaid,
    Denied, Clawback, ReserveReleased, Recoupment
}

Event-Driven Architecture
The Event Pipeline
MediChain Pay is built on an event-driven architecture —
every state change emits a permanent event to the blockchain.
CLAIM SUBMITTED
─────────────────────────────────────────────────
Source:     Agency wallet
Trigger:    submitClaim() called
Event:      ClaimSubmitted(claimId, agency, claimAmount)
Consumers:  Admin dashboard, audit trail, analytics

FUNDS ADVANCED
─────────────────────────────────────────────────
Source:     Owner wallet
Trigger:    advanceFunds() called
Event:      FundsAdvanced(claimId, agency, advance, reserve)
Consumers:  Agency portal, liquidity monitor, audit trail

ADVANCE REPAID
─────────────────────────────────────────────────
Source:     Chainlink oracle (Phase 4) / Owner (Phase 3)
Trigger:    CMS remittance detected
Event:      AdvanceRepaid(claimId, totalRepaid)
Consumers:  Revenue dashboard, agency portal, audit trail

RESERVE RELEASED
─────────────────────────────────────────────────
Source:     Chainlink Automation (Phase 4) / Owner (Phase 3)
Trigger:    180-day window elapsed
Event:      ReserveReleased(claimId, agency, reserveAmount)
Consumers:  Agency portal, audit trail

RECOUPMENT APPLIED
─────────────────────────────────────────────────
Source:     Owner wallet
Trigger:    CMS audit clawback detected
Event:      RecoupmentApplied(claimId, amount, reserveUsed)
Consumers:  Risk dashboard, audit trail, compliance reporting
Event Schema Design
Events in Solidity are designed with the same principles
as Azure Event Hub event schemas — indexed fields for
searchability, minimal payload for efficiency.
solidity// Indexed fields = searchable (like Event Hub partition key)
// Non-indexed fields = payload data
event ClaimSubmitted(
    uint256 indexed claimId,   // Searchable — filter by claim
    address indexed agency,    // Searchable — filter by agency
    uint256 claimAmount        // Payload — not searchable
);
Comparing to Azure Event Hub
Azure Event Hub:
Producer → Event Hub → Consumer Group → Processing

MediChain Pay:
Smart Contract → Blockchain Event → Frontend Subscriber → UI Update

The pattern is identical. The infrastructure is different.

API Integration Layer (Phase 4)
Chainlink Functions — The API Gateway
Chainlink Functions is the blockchain equivalent of
Azure API Management combined with Azure Logic Apps.
It allows smart contracts to make authenticated HTTP
requests to external APIs — exactly like Logic App
connectors calling REST APIs.
Enterprise Pattern (Azure):
Logic App → API Management → Availity REST API
        ↓
Response processed
        ↓
Azure Service Bus message triggered
        ↓
Downstream processing begins

MediChain Pay Pattern (Chainlink):
Chainlink Functions → Availity REST API
        ↓
Response processed
        ↓
On-chain transaction triggered
        ↓
Smart contract state updated
The Availity Integration Design
javascript// Chainlink Functions — Availity claim validation
// This is the same API call you'd write in a Logic App

const claimId = args[0];
const apiKey = secrets.availityKey;

const response = await Functions.makeHttpRequest({
    url: `https://api.availity.com/availity/v1/claims/${claimId}`,
    method: "GET",
    headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json"
    }
});

// Parse response — same as Data Factory mapping
const claimStatus = response.data.status;
const claimAmount = response.data.amount;
const payerId = response.data.payerId;

// Return structured data to smart contract
return Functions.encodeString(JSON.stringify({
    status: claimStatus,
    amount: claimAmount,
    payerId: payerId
}));

ETL Pipeline — ERA/835 Processing (Phase 4)
The Remittance Data Pipeline
The ERA (Electronic Remittance Advice) / 835 file is the
structured remittance data CMS sends when paying claims.
Processing it is a classic ETL problem.
EXTRACT
─────────────────────────────────────────────────
Source:         CMS / Medicaid MCO
Format:         ANSI X12 835 transaction set
Transport:      SFTP / clearinghouse API
Frequency:      Daily batch + real-time

TRANSFORM
─────────────────────────────────────────────────
Parse 835 segments:
  BPR — Financial information (payment amount)
  TRN — Trace number (check/EFT number)
  CLP — Claim payment information
  SVC — Service payment information

Extract per claim:
  Claim ID          → matches on-chain claimId
  Payment amount    → validates against claimAmount
  Payer ID          → validates against expected payer
  Payment date      → triggers repayAdvance()
  Adjustment codes  → triggers applyRecoupment() if needed

LOAD
─────────────────────────────────────────────────
Target:         Blockchain (via Chainlink oracle)
Method:         Chainlink Functions HTTP request
Trigger:        repayAdvance() or applyRecoupment()
Frequency:      Real-time per remittance event
Mapping to Azure Data Factory
Azure Data Factory Pipeline:
Source Dataset (835 file)
    → Mapping Data Flow
        → Derived Column (parse 835 segments)
        → Filter (match claim IDs)
        → Sink Dataset (trigger downstream API)

MediChain Pay Pipeline:
ERA/835 file
    → Chainlink Functions
        → Parse 835 segments
        → Match claim IDs to on-chain claims
        → Call repayAdvance() or applyRecoupment()

Automation Layer (Phase 4)
Chainlink Automation — The Workflow Engine
Chainlink Automation is the blockchain equivalent of
Azure Logic App scheduled triggers or Power Automate flows.
It monitors conditions and automatically executes
functions when those conditions are met.
Use Case 1 — Automated Repayment:
Condition:  CMS remittance detected for Claim #X
Action:     repayAdvance(X) called automatically

Use Case 2 — Reserve Release:
Condition:  block.timestamp >= claim.advancedAt + 180 days
Action:     releaseReserve(X) called automatically

Use Case 3 — Recoupment Monitoring:
Condition:  ERA/835 contains adjustment code CO-4 (denial)
Action:     applyRecoupment(X, amount) called automatically
Comparing to Power Automate
Power Automate Flow:
Trigger: "When a new file arrives in SharePoint"
Action:  "Parse JSON" → "Call REST API" → "Update database"

Chainlink Automation:
Trigger: "When block.timestamp >= advancedAt + 15552000"
Action:  "Call releaseReserve()" → "Transfer USDC" → "Emit event"

Same pattern. Different runtime.

Immutable Audit Trail
Why Blockchain Beats Traditional Audit Logging
Enterprise audit logs can be altered by a DBA.
Blockchain audit logs cannot be altered by anyone.
Traditional Audit Log (SQL Server):
UPDATE AuditLog SET Amount = 4500 WHERE ClaimId = 1;
-- This is possible. A DBA can do this.
-- Regulators have to trust you didn't.

Blockchain Audit Log:
-- This is impossible. The chain is immutable.
-- Regulators can verify independently.
-- No trust required.
The Audit Trail Design
Every MediChain Pay transaction is permanently logged:
Block 32:  ClaimSubmitted(1, 0x5B38..., 5000000000)
Block 33:  FundsAdvanced(1, 0x5B38..., 4250000000, 250000000)
Block 36:  AdvanceRepaid(1, 4313750000)
Block 47:  ReserveReleased(1, 0x5B38..., 250000000)
Anyone — regulator, auditor, agency, CMS — can query
this data independently without asking MediChain Pay
for access. It's public infrastructure.
Querying Events — Like Azure Log Analytics
javascript// Query blockchain events — like a KQL query in Log Analytics

const filter = contract.filters.ClaimSubmitted(null, agencyAddress);
const events = await contract.queryFilter(filter, fromBlock, toBlock);

// Returns all ClaimSubmitted events for a specific agency
// Like: AuditLog | where AgencyId == "0x5B38..." | order by Timestamp

Access Control Architecture
Role-Based Access Control
MediChain Pay implements RBAC at the smart contract level —
equivalent to Azure Active Directory role assignments.
Current Implementation (MVP):
────────────────────────────────────────
Owner Role      → Full admin access
                  advanceFunds(), repayAdvance(),
                  clawback(), releaseReserve(),
                  applyRecoupment(), withdrawUSDC()

Agency Role     → Submit only
                  submitClaim()

Public Role     → Read only
                  getClaimStatus(), getContractBalance()

Phase 4 Implementation:
────────────────────────────────────────
Owner Role      → Platform administration
Reviewer Role   → Claim approval only
Oracle Role     → Automated function calls (Chainlink)
Agency Role     → Submit and view own claims
Auditor Role    → Read-only access to all data
Comparing to Azure RBAC
Azure RBAC:
Contributor → Read + Write
Reader      → Read only
Owner       → Full control

MediChain Pay (Phase 4):
onlyOwner    → Full control
onlyReviewer → Claim approval only
onlyOracle   → Automated triggers only
public       → Read only

Liquidity Pool Architecture
The Capital Management Problem
MediChain Pay operates a liquidity pool — USDC held
in the smart contract used to fund advances.
This is a classic capital allocation problem that maps
directly to treasury management systems.
LIQUIDITY POOL DESIGN
─────────────────────────────────────────────────
Total Pool:         USDC in contract
Committed Capital:  Sum of all active reserve amounts
Available Capital:  Total Pool - Committed Capital
Advance Capacity:   Available Capital / advancePercent

Example:
Total Pool:         $100,000
Committed Reserves: $12,500  (50 x $250 reserves)
Available Capital:  $87,500
Advance Capacity:   ~$102,941 in new advances
Phase 4 — Institutional Liquidity
Phase 4 capital sources:
→ Founder capital (current)
→ Institutional liquidity pool (DeFi)
→ Secondary market for claim advances
→ Investor capital via tokenized pool shares

Technology Roadmap — Data Architecture View
PHASE 3 — MVP (Current)
─────────────────────────────────────────────────
✅ On-chain data model (Claim struct)
✅ Event-driven architecture (7 events)
✅ RBAC — onlyOwner pattern
✅ Immutable audit trail
✅ Manual API integration (owner triggers)
⬜ React frontend event subscribers
⬜ Base Sepolia deployment

PHASE 4 — Automation
─────────────────────────────────────────────────
⬜ Chainlink Functions → Availity API
⬜ ERA/835 ETL pipeline → Chainlink oracle
⬜ Chainlink Automation → repayAdvance()
⬜ Chainlink Automation → releaseReserve()
⬜ Advanced RBAC (Reviewer, Oracle roles)
⬜ Liquidity pool monitoring dashboard

PHASE 5 — Scale
─────────────────────────────────────────────────
⬜ Multi-payer data feeds (Medicare + Medicaid MCOs)
⬜ Institutional liquidity integration
⬜ Secondary market for claim advances
⬜ Cross-chain expansion
⬜ Predictive claim risk scoring (ML pipeline)

The Architect's Advantage
Most blockchain developers learn decentralized systems
first and enterprise patterns second — if at all.
This platform is built by someone who spent years at
Microsoft designing the exact integration patterns that
blockchain infrastructure is now replicating:

Event-driven pipelines → Smart contract events
API integration layers → Chainlink Functions
ETL processing → Oracle data feeds
Workflow automation → Chainlink Automation
Immutable audit logs → Blockchain ledger
RBAC → Smart contract modifiers

The result is a healthcare payment platform that combines
the rigor of enterprise data architecture with the
transparency and automation of blockchain infrastructure.

MediChain Pay — Data Architecture Documentation
Built on enterprise integration patterns from Microsoft
github.com/darnharris37/medichain-pay
