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
| Access control | Azure RBAC | onlyOwner modifier |
| Monitoring | Azure Monitor | Basescan event logs |

---

## The On-Chain Data Model

The MediChain Pay on-chain data model was designed with the same principles used in enterprise database architecture — normalized, indexed, and constrained.

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

SQL Server and Solidity solve the same problem differently:

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
| Source | Agency wallet |
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

Events in Solidity are designed with the same principles as Azure Event Hub event schemas — indexed fields for searchability, minimal payload for efficiency.

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

The pattern is identical. The infrastructure is different.

---

## API Integration Layer — Phase 4

### Chainlink Functions — The API Gateway

Chainlink Functions is the blockchain equivalent of Azure API Management combined with Azure Logic Apps. It allows smart contracts to make authenticated HTTP requests to external APIs — exactly like Logic App connectors calling REST APIs.

**Azure Pattern:**
