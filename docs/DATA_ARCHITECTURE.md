# Data Architecture — MediChain Pay

> Written by a former Microsoft Data Solutions Architect.
> This document maps enterprise data architecture patterns to blockchain infrastructure — showing how MediChain Pay applies proven enterprise integration design to decentralized payment systems.

---

## The Architect's Perspective

Most blockchain projects are built by developers who learned smart contracts first and business logic second.

MediChain Pay is built the other way around.

The founder spent years designing enterprise data architectures at Microsoft — event-driven pipelines, API integrations, immutable audit logs, and real-time data processing — before writing a single line of Solidity.

The result is a blockchain platform designed with the rigor of enterprise software, not the improvisation of a side project.

---

## Enterprise Patterns Mapped to Blockchain

Every architectural decision in MediChain Pay maps directly to a proven enterprise pattern. The infrastructure is different. The design is the same.

| Enterprise Pattern | Microsoft Tool | MediChain Pay Equivalent |
|---|---|---|
| Customer identity | Azure Active Directory B2C | Auth0 Healthcare CIAM |
| Event streaming | Azure Event Hub | Smart contract events |
| API integration | Azure Logic Apps | Chainlink Functions |
| ETL pipeline | Azure Data Factory | ERA/835 → Oracle feed |
| Workflow automation | Power Automate | Chainlink Automation |
| API management | Azure API Management | Chainlink → Availity |
| Immutable audit log | Append-only storage | Blockchain ledger |
| Database row | SQL Server / Cosmos DB | Claim struct (on-chain) |
| Primary key index | Clustered index | Mapping (claimId → Claim) |
| Status column | Constrained enum | ClaimStatus enum |
| Change data capture | Azure CDC | Blockchain events |
| Transaction timestamp | DATETIME column | block.timestamp |
| Service Bus trigger | Azure Service Bus | On-chain event trigger |
| Retry logic | Logic App retry policy | Chainlink oracle retry |
| Data validation | Data Factory validation | require() statements |
| Access control | Azure RBAC | onlyOwner modifier + Auth0 roles |
| Monitoring | Azure Monitor | Basescan event logs |

---

## System Architecture — 5 Layers

MediChain Pay is organized into 5 distinct architectural layers. Each layer has a clear responsibility and maps to enterprise architecture principles.

| Layer | Responsibility |
|---|---|
| Client Layer | What users see and interact with |
| Identity Layer | Who is allowed in and what they can do (Auth0) |
| Middleware Layer | How external systems connect |
| Smart Contract | Where business logic and money live |
| Blockchain Infra | The foundation everything runs on |

---

## Identity Layer — Auth0 Healthcare CIAM

> New in v1.1 — Auth0 has been added as a dedicated Identity Layer between the Client and Middleware layers.

### What is CIAM?

Customer Identity and Access Management (CIAM) is the enterprise pattern for managing who can access your application and what they can do once inside.

In Microsoft terms this is Azure Active Directory B2C. In MediChain Pay this is Auth0 by Okta — purpose-built for healthcare.

### Why Auth0 for Healthcare

| Requirement | Auth0 Feature |
|---|---|
| HIPAA compliance | Business Associate Agreement (BAA) available |
| Secure login | Universal Login with branding |
| MFA enforcement | TOTP, SMS, email authenticators |
| SSO with EHR systems | Connect to Epic, Cerner, Homecare Homebase |
| Role-based access | Fine-Grained Authorization |
| Audit trail | Full login and access event logging |
| Bot protection | Bot detection and attack protection |
| Session security | Configurable session timeouts |
| AI agent auth | Secure automated agent identity (Phase 4) |

### Auth0 Role Design

| Auth0 Role | Portal Access | Smart Contract Access |
|---|---|---|
| Platform Owner | Full admin dashboard | All onlyOwner functions |
| Agency Admin | Full agency portal | submitClaim() |
| Agency Staff | Limited portal view | submitClaim() |
| Auditor | Read-only dashboard | getClaimStatus() |
| Reviewer | Claim review only | denySubmittedClaim() |

### Auth0 vs Azure AD B2C

| Feature | Azure AD B2C | Auth0 Healthcare |
|---|---|---|
| Healthcare focus | General purpose | Purpose-built for healthcare |
| HIPAA BAA | Available | Available |
| SSO providers | Microsoft ecosystem | Epic, Cerner, any SAML/OIDC |
| Setup complexity | High | Low — developer friendly |
| Free tier | Limited | 7,500 monthly active users |
| SMART on FHIR | Manual setup | Built-in support |
| AI agent auth | Not available | Available (2026) |

### The Updated Authentication Flow

Agency staff visits MediChain Pay portal, Auth0 Universal Login loads, user enters credentials, Auth0 enforces MFA, Auth0 assigns role, JWT token issued, portal loads with role-appropriate views, MetaMask connects for blockchain transactions, smart contract executes with onlyOwner enforced on-chain.

### SSO Integration — Removing Adoption Friction

| Agency Software | SSO Protocol | Auth0 Support |
|---|---|---|
| Epic | SAML / OIDC | Supported |
| Cerner | SAML / OIDC | Supported |
| Homecare Homebase | SAML | Supported |
| MatrixCare | SAML | Supported |
| PointClickCare | SAML / OIDC | Supported |

### Auth0 Actions Engine — Custom KYB Logic

Auth0's Actions engine lets you run custom JavaScript at login — before the user gets in. For MediChain Pay this means you can enforce KYB verification as a login gate:

```javascript
// Auth0 Action — runs at every login
// Blocks access if agency KYB is not verified

exports.onExecutePostLogin = async (event, api) => {
  const kybStatus = event.user.app_metadata?.kybStatus;
  if (kybStatus !== "verified") {
    api.access.deny("Agency KYB verification required before accessing MediChain Pay.");
  }
};
```

### AI Agent Authentication — Phase 4

Auth0's 2026 AI agent authentication secures automated system-to-system calls. In Phase 4 when Chainlink oracles call smart contract functions automatically, Auth0 can authenticate those agent calls at the identity layer — adding a security layer that pure blockchain developers almost never think about.

---

## The On-Chain Data Model

### Claim Entity

| Field | Type | Description |
|---|---|---|
| `id` | UINT256 | Primary key — auto-increment |
| `agency` | ADDRESS | Foreign key → agency wallet |
| `claimAmount` | UINT256 | Full claim value (6 decimals) |
| `advanceAmount` | UINT256 | 85% of claimAmount |
| `reserveAmount` | UINT256 | 5% of claimAmount |
| `feeAmount` | UINT256 | 1.5% of advanceAmount |
| `status` | ENUM | Constrained status field |
| `submittedAt` | UINT256 | Unix timestamp |
| `advancedAt` | UINT256 | Unix timestamp |
| `reserveReleasedAt` | UINT256 | Unix timestamp — 0 means not yet released |

### Agency Claims Index

| Field | Type | Description |
|---|---|---|
| `agency` | ADDRESS | Indexed lookup key |
| `claimIds` | UINT256[] | Array of all claim IDs for this agency |

### Primary Key Pattern

```sql
-- SQL Server
CREATE TABLE Claims (
    Id INT IDENTITY(1,1) PRIMARY KEY
)
```

```solidity
// Solidity equivalent
claimCounter++;
uint256 newClaimId = claimCounter;
claims[newClaimId] = Claim({...});
```

### Index Pattern

```sql
-- SQL Server
CREATE INDEX IX_Claims_Agency ON Claims(AgencyId);
```

```solidity
// Solidity equivalent
mapping(address => uint256[]) public agencyClaims;
```

### Constrained Status Column

```sql
-- SQL Server
CREATE TYPE ClaimStatus AS ENUM (
    'Submitted', 'Advanced', 'Repaid',
    'Denied', 'Clawback', 'ReserveReleased', 'Recoupment'
);
```

```solidity
// Solidity equivalent
enum ClaimStatus {
    Submitted, Advanced, Repaid,
    Denied, Clawback, ReserveReleased, Recoupment
}
```

---

## Event-Driven Architecture

MediChain Pay is built on an event-driven architecture — every state change emits a permanent event to the blockchain.

### The Event Pipeline

**ClaimSubmitted**

| Property | Value |
|---|---|
| Source | Agency wallet (after Auth0 authentication) |
| Trigger | submitClaim() called |
| Event | ClaimSubmitted(claimId, agency, claimAmount) |
| Consumers | Admin dashboard, audit trail, analytics |

**FundsAdvanced**

| Property | Value |
|---|---|
| Source | Owner wallet |
| Trigger | advanceFunds() called |
| Event | FundsAdvanced(claimId, agency, advance, reserve) |
| Consumers | Agency portal, liquidity monitor, audit trail |

**AdvanceRepaid**

| Property | Value |
|---|---|
| Source | Chainlink oracle (Phase 4) / Owner (Phase 3) |
| Trigger | CMS remittance detected |
| Event | AdvanceRepaid(claimId, totalRepaid) |
| Consumers | Revenue dashboard, agency portal, audit trail |

**ReserveReleased**

| Property | Value |
|---|---|
| Source | Chainlink Automation (Phase 4) / Owner (Phase 3) |
| Trigger | 180-day window elapsed |
| Event | ReserveReleased(claimId, agency, reserveAmount) |
| Consumers | Agency portal, audit trail |

**RecoupmentApplied**

| Property | Value |
|---|---|
| Source | Owner wallet |
| Trigger | CMS audit clawback detected |
| Event | RecoupmentApplied(claimId, amount, reserveUsed) |
| Consumers | Risk dashboard, audit trail, compliance reporting |

### Event Schema Design

```solidity
// Indexed fields = searchable (like Event Hub partition key)
// Non-indexed fields = payload data
event ClaimSubmitted(
    uint256 indexed claimId,   // Searchable — filter by claim
    address indexed agency,    // Searchable — filter by agency
    uint256 claimAmount        // Payload — not indexed
);
```

### Azure Event Hub Comparison

| Azure Event Hub | MediChain Pay |
|---|---|
| Producer | Smart contract function |
| Event Hub | Blockchain event log |
| Consumer Group | Frontend / dashboard subscriber |
| Processing | UI update / dashboard refresh |

---

## API Integration Layer — Phase 4

### Chainlink Functions — The API Gateway

**Azure Pattern vs MediChain Pay Pattern**

| Step | Azure Tool | MediChain Pay Tool |
|---|---|---|
| Receive trigger | Logic App trigger | Chainlink automation condition |
| Call external API | API Management connector | Chainlink Functions HTTP request |
| Process response | Logic App action | JavaScript handler |
| Update system | Service Bus message | On-chain transaction |

### Availity Integration Design

```javascript
// Chainlink Functions — Availity claim validation
// Same API call pattern as a Logic App connector

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

const claimStatus = response.data.status;
const claimAmount = response.data.amount;
const payerId = response.data.payerId;

return Functions.encodeString(JSON.stringify({
    status: claimStatus,
    amount: claimAmount,
    payerId: payerId
}));
```

---

## ETL Pipeline — ERA/835 Processing — Phase 4

### Extract

| Property | Value |
|---|---|
| Source | CMS / Medicaid MCO |
| Format | ANSI X12 835 transaction set |
| Transport | SFTP / clearinghouse API |
| Frequency | Daily batch + real-time |

### Transform

| Segment | Description |
|---|---|
| BPR | Financial information (payment amount) |
| TRN | Trace number (check/EFT number) |
| CLP | Claim payment information |
| SVC | Service payment information |

| Field | Action |
|---|---|
| Claim ID | Matches on-chain claimId |
| Payment amount | Validates against claimAmount |
| Payer ID | Validates against expected payer |
| Payment date | Triggers repayAdvance() |
| Adjustment codes | Triggers applyRecoupment() if needed |

### Load

| Property | Value |
|---|---|
| Target | Blockchain via Chainlink oracle |
| Method | Chainlink Functions HTTP request |
| Trigger | repayAdvance() or applyRecoupment() |
| Frequency | Real-time per remittance event |

### Azure Data Factory Comparison

| Azure Data Factory | MediChain Pay |
|---|---|
| Source Dataset (835 file) | ERA/835 from clearinghouse |
| Mapping Data Flow | Chainlink Functions parser |
| Derived Column (835 segments) | BPR, TRN, CLP, SVC extraction |
| Filter (match claim IDs) | On-chain claimId matching |
| Sink Dataset (trigger API) | repayAdvance() or applyRecoupment() |

---

## Automation Layer — Phase 4

### Automation Use Cases

| Use Case | Condition | Action |
|---|---|---|
| Automated repayment | CMS remittance detected for Claim X | repayAdvance(X) called automatically |
| Reserve release | block.timestamp >= advancedAt + 180 days | releaseReserve(X) called automatically |
| Recoupment monitoring | ERA/835 contains adjustment code CO-4 | applyRecoupment(X, amount) called automatically |

### Power Automate Comparison

| Power Automate | Chainlink Automation |
|---|---|
| Trigger: new file in SharePoint | Trigger: block.timestamp condition met |
| Action: Parse JSON | Action: Parse on-chain state |
| Action: Call REST API | Action: Call smart contract function |
| Action: Update database | Action: State written to blockchain |

---

## Immutable Audit Trail

### Why Blockchain Beats Traditional Audit Logging

| Traditional Audit Log | Blockchain Audit Log |
|---|---|
| DBA can alter records | Nobody can alter records |
| Regulators must trust you | Regulators verify independently |
| Internal access required | Publicly queryable |
| Centralized — single point of failure | Distributed — no single point of failure |

### Two Audit Trails Working Together

| Layer | System | What It Logs |
|---|---|---|
| Identity | Auth0 | Who logged in, when, from where, what role |
| Transactions | Blockchain | Every claim, advance, repayment, clawback |

### The Blockchain Audit Trail in Action

```
Block 32:  ClaimSubmitted(1, 0x5B38..., 5000000000)
Block 33:  FundsAdvanced(1, 0x5B38..., 4250000000, 250000000)
Block 36:  AdvanceRepaid(1, 4313750000)
Block 47:  ReserveReleased(1, 0x5B38..., 250000000)
```

### Querying Events — Like Azure Log Analytics

```javascript
// Query blockchain events
// Equivalent to a KQL query in Azure Log Analytics

const filter = contract.filters.ClaimSubmitted(null, agencyAddress);
const events = await contract.queryFilter(filter, fromBlock, toBlock);

// KQL equivalent:
// AuditLog
// | where AgencyId == "0x5B38..."
// | order by Timestamp asc
```

---

## Access Control Architecture

### Two-Layer RBAC Design

| Layer | System | Controls |
|---|---|---|
| Application | Auth0 | What pages and features users can see |
| Blockchain | Smart contract modifiers | What on-chain functions can be called |

### Current MVP Roles

| Role | Auth0 Access | Smart Contract Access |
|---|---|---|
| Owner | Full admin dashboard | All onlyOwner functions |
| Agency Admin | Full agency portal | submitClaim() |
| Agency Staff | Limited portal view | submitClaim() |
| Public | None | getClaimStatus(), getContractBalance() |

### Phase 4 Roles

| Role | Auth0 Access | Smart Contract Access | Azure Equivalent |
|---|---|---|---|
| Owner | Platform admin | Full control | Subscription Owner |
| Reviewer | Claim review only | denySubmittedClaim() | Contributor |
| Oracle | Automated only | repayAdvance(), releaseReserve() | Service Principal |
| Agency Admin | Full portal | submitClaim() | Scoped Contributor |
| Auditor | Read-only all data | getClaimStatus() | Reader |

---

## Liquidity Pool Architecture

### Capital Allocation Model

| Component | Formula | Example |
|---|---|---|
| Total Pool | USDC in contract | $100,000 |
| Committed Capital | Sum of active reserves | $12,500 (50 x $250) |
| Available Capital | Total Pool - Committed | $87,500 |
| Advance Capacity | Available / advancePercent | ~$102,941 |

### Phase 4 Capital Sources

| Source | Description |
|---|---|
| Founder capital | Current — bootstrapped |
| Institutional DeFi pool | External liquidity providers |
| Secondary market | Claim advance marketplace |
| Tokenized pool shares | Investor participation |

---

## Technology Roadmap — Data Architecture View

### Phase 3 — MVP (Current)

| Component | Status |
|---|---|
| On-chain data model (Claim struct) | Complete |
| Event-driven architecture (7 events) | Complete |
| RBAC — onlyOwner pattern | Complete |
| Immutable audit trail | Complete |
| Auth0 Healthcare CIAM integration | In progress |
| React frontend event subscribers | In progress |
| Base Sepolia deployment | In progress |

### Phase 4 — Automation

| Component | Status |
|---|---|
| Chainlink Functions → Availity API | Planned |
| ERA/835 ETL pipeline → Chainlink oracle | Planned |
| Chainlink Automation → repayAdvance() | Planned |
| Chainlink Automation → releaseReserve() | Planned |
| Auth0 SSO → Epic / Cerner / Homecare Homebase | Planned |
| Auth0 AI Agent Authentication | Planned |
| Auth0 Fine-Grained Authorization | Planned |
| Advanced RBAC (Reviewer, Oracle roles) | Planned |
| Liquidity pool monitoring dashboard | Planned |

### Phase 5 — Scale

| Component | Status |
|---|---|
| Multi-payer data feeds | Planned |
| Institutional liquidity integration | Planned |
| Secondary market for claim advances | Planned |
| Cross-chain expansion | Planned |
| Predictive claim risk scoring (ML pipeline) | Planned |

---

## The Architect's Advantage

Most blockchain developers learn decentralized systems first and enterprise patterns second — if at all.

This platform is built by someone who spent years at Microsoft designing the exact integration patterns that blockchain infrastructure is now replicating:

| Enterprise Experience | Blockchain Application |
|---|---|
| Azure AD B2C / identity management | Auth0 Healthcare CIAM |
| Event-driven pipelines | Smart contract events |
| API integration layers | Chainlink Functions |
| ETL processing | Oracle data feeds |
| Workflow automation | Chainlink Automation |
| Immutable audit logs | Blockchain ledger |
| Azure RBAC | Smart contract modifiers + Auth0 roles |

The result is a healthcare payment platform that combines the rigor of enterprise data architecture with the transparency and automation of blockchain infrastructure — and the compliance requirements of the healthcare industry.

---

*MediChain Pay — Data Architecture Documentation*

*Built on enterprise integration patterns from Microsoft*

*github.com/darnharris37/medichain-pay*
