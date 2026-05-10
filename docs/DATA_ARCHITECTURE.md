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
