// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract MediChainPay {

    address public owner;
    IERC20 public usdc;
    uint256 public advancePercent;
    uint256 public feeBasisPoints;
    uint256 public claimCounter;

    struct Claim {
        uint256 id;
        address agency;
        uint256 claimAmount;
        uint256 advanceAmount;
        uint256 feeAmount;
        ClaimStatus status;
        uint256 submittedAt;
        uint256 advancedAt;
    }

    enum ClaimStatus {
        Submitted,
        Approved,
        Advanced,
        Repaid,
        Denied,
        Clawback
    }

    mapping(uint256 => Claim) public claims;
    mapping(address => uint256[]) public agencyClaims;

    event ClaimSubmitted(uint256 indexed claimId, address indexed agency, uint256 claimAmount);
    event FundsAdvanced(uint256 indexed claimId, address indexed agency, uint256 advanceAmount);
    event AdvanceRepaid(uint256 indexed claimId, uint256 totalRepaid);
    event ClawbackExecuted(uint256 indexed claimId, address indexed agency, uint256 amount);
    event ClaimDenied(uint256 indexed claimId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized: owner only");
        _;
    }

    constructor(address _usdcAddress) {
        owner = msg.sender;
        usdc = IERC20(_usdcAddress);
        advancePercent = 90;
        feeBasisPoints = 150;
    }

    function submitClaim(uint256 _claimAmountUSDC) external returns (uint256) {
        require(_claimAmountUSDC >= 100 * 1e6, "Claim too small: minimum 100 USDC");

        claimCounter++;
        uint256 newClaimId = claimCounter;

        uint256 advance = (_claimAmountUSDC * advancePercent) / 100;
        uint256 fee = (advance * feeBasisPoints) / 10000;

        claims[newClaimId] = Claim({
            id:            newClaimId,
            agency:        msg.sender,
            claimAmount:   _claimAmountUSDC,
            advanceAmount: advance,
            feeAmount:     fee,
            status:        ClaimStatus.Submitted,
            submittedAt:   block.timestamp,
            advancedAt:    0
        });

        agencyClaims[msg.sender].push(newClaimId);
        emit ClaimSubmitted(newClaimId, msg.sender, _claimAmountUSDC);
        return newClaimId;
    }

    function advanceFunds(uint256 _claimId) external onlyOwner {
        Claim storage claim = claims[_claimId];
        require(claim.status == ClaimStatus.Submitted, "Claim must be in Submitted status");
        require(usdc.balanceOf(address(this)) >= claim.advanceAmount, "Insufficient USDC in contract");

        claim.status = ClaimStatus.Advanced;
        claim.advancedAt = block.timestamp;

        bool success = usdc.transfer(claim.agency, claim.advanceAmount);
        require(success, "USDC transfer failed");

        emit FundsAdvanced(_claimId, claim.agency, claim.advanceAmount);
    }

    function repayAdvance(uint256 _claimId) external onlyOwner {
        Claim storage claim = claims[_claimId];
        require(claim.status == ClaimStatus.Advanced, "Claim must be in Advanced status");

        uint256 totalRepayment = claim.advanceAmount + claim.feeAmount;
        claim.status = ClaimStatus.Repaid;

        bool success = usdc.transferFrom(claim.agency, address(this), totalRepayment);
        require(success, "Repayment transfer failed - check agency USDC allowance");

        emit AdvanceRepaid(_claimId, totalRepayment);
    }

    function clawback(uint256 _claimId) external onlyOwner {
        Claim storage claim = claims[_claimId];
        require(claim.status == ClaimStatus.Advanced, "Can only clawback advanced claims");

        claim.status = ClaimStatus.Clawback;

        bool success = usdc.transferFrom(claim.agency, address(this), claim.advanceAmount);
        require(success, "Clawback transfer failed - check agency USDC allowance");

        emit ClawbackExecuted(_claimId, claim.agency, claim.advanceAmount);
    }

    function getClaimStatus(uint256 _claimId) external view returns (
        string memory status,
        address agency,
        uint256 claimAmount,
        uint256 advanceAmount,
        uint256 feeAmount
    ) {
        Claim memory claim = claims[_claimId];

        string memory statusLabel;
        if (claim.status == ClaimStatus.Submitted)       statusLabel = "Submitted";
        else if (claim.status == ClaimStatus.Approved)   statusLabel = "Approved";
        else if (claim.status == ClaimStatus.Advanced)   statusLabel = "Advanced";
        else if (claim.status == ClaimStatus.Repaid)     statusLabel = "Repaid";
        else if (claim.status == ClaimStatus.Denied)     statusLabel = "Denied";
        else if (claim.status == ClaimStatus.Clawback)   statusLabel = "Clawback";
        else statusLabel = "Unknown";

        return (statusLabel, claim.agency, claim.claimAmount, claim.advanceAmount, claim.feeAmount);
    }

    function getAgencyClaims(address _agency) external view returns (uint256[] memory) {
        return agencyClaims[_agency];
    }

    function denySubmittedClaim(uint256 _claimId) external onlyOwner {
        Claim storage claim = claims[_claimId];
        require(claim.status == ClaimStatus.Submitted, "Can only deny Submitted claims");
        claim.status = ClaimStatus.Denied;
        emit ClaimDenied(_claimId);
    }

    function withdrawUSDC(uint256 _amount) external onlyOwner {
        require(usdc.balanceOf(address(this)) >= _amount, "Insufficient balance");
        usdc.transfer(owner, _amount);
    }

    function updateFee(uint256 _newBasisPoints) external onlyOwner {
        require(_newBasisPoints <= 500, "Fee cannot exceed 5%");
        feeBasisPoints = _newBasisPoints;
    }
}
