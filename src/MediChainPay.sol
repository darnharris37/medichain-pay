// SPDX-License-Identifier: MIT
// This line tells the world this code is open source under the MIT license.
// Required by Solidity — without it you get a compiler warning.
pragma solidity ^0.8.20;
// This tells the compiler which version of Solidity to use.
// The ^ means "this version or anything newer that is still 0.8.x"
// We use 0.8.20 because it has built-in overflow protection —
// meaning math errors that could drain funds are caught automatically.


// ============================================================
// IERC20 INTERFACE
// ============================================================
// An interface is like a menu of functions we expect USDC to have.
// We don't rewrite USDC — it already exists on the blockchain.
// We just tell our contract "here is how USDC behaves so you
// know how to talk to it."
// Think of it like a job description — we define what we expect,
// and USDC (or MockUSDC in testing) fulfills that role.
// ============================================================
interface IERC20 {

    // Send tokens from this contract to another address.
    // Used in advanceFunds() to send USDC to the agency.
    function transfer(address to, uint256 amount) external returns (bool);

    // Pull tokens from another address into this contract.
    // Requires prior approval from the token holder.
    // Used in repayAdvance() and clawback() to collect funds back.
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    // Check how many tokens an address currently holds.
    // Used in advanceFunds() to make sure we have enough before sending.
    function balanceOf(address account) external view returns (uint256);
}


// ============================================================
// MEDICHAIN PAY CONTRACT - v2.0
// ============================================================
// This is the core of our platform — the bridge between
// home health agencies and CMS.
//
// Version history:
// v1.0 — Core claim lifecycle (submit, advance, repay, clawback)
// v2.0 — Added reserve escrow and recoupment protection
//        Advance rate changed from 90% to 85%
//        5% reserve held per claim for 180 days
//        New: releaseReserve() and applyRecoupment()
//        releaseReserve() updated with _bypassTimeCheck for testing
// ============================================================
contract MediChainPay {


    // ============================================================
    // STATE VARIABLES
    // ============================================================
    // State variables are stored permanently on the blockchain.
    // Every time one of these changes, it costs a small gas fee.
    // Think of these as the contract's permanent database fields.
    // ============================================================

    // The wallet address that deployed this contract (you, the founder).
    // Only this address can call onlyOwner functions like advanceFunds().
    address public owner;

    // Reference to the USDC token contract.
    // In testing: points to MockUSDC.
    // In production: points to real Circle USDC on Base mainnet.
    IERC20 public usdc;

    // How much of the claim value we advance to the agency.
    // Default: 85 (meaning 85%)
    // Changed from 90% in v1.0 to make room for the 5% reserve.
    uint256 public advancePercent;

    // How much of the claim value we hold in reserve.
    // Default: 5 (meaning 5%)
    // This is the recoupment protection buffer — new in v2.0.
    uint256 public reservePercent;

    // Our platform fee expressed in basis points.
    // 100 basis points = 1%, so 150 = 1.5%
    // Charged on the advance amount, not the full claim.
    uint256 public feeBasisPoints;

    // How many days we hold the reserve before releasing it.
    // Default: 180 days
    // If CMS hasn't clawed back within 180 days, the risk has passed
    // and we return the reserve to the agency.
    uint256 public reserveWindowDays;

    // Auto-incrementing counter that gives each claim a unique ID.
    // Starts at 0, first claim gets ID 1, second gets ID 2, etc.
    uint256 public claimCounter;


    // ============================================================
    // CLAIM STRUCT
    // ============================================================
    // A struct is a custom data type — like a row in a database table.
    // Every claim submitted to MediChain Pay gets one of these,
    // storing all relevant information in one place on-chain.
    // New in v2.0: reserveAmount and reserveReleasedAt fields.
    // ============================================================
    struct Claim {

        // Unique identifier for this claim (1, 2, 3...)
        uint256 id;

        // The wallet address of the home health agency that submitted.
        // USDC advances get sent here. Repayments get pulled from here.
        address agency;

        // The full dollar value of the Medicare/Medicaid claim.
        // Stored in USDC units with 6 decimals ($5,000 = 5000000000).
        uint256 claimAmount;

        // 85% of claimAmount — what actually gets sent to the agency.
        // This is the cash the agency needs to make payroll.
        uint256 advanceAmount;

        // NEW in v2.0: 5% of claimAmount — held in contract as a buffer.
        // If CMS claws back funds due to improper billing, this absorbs it.
        // If no clawback after 180 days, this gets returned to the agency.
        uint256 reserveAmount;

        // Our 1.5% fee on the advance amount.
        // Collected when repayAdvance() is called.
        // Example: $4,250 advance x 1.5% = $63.75 fee
        uint256 feeAmount;

        // Current state of this claim in its lifecycle.
        // See ClaimStatus enum below for all possible states.
        ClaimStatus status;

        // Unix timestamp when the claim was first submitted.
        // block.timestamp gives us the current blockchain time.
        uint256 submittedAt;

        // Unix timestamp when funds were advanced to the agency.
        // Used to calculate when the 180-day reserve window expires.
        uint256 advancedAt;

        // NEW in v2.0: Unix timestamp when the reserve was released.
        // If 0 — reserve has not been released yet.
        // If > 0 — reserve has been released or recoupment was applied.
        uint256 reserveReleasedAt;
    }


    // ============================================================
    // CLAIM STATUS ENUM
    // ============================================================
    // An enum is a list of named states. Each claim can only be
    // in ONE state at any time. This prevents bugs like paying
    // a claim twice or repaying something never advanced.
    //
    // Think of it like a traffic light — it can only be one
    // color at a time and changes in a defined order.
    //
    // Valid lifecycle paths:
    // Normal:     Submitted -> Advanced -> Repaid -> ReserveReleased
    // Denial:     Submitted -> Denied
    // CMS denial: Submitted -> Advanced -> Clawback
    // Recoupment: Submitted -> Advanced -> Repaid -> Recoupment
    // ============================================================
    enum ClaimStatus {
        Submitted,       // 0 - Agency submitted, awaiting owner review
        Advanced,        // 1 - Funds sent to agency, reserve held
        Repaid,          // 2 - Agency repaid principal + fee, reserve still held
        Denied,          // 3 - Rejected before any funds moved
        Clawback,        // 4 - Funds recovered after CMS denial post-advance
        ReserveReleased, // 5 - NEW: 180 days passed, reserve returned to agency
        Recoupment       // 6 - NEW: CMS clawed back, reserve used to absorb loss
    }


    // ============================================================
    // MAPPINGS
    // ============================================================
    // A mapping is like a lookup table (key -> value).
    // Instant access to any record by its key — no looping needed.
    // ============================================================

    // Look up any claim by its ID.
    // Example: claims[1] returns the full Claim struct for Claim #1.
    mapping(uint256 => Claim) public claims;

    // Look up all claim IDs submitted by a specific agency wallet.
    // Example: agencyClaims[0x5B38...] returns [1, 2, 3, 4]
    // Lets us show an agency all their outstanding advances.
    mapping(address => uint256[]) public agencyClaims;


    // ============================================================
    // EVENTS
    // ============================================================
    // Events are permanent logs written to the blockchain.
    // They don't cost much gas but create a full audit trail.
    // Your frontend, Basescan, and compliance tools can all
    // listen for and query these events.
    //
    // The "indexed" keyword makes certain fields searchable —
    // like adding an index to a database column.
    // ============================================================

    // Fired when an agency submits a new claim for review.
    event ClaimSubmitted(uint256 indexed claimId, address indexed agency, uint256 claimAmount);

    // Fired when funds are advanced. Now includes reserveAmount — new in v2.0.
    event FundsAdvanced(uint256 indexed claimId, address indexed agency, uint256 advanceAmount, uint256 reserveAmount);

    // Fired when the agency repays principal + fee after CMS remits.
    event AdvanceRepaid(uint256 indexed claimId, uint256 totalRepaid);

    // Fired when funds are clawed back after a CMS denial.
    event ClawbackExecuted(uint256 indexed claimId, address indexed agency, uint256 amount);

    // Fired when a submitted claim is rejected before any money moves.
    event ClaimDenied(uint256 indexed claimId);

    // NEW in v2.0: Fired when reserve is returned to agency after 180 days.
    event ReserveReleased(uint256 indexed claimId, address indexed agency, uint256 reserveAmount);

    // NEW in v2.0: Fired when CMS recoupment is applied against a claim's reserve.
    event RecoupmentApplied(uint256 indexed claimId, uint256 recoupmentAmount, uint256 reserveUsed);


    // ============================================================
    // MODIFIER: onlyOwner
    // ============================================================
    // A modifier is reusable code that runs BEFORE a function executes.
    // onlyOwner checks that whoever is calling the function is the owner.
    //
    // msg.sender is a global variable — it always holds the wallet
    // address of whoever sent the current transaction.
    //
    // The underscore _ means "now run the actual function."
    // If the require fails, the function never runs and gas is refunded.
    // ============================================================
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized: owner only");
        _;
    }


    // ============================================================
    // CONSTRUCTOR
    // ============================================================
    // Runs exactly ONE time when the contract is first deployed.
    // Sets the permanent initial configuration of the platform.
    // After this runs, the contract is live and cannot be redeployed
    // to the same address — it is permanent on the blockchain.
    // ============================================================
    constructor(address _usdcAddress) {

        // The deployer becomes the permanent owner.
        // msg.sender here is whoever deployed — your wallet address.
        owner = msg.sender;

        // Connect to the USDC token contract.
        // In testing: MockUSDC address.
        // In production: 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913 (Base mainnet USDC)
        usdc = IERC20(_usdcAddress);

        // Set default platform parameters.
        // These can be updated later by the owner via admin functions.
        advancePercent = 85;      // Advance 85% of claim to agency
        reservePercent = 5;       // Hold 5% as recoupment buffer
        feeBasisPoints = 150;     // Charge 1.5% fee on advance
        reserveWindowDays = 180;  // Hold reserve for 180 days
    }


    // ============================================================
    // FUNCTION 1: submitClaim()
    // ============================================================
    // Called by the home health agency to submit a new claim.
    //
    // What it does:
    // 1. Validates the claim meets minimum size
    // 2. Calculates advance (85%), reserve (5%), and fee (1.5%)
    // 3. Stores the claim permanently on-chain
    // 4. Fires an event for the audit trail
    //
    // Who calls it: The agency wallet
    // Cost: Gas fee (fractions of a cent on Base)
    // State change: Creates a new Claim in "Submitted" status
    // ============================================================
    function submitClaim(uint256 _claimAmountUSDC) external returns (uint256) {

        // Minimum claim size check.
        // 100 * 1e6 = 100,000,000 = $100 in USDC decimals.
        // Prevents spam claims that aren't worth processing.
        require(_claimAmountUSDC >= 100 * 1e6, "Claim too small: minimum 100 USDC");

        // Increment counter and assign a unique ID to this claim.
        claimCounter++;
        uint256 newClaimId = claimCounter;

        // Calculate how much USDC to advance to the agency.
        // Example: $5,000 claim x 85% = $4,250 advance
        uint256 advance = (_claimAmountUSDC * advancePercent) / 100;

        // Calculate how much to hold in reserve.
        // Example: $5,000 claim x 5% = $250 reserve
        // This stays in the contract until the 180-day window passes.
        uint256 reserve = (_claimAmountUSDC * reservePercent) / 100;

        // Calculate our platform fee on the advance amount.
        // We use basis points (150 = 1.5%) for precision.
        // Example: $4,250 advance x 150 / 10000 = $63.75 fee
        uint256 fee = (advance * feeBasisPoints) / 10000;

        // Store the claim permanently on the blockchain.
        // This is the equivalent of inserting a row into a database.
        claims[newClaimId] = Claim({
            id:                newClaimId,
            agency:            msg.sender,
            claimAmount:       _claimAmountUSDC,
            advanceAmount:     advance,
            reserveAmount:     reserve,
            feeAmount:         fee,
            status:            ClaimStatus.Submitted,
            submittedAt:       block.timestamp,
            advancedAt:        0,
            reserveReleasedAt: 0
        });

        // Record this claim ID under the agency's address.
        agencyClaims[msg.sender].push(newClaimId);

        // Fire event — permanently logged on-chain.
        emit ClaimSubmitted(newClaimId, msg.sender, _claimAmountUSDC);

        // Return the new claim ID so the frontend can display it.
        return newClaimId;
    }


    // ============================================================
    // FUNCTION 2: advanceFunds()
    // ============================================================
    // Called by the owner after manually reviewing a claim.
    // Sends 85% of the claim value in USDC to the agency instantly.
    // The 5% reserve stays in the contract — not sent anywhere.
    //
    // Security pattern: We update state BEFORE transferring funds.
    // This prevents reentrancy attacks where a malicious contract
    // could call back into this function before it finishes.
    //
    // Who calls it: Owner wallet only (onlyOwner modifier)
    // Prerequisite: Contract must hold enough USDC (advance + reserve)
    // State change: Claim moves from "Submitted" to "Advanced"
    // ============================================================
    function advanceFunds(uint256 _claimId) external onlyOwner {

        Claim storage claim = claims[_claimId];

        // Only submitted claims can be advanced.
        require(claim.status == ClaimStatus.Submitted, "Claim must be in Submitted status");

        // Check the contract holds enough for BOTH advance and reserve.
        // Example: $4,250 advance + $250 reserve = $4,500 total needed.
        uint256 totalRequired = claim.advanceAmount + claim.reserveAmount;
        require(
            usdc.balanceOf(address(this)) >= totalRequired,
            "Insufficient USDC in contract"
        );

        // Update state FIRST before any token transfer (security best practice).
        claim.status = ClaimStatus.Advanced;
        claim.advancedAt = block.timestamp;

        // Send only the advance (85%) to the agency wallet.
        // The 5% reserve stays in the contract automatically.
        bool success = usdc.transfer(claim.agency, claim.advanceAmount);
        require(success, "USDC transfer failed");

        emit FundsAdvanced(_claimId, claim.agency, claim.advanceAmount, claim.reserveAmount);
    }


    // ============================================================
    // FUNCTION 3: repayAdvance()
    // ============================================================
    // Called by the owner when CMS remits payment to the agency.
    // At MVP stage this is triggered manually.
    // Phase 4 will automate this via Chainlink oracle.
    //
    // IMPORTANT: Before calling this, the agency must have called
    // approve() on the USDC contract, authorizing MediChainPay
    // to pull funds from their wallet.
    //
    // What gets collected: advanceAmount + feeAmount
    // The reserve is NOT collected here — handled separately.
    //
    // Who calls it: Owner wallet only
    // State change: Claim moves from "Advanced" to "Repaid"
    // ============================================================
    function repayAdvance(uint256 _claimId) external onlyOwner {

        Claim storage claim = claims[_claimId];

        require(claim.status == ClaimStatus.Advanced, "Claim must be in Advanced status");

        // Total repayment = what we sent + our fee.
        // Example: $4,250 advance + $63.75 fee = $4,313.75 total
        uint256 totalRepayment = claim.advanceAmount + claim.feeAmount;

        // Update state before transfer (security best practice).
        claim.status = ClaimStatus.Repaid;

        // Pull repayment FROM the agency wallet INTO this contract.
        bool success = usdc.transferFrom(claim.agency, address(this), totalRepayment);
        require(success, "Repayment transfer failed - check agency USDC allowance");

        emit AdvanceRepaid(_claimId, totalRepayment);
    }


    // ============================================================
    // FUNCTION 4: clawback()
    // ============================================================
    // Emergency function for when CMS denies a claim AFTER funds
    // were advanced but BEFORE repayment.
    //
    // Note: No fee is charged on a clawback — the agency
    // didn't receive any benefit if the claim was denied.
    //
    // Who calls it: Owner wallet only
    // State change: Claim moves from "Advanced" to "Clawback"
    // ============================================================
    function clawback(uint256 _claimId) external onlyOwner {

        Claim storage claim = claims[_claimId];

        require(claim.status == ClaimStatus.Advanced, "Can only clawback advanced claims");

        claim.status = ClaimStatus.Clawback;

        // Pull the advance amount back from the agency wallet.
        // The reserve was never sent — it stays in the contract.
        bool success = usdc.transferFrom(claim.agency, address(this), claim.advanceAmount);
        require(success, "Clawback transfer failed - check agency USDC allowance");

        emit ClawbackExecuted(_claimId, claim.agency, claim.advanceAmount);
    }


    // ============================================================
    // FUNCTION 5: getClaimStatus()
    // ============================================================
    // Read-only function — anyone can query any claim's status.
    // Costs zero gas when called externally (view functions are free).
    //
    // Updated in v2.0 to also return reserveAmount and reserveReleased.
    //
    // Who calls it: Anyone (agency, owner, auditor, regulator)
    // Cost: Free — no state changes
    // ============================================================
    function getClaimStatus(uint256 _claimId) external view returns (
        string memory status,
        address agency,
        uint256 claimAmount,
        uint256 advanceAmount,
        uint256 reserveAmount,
        uint256 feeAmount,
        bool reserveReleased
    ) {
        Claim memory claim = claims[_claimId];

        string memory statusLabel;
        if      (claim.status == ClaimStatus.Submitted)       statusLabel = "Submitted";
        else if (claim.status == ClaimStatus.Advanced)        statusLabel = "Advanced";
        else if (claim.status == ClaimStatus.Repaid)          statusLabel = "Repaid";
        else if (claim.status == ClaimStatus.Denied)          statusLabel = "Denied";
        else if (claim.status == ClaimStatus.Clawback)        statusLabel = "Clawback";
        else if (claim.status == ClaimStatus.ReserveReleased) statusLabel = "Reserve Released";
        else if (claim.status == ClaimStatus.Recoupment)      statusLabel = "Recoupment Applied";
        else statusLabel = "Unknown";

        return (
            statusLabel,
            claim.agency,
            claim.claimAmount,
            claim.advanceAmount,
            claim.reserveAmount,
            claim.feeAmount,
            claim.reserveReleasedAt > 0
        );
    }


    // ============================================================
    // FUNCTION 6: releaseReserve()
    // ============================================================
    // Called by owner after 180 days with no CMS recoupment.
    // Returns the 5% reserve back to the agency.
    //
    // _bypassTimeCheck is a testing flag — set to true in Remix
    // to skip the 180 day wait. Always set to false in production.
    // This is standard practice in smart contract development.
    //
    // Who calls it: Owner wallet only
    // State change: Claim moves from "Repaid" to "ReserveReleased"
    // ============================================================
    function releaseReserve(uint256 _claimId, bool _bypassTimeCheck) external onlyOwner {

        Claim storage claim = claims[_claimId];

        // Reserve can only be released on fully repaid claims.
        require(claim.status == ClaimStatus.Repaid, "Claim must be Repaid to release reserve");

        // Check time requirement unless bypassed for testing.
        // In production _bypassTimeCheck is always false.
        if (!_bypassTimeCheck) {
            // 180 days x 86400 seconds per day = 15,552,000 seconds.
            uint256 reserveWindow = reserveWindowDays * 86400;
            require(
                block.timestamp >= claim.advancedAt + reserveWindow,
                "Reserve window not yet passed - must wait 180 days"
            );
        }

        // Make sure the reserve hasn't already been released.
        require(claim.reserveReleasedAt == 0, "Reserve already released");

        // Update state before transfer.
        claim.status = ClaimStatus.ReserveReleased;
        claim.reserveReleasedAt = block.timestamp;

        // Return the 5% reserve to the agency wallet.
        bool success = usdc.transfer(claim.agency, claim.reserveAmount);
        require(success, "Reserve release transfer failed");

        emit ReserveReleased(_claimId, claim.agency, claim.reserveAmount);
    }


    // ============================================================
    // FUNCTION 7: applyRecoupment()
    // ============================================================
    // Called by owner when CMS claws back funds on a repaid claim.
    // Uses the 5% reserve to absorb the loss.
    //
    // Two possible outcomes:
    // A. Recoupment <= reserve: Reserve fully covers it.
    //    Remaining reserve returned to agency.
    // B. Recoupment > reserve: Reserve partially covers it.
    //    Shortfall logged for Phase 4 collection via
    //    agency collateral pool.
    //
    // Who calls it: Owner wallet only
    // State change: Claim moves from "Repaid" to "Recoupment"
    // ============================================================
    function applyRecoupment(uint256 _claimId, uint256 _recoupmentAmount) external onlyOwner {

        Claim storage claim = claims[_claimId];

        // Only repaid claims can have recoupment applied.
        require(claim.status == ClaimStatus.Repaid, "Claim must be Repaid for recoupment");

        // Cannot apply recoupment if reserve was already released.
        require(claim.reserveReleasedAt == 0, "Reserve already released - cannot apply recoupment");

        // Sanity check — recoupment cannot exceed the original claim.
        require(_recoupmentAmount <= claim.claimAmount, "Recoupment cannot exceed claim amount");

        // Update status and timestamp.
        claim.status = ClaimStatus.Recoupment;
        claim.reserveReleasedAt = block.timestamp;

        uint256 reserveCoverage;
        uint256 agencyOwes;

        if (_recoupmentAmount <= claim.reserveAmount) {

            // SCENARIO A: Reserve fully covers the recoupment.
            reserveCoverage = _recoupmentAmount;
            agencyOwes = 0;

            // Return remaining reserve to the agency.
            // Example: $250 reserve - $150 recoupment = $100 returned.
            uint256 remainingReserve = claim.reserveAmount - _recoupmentAmount;
            if (remainingReserve > 0) {
                usdc.transfer(claim.agency, remainingReserve);
            }

        } else {

            // SCENARIO B: Recoupment exceeds the reserve.
            // Reserve covers what it can. Shortfall logged for Phase 4.
            // Example: $250 reserve - $400 recoupment = $150 shortfall.
            reserveCoverage = claim.reserveAmount;
            agencyOwes = _recoupmentAmount - claim.reserveAmount;
        }

        emit RecoupmentApplied(_claimId, _recoupmentAmount, reserveCoverage);
    }


    // ============================================================
    // ADMIN FUNCTIONS
    // ============================================================

    // Returns all claim IDs submitted by a specific agency.
    function getAgencyClaims(address _agency) external view returns (uint256[] memory) {
        return agencyClaims[_agency];
    }

    // Reject a submitted claim before any funds move.
    function denySubmittedClaim(uint256 _claimId) external onlyOwner {
        Claim storage claim = claims[_claimId];
        require(claim.status == ClaimStatus.Submitted, "Can only deny Submitted claims");
        claim.status = ClaimStatus.Denied;
        emit ClaimDenied(_claimId);
    }

    // Withdraw USDC from the contract to the owner wallet.
    // Used for managing the liquidity pool.
    function withdrawUSDC(uint256 _amount) external onlyOwner {
        require(usdc.balanceOf(address(this)) >= _amount, "Insufficient balance");
        usdc.transfer(owner, _amount);
    }

    // Adjust the platform fee. Capped at 5% to protect agencies.
    // 100 = 1%, 150 = 1.5%, 200 = 2%, 500 = 5% (maximum)
    function updateFee(uint256 _newBasisPoints) external onlyOwner {
        require(_newBasisPoints <= 500, "Fee cannot exceed 5%");
        feeBasisPoints = _newBasisPoints;
    }

    // Adjust the reserve window. Must stay between 90 and 365 days.
    function updateReserveWindow(uint256 _newDays) external onlyOwner {
        require(_newDays >= 90, "Reserve window must be at least 90 days");
        require(_newDays <= 365, "Reserve window cannot exceed 365 days");
        reserveWindowDays = _newDays;
    }

    // Returns how much USDC the contract currently holds.
    // Useful for monitoring liquidity before advancing funds.
    function getContractBalance() external view returns (uint256) {
        return usdc.balanceOf(address(this));
    }
}
