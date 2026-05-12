import { useState } from "react";

const Logo = ({ src, fallback, size = 24 }) => {
  const [err, setErr] = useState(false);
  if (err || !src) return <span style={{ fontSize: size * 0.85, lineHeight: 1 }}>{fallback}</span>;
  return <img src={src} alt="" onError={() => setErr(true)}
    style={{ width: size, height: size, objectFit: "contain", display: "block" }} />;
};

const L = {
  react:     "https://upload.wikimedia.org/wikipedia/commons/a/a7/React-icon.svg",
  base:      "https://raw.githubusercontent.com/base-org/brand-kit/001c0e9b40a67799ebe0418671ac4e02a0c683ce/logo/in-product/Base_Network_Logo.svg",
  usdc:      "https://cryptologos.cc/logos/usd-coin-usdc-logo.svg?v=035",
  chainlink: "https://cryptologos.cc/logos/chainlink-link-logo.svg?v=035",
  eth:       "https://cryptologos.cc/logos/ethereum-eth-logo.svg?v=035",
  metamask:  "https://upload.wikimedia.org/wikipedia/commons/3/36/MetaMask_Fox.svg",
  auth0:     "https://cdn.auth0.com/website/bob-away/media/press/auth0-badge.png",
};

const C = {
  navy:   "#0D2B4E",
  blue:   "#1A4A8A",
  mid:    "#1E6FA3",
  teal:   "#0F7B8C",
  green:  "#0F6B4A",
  border: "#B8CDE0",
  bg:     "#FFFFFF",
  band1:  "#F0F5FA",
  band2:  "#EBF4F8",
  band3:  "#E8F2EE",
  band4:  "#F5F0EB",
  text:   "#0D2B4E",
  sub:    "#4A6A8A",
  mono:   "'Courier New', monospace",
  serif:  "Georgia, serif",
};

function Box({ logo, fallback, title, subtitle, tag, tagColor = C.blue, width = 118, accent = C.blue, highlight = false }) {
  return (
    <div style={{
      width,
      background: highlight ? "#F0FFF8" : C.bg,
      border: `1px solid ${highlight ? "#0F6B4A" : C.border}`,
      borderTop: `3px solid ${accent}`,
      borderRadius: 4,
      padding: "10px 8px 9px",
      display: "flex",
      flexDirection: "column",
      alignItems: "center",
      gap: 5,
      flexShrink: 0,
      boxShadow: highlight ? `0 2px 8px ${accent}30` : "0 1px 3px rgba(0,0,0,0.07)",
    }}>
      <Logo src={logo} fallback={fallback} size={26} />
      <div style={{ textAlign: "center" }}>
        <div style={{ fontSize: "0.72rem", fontWeight: 700, color: C.text, lineHeight: 1.25, fontFamily: C.serif }}>
          {title}
        </div>
        {subtitle && (
          <div style={{ fontSize: "0.6rem", color: C.sub, fontFamily: C.mono, marginTop: 3, lineHeight: 1.3 }}>
            {subtitle}
          </div>
        )}
      </div>
      {tag && (
        <span style={{
          fontSize: "0.55rem", fontFamily: C.mono, fontWeight: 700,
          background: tagColor + "18", color: tagColor,
          padding: "1px 6px", borderRadius: 3, letterSpacing: "0.05em",
        }}>{tag}</span>
      )}
      {highlight && (
        <span style={{
          fontSize: "0.5rem", fontFamily: C.mono, fontWeight: 700,
          background: "#0F6B4A18", color: "#0F6B4A",
          padding: "1px 6px", borderRadius: 3, letterSpacing: "0.05em",
        }}>NEW</span>
      )}
    </div>
  );
}

function Arrow({ label = "", vertical = false }) {
  if (vertical) return (
    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 2, margin: "2px 0" }}>
      <div style={{ width: 1.5, height: 20, background: C.border }} />
      <div style={{ width: 0, height: 0, borderLeft: "5px solid transparent", borderRight: "5px solid transparent", borderTop: `7px solid ${C.border}` }} />
    </div>
  );
  return (
    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", flexShrink: 0, gap: 3, padding: "0 2px" }}>
      {label && <div style={{ fontSize: "0.58rem", color: C.sub, fontFamily: C.mono, textAlign: "center", maxWidth: 52 }}>{label}</div>}
      <div style={{ display: "flex", alignItems: "center" }}>
        <div style={{ width: 22, height: 1.5, background: C.border }} />
        <div style={{ width: 0, height: 0, borderTop: "5px solid transparent", borderBottom: "5px solid transparent", borderLeft: `7px solid ${C.border}` }} />
      </div>
    </div>
  );
}

function Band({ label, sublabel, bg, accent, children, minHeight = 90 }) {
  return (
    <div style={{ display: "flex", minHeight, marginBottom: 1 }}>
      <div style={{
        width: 96, flexShrink: 0, background: accent,
        display: "flex", flexDirection: "column", alignItems: "center",
        justifyContent: "center", padding: "8px 6px", borderRadius: "4px 0 0 4px",
      }}>
        <div style={{
          color: "white", fontSize: "0.65rem", fontWeight: 700,
          fontFamily: C.mono, letterSpacing: "0.08em", textTransform: "uppercase",
          textAlign: "center", lineHeight: 1.35,
        }}>{label}</div>
        {sublabel && (
          <div style={{
            color: "rgba(255,255,255,0.55)", fontSize: "0.56rem",
            fontFamily: C.mono, textAlign: "center", marginTop: 4, lineHeight: 1.3,
          }}>{sublabel}</div>
        )}
      </div>
      <div style={{
        flex: 1, background: bg,
        border: `1px solid ${C.border}`, borderLeft: "none",
        borderRadius: "0 4px 4px 0",
        display: "flex", alignItems: "center",
        padding: "12px 16px", gap: 0, overflowX: "auto",
      }}>
        {children}
      </div>
    </div>
  );
}

function Step({ n, label, last }) {
  return (
    <div style={{ display: "flex", alignItems: "center" }}>
      <div style={{ textAlign: "center", width: 96, flexShrink: 0 }}>
        <div style={{
          width: 28, height: 28, borderRadius: "50%", background: C.navy,
          color: "white", fontSize: "0.7rem", fontWeight: 700, fontFamily: C.mono,
          display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto 5px",
        }}>{n}</div>
        <div style={{ fontSize: "0.68rem", color: C.text, lineHeight: 1.35, fontFamily: C.serif, fontWeight: 500 }}>
          {label}
        </div>
      </div>
      {!last && (
        <div style={{ display: "flex", alignItems: "center", margin: "0 4px", flexShrink: 0 }}>
          <div style={{ width: 18, height: 1.5, background: C.border }} />
          <div style={{ width: 0, height: 0, borderTop: "4px solid transparent", borderBottom: "4px solid transparent", borderLeft: `6px solid ${C.border}` }} />
        </div>
      )}
    </div>
  );
}

export default function Architecture() {
  return (
    <div style={{ fontFamily: C.serif, background: "#F0F4F8", minHeight: "100vh", padding: "2.5rem 1.5rem" }}>
      <div style={{ maxWidth: 1100, margin: "0 auto" }}>

        {/* Header */}
        <div style={{ borderBottom: `3px solid ${C.navy}`, paddingBottom: "1.1rem", marginBottom: "1.5rem" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-end", flexWrap: "wrap", gap: 12 }}>
            <div>
              <div style={{ fontSize: "0.6rem", letterSpacing: "0.3em", color: C.mid, fontFamily: C.mono, textTransform: "uppercase", marginBottom: 5 }}>
                Solution Architecture — Confidential
              </div>
              <div style={{ fontSize: "2rem", fontWeight: 700, color: C.navy, letterSpacing: "-0.02em", lineHeight: 1.1 }}>
                MediChain Pay
              </div>
              <div style={{ fontSize: "0.88rem", color: C.sub, marginTop: 4, fontStyle: "italic" }}>
                Blockchain-Powered Medicare & Medicaid Payment Acceleration
              </div>
            </div>
            <div style={{ textAlign: "right" }}>
              <div style={{ background: C.navy, color: "white", padding: "5px 12px", borderRadius: 4, fontSize: "0.68rem", fontFamily: C.mono, letterSpacing: "0.06em" }}>
                Solidity · Base Network · USDC · Auth0
              </div>
              <div style={{ fontSize: "0.6rem", color: "#9aaabb", fontFamily: C.mono, marginTop: 4 }}>
                v1.1 — 2026 · github.com/darnharris37/medichain-pay
              </div>
            </div>
          </div>
        </div>

        {/* Auth0 callout banner */}
        <div style={{
          background: "#F0FFF8",
          border: "1px solid #0F6B4A",
          borderLeft: "4px solid #0F6B4A",
          borderRadius: 4,
          padding: "10px 16px",
          marginBottom: "1rem",
          display: "flex",
          alignItems: "center",
          gap: "1rem",
          flexWrap: "wrap",
        }}>
          <Logo src={L.auth0} fallback="🔐" size={28} />
          <div>
            <div style={{ fontSize: "0.78rem", fontWeight: 700, color: "#0F6B4A", fontFamily: C.serif }}>
              Auth0 Healthcare CIAM — Newly Integrated
            </div>
            <div style={{ fontSize: "0.68rem", color: C.sub, fontFamily: C.mono, marginTop: 2 }}>
              HIPAA-compliant identity layer · MFA · SSO · Fine-Grained Authorization · Business Associate Agreement (BAA)
            </div>
          </div>
        </div>

        {/* Section Label */}
        <div style={{ fontSize: "0.58rem", letterSpacing: "0.22em", color: "#8A9BB0", fontFamily: C.mono, textTransform: "uppercase", marginBottom: 8 }}>
          Component Architecture
        </div>

        {/* LAYER 1 — CLIENT */}
        <Band label="Client Layer" sublabel="User Interfaces" bg={C.band1} accent={C.navy}>
          <Box logo={null} fallback="🏠" title="Home Health Agency" subtitle="Claim submitter" tag="Customer" tagColor={C.blue} accent={C.blue} />
          <Arrow label="HTTPS" />
          <Box logo={L.react} fallback="⚛️" title="Agency Portal" subtitle="React · Web3.js" tag="React" tagColor="#61DAFB" accent="#61DAFB" />
          <Arrow label="Signs tx" />
          <Box logo={L.metamask} fallback="🦊" title="MetaMask" subtitle="Wallet · Signing" tag="Web3" tagColor="#F6851B" accent="#F6851B" />
          <Arrow label="Reviews" />
          <Box logo={null} fallback="⚙️" title="Admin Dashboard" subtitle="Owner interface" tag="Internal" tagColor={C.blue} accent={C.blue} />
        </Band>

        {/* Vertical arrows */}
        <div style={{ display: "flex", paddingLeft: 96, gap: 0 }}>
          {[138, 48, 130, 48, 130, 48, 130].map((w, i) => (
            <div key={i} style={{ width: w, flexShrink: 0, display: "flex", justifyContent: "center" }}>
              {i % 2 === 0 && <Arrow vertical />}
            </div>
          ))}
        </div>

        {/* LAYER 2 — IDENTITY (NEW) */}
        <Band label="Identity Layer" sublabel="Auth0 CIAM" bg="#F0FFF8" accent="#0F6B4A">
          <Box logo={L.auth0} fallback="🔐" title="Auth0 Login" subtitle="Universal Login · SSO" tag="CIAM" tagColor="#0F6B4A" accent="#0F6B4A" highlight={true} />
          <Arrow label="Verifies" />
          <Box logo={null} fallback="🔑" title="Multi-Factor Auth" subtitle="TOTP · SMS · Email" tag="MFA" tagColor="#0F6B4A" accent="#0F6B4A" highlight={true} />
          <Arrow label="Assigns" />
          <Box logo={null} fallback="👤" title="Role Management" subtitle="Agency · Admin · Auditor" tag="RBAC" tagColor="#0F6B4A" accent="#0F6B4A" highlight={true} />
          <Arrow label="HIPAA" />
          <Box logo={null} fallback="📋" title="BAA / Compliance" subtitle="HIPAA · SMART on FHIR" tag="Compliance" tagColor="#0F6B4A" accent="#0F6B4A" highlight={true} />
        </Band>

        {/* Vertical arrows */}
        <div style={{ display: "flex", paddingLeft: 96, gap: 0 }}>
          {[138, 48, 130, 48, 130, 48, 130].map((w, i) => (
            <div key={i} style={{ width: w, flexShrink: 0, display: "flex", justifyContent: "center" }}>
              {i % 2 === 0 && <Arrow vertical />}
            </div>
          ))}
        </div>

        {/* LAYER 3 — MIDDLEWARE */}
        <Band label="Middleware" sublabel="Integration & APIs" bg={C.band2} accent={C.blue}>
          <Box logo={null} fallback="🔗" title="Availity API" subtitle="Claim validation · ERA" tag="REST" tagColor={C.mid} accent={C.mid} />
          <Arrow label="Validates" />
          <Box logo={null} fallback="🛡️" title="KYB / BAA" subtitle="Agency onboarding" tag="Legal" tagColor={C.mid} accent={C.mid} />
          <Arrow label="Triggers" />
          <Box logo={L.chainlink} fallback="⛓️" title="Chainlink Oracle" subtitle="Automated repayment" tag="Oracle" tagColor="#375BD2" accent="#375BD2" />
          <Arrow label="ERA / 835" />
          <Box logo={null} fallback="🏛️" title="CMS / Medicaid" subtitle="Payer remittance" tag="Federal" tagColor={C.blue} accent={C.blue} />
        </Band>

        {/* Vertical arrows */}
        <div style={{ display: "flex", paddingLeft: 96, gap: 0 }}>
          {[138, 48, 130, 48, 130, 48, 130].map((w, i) => (
            <div key={i} style={{ width: w, flexShrink: 0, display: "flex", justifyContent: "center" }}>
              {i % 2 === 0 && <Arrow vertical />}
            </div>
          ))}
        </div>

        {/* LAYER 4 — SMART CONTRACT */}
        <Band label="Smart Contract" sublabel="On-Chain Logic" bg={C.band3} accent={C.teal}>
          <Box logo={L.eth} fallback="📄" title="MediChainPay.sol" subtitle="Solidity · Escrow" tag="Solidity" tagColor="#627EEA" accent="#627EEA" />
          <Arrow label="Advances" />
          <Box logo={L.usdc} fallback="💵" title="USDC Token" subtitle="ERC-20 · Circle" tag="ERC-20" tagColor="#2775CA" accent="#2775CA" />
          <Arrow label="Emits events" />
          <Box logo={null} fallback="📋" title="Claim Escrow" subtitle="Reserve · Clawback" tag="State" tagColor={C.teal} accent={C.teal} />
          <Arrow label="Logged" />
          <Box logo={null} fallback="📊" title="On-Chain Audit" subtitle="Immutable ledger" tag="Compliance" tagColor={C.teal} accent={C.teal} />
        </Band>

        {/* Vertical arrows */}
        <div style={{ display: "flex", paddingLeft: 96, gap: 0 }}>
          {[138, 48, 130, 48, 130, 48, 130].map((w, i) => (
            <div key={i} style={{ width: w, flexShrink: 0, display: "flex", justifyContent: "center" }}>
              {i % 2 === 0 && <Arrow vertical />}
            </div>
          ))}
        </div>

        {/* LAYER 5 — BLOCKCHAIN INFRA */}
        <Band label="Blockchain Infra" sublabel="Base Network · L2" bg={C.band4} accent="#0D4A7A">
          <Box logo={L.base} fallback="🔵" title="Base Network" subtitle="Coinbase L2 · EVM" tag="L2" tagColor="#0052FF" accent="#0052FF" />
          <Arrow label="Confirms" />
          <Box logo={null} fallback="🔗" title="Consensus Layer" subtitle="Block validation" tag="PoS" tagColor="#0D4A7A" accent="#0D4A7A" />
          <Arrow label="Distributed" />
          <Box logo={null} fallback="💾" title="Distributed Ledger" subtitle="Permanent state" tag="Immutable" tagColor="#0D4A7A" accent="#0D4A7A" />
          <Arrow label="Indexed" />
          <Box logo={L.base} fallback="🔍" title="Basescan" subtitle="Block explorer" tag="Explorer" tagColor="#0052FF" accent="#0052FF" />
        </Band>

        {/* Divider */}
        <div style={{ borderTop: `1px solid ${C.border}`, margin: "1.6rem 0 1.1rem" }} />

        {/* Section Label */}
        <div style={{ fontSize: "0.58rem", letterSpacing: "0.22em", color: "#8A9BB0", fontFamily: C.mono, textTransform: "uppercase", marginBottom: 12 }}>
          End-to-End Claim Lifecycle
        </div>

        {/* Flow Steps */}
        <div style={{
          background: C.bg, border: `1px solid ${C.border}`, borderRadius: 6,
          padding: "16px 20px", display: "flex", alignItems: "flex-start",
          overflowX: "auto", boxShadow: "0 1px 3px rgba(0,0,0,0.05)", marginBottom: "1.4rem",
        }}>
          {[
            "Agency logs in via Auth0",
            "MFA verified",
            "Claim submitted",
            "Clearinghouse validates",
            "Owner approves",
            "85% USDC advanced",
            "5% held in escrow",
            "CMS remits",
            "Principal + fee collected",
            "Reserve released 180d",
          ].map((label, i, arr) => (
            <Step key={i} n={String(i + 1).padStart(2, "0")} label={label} last={i === arr.length - 1} />
          ))}
        </div>

        {/* Auth0 Feature Breakdown */}
        <div style={{
          background: "#F0FFF8",
          border: "1px solid #0F6B4A",
          borderRadius: 6,
          padding: "1.1rem 1.25rem",
          marginBottom: "1.4rem",
        }}>
          <div style={{ fontSize: "0.62rem", letterSpacing: "0.2em", color: "#0F6B4A", fontFamily: C.mono, textTransform: "uppercase", marginBottom: "0.85rem", fontWeight: 700 }}>
            Auth0 Healthcare CIAM — Feature Breakdown
          </div>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))", gap: "0.75rem" }}>
            {[
              { icon: "🔐", title: "Universal Login", desc: "Branded login page for all agency users" },
              { icon: "📱", title: "Multi-Factor Auth", desc: "TOTP, SMS, email — required for HIPAA" },
              { icon: "🔄", title: "Single Sign-On", desc: "Connect to Epic, Cerner, Homecare Homebase" },
              { icon: "👥", title: "Role Management", desc: "Agency Admin, Staff, Auditor, Owner" },
              { icon: "📋", title: "HIPAA BAA", desc: "Business Associate Agreement available" },
              { icon: "🤖", title: "AI Agent Auth", desc: "Secure automated agent identity (Phase 4)" },
            ].map((f, i) => (
              <div key={i} style={{
                background: "white",
                border: "1px solid #B8E8D0",
                borderRadius: 4,
                padding: "0.75rem",
              }}>
                <div style={{ display: "flex", alignItems: "center", gap: "0.5rem", marginBottom: "0.3rem" }}>
                  <span style={{ fontSize: "1rem" }}>{f.icon}</span>
                  <span style={{ fontSize: "0.75rem", fontWeight: 700, color: "#0F6B4A", fontFamily: C.serif }}>{f.title}</span>
                </div>
                <div style={{ fontSize: "0.65rem", color: C.sub, fontFamily: C.mono, lineHeight: 1.4 }}>{f.desc}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Key Metrics */}
        <div style={{ display: "grid", gridTemplateColumns: "repeat(5, 1fr)", gap: 10, marginBottom: "1.5rem" }}>
          {[
            { v: "85%", l: "Advance Rate" },
            { v: "5%", l: "Reserve Escrow" },
            { v: "1.5%", l: "Platform Fee" },
            { v: "180d", l: "Reserve Window" },
            { v: "HIPAA", l: "Auth0 Compliant" },
          ].map((m, i) => (
            <div key={i} style={{
              background: i === 4 ? "#0F6B4A" : C.navy,
              borderRadius: 4, padding: "12px",
              textAlign: "center", boxShadow: "0 1px 3px rgba(0,0,0,0.1)",
            }}>
              <div style={{ fontSize: "1.5rem", fontWeight: 700, color: "white", lineHeight: 1, marginBottom: 4 }}>{m.v}</div>
              <div style={{ fontSize: "0.6rem", color: "rgba(255,255,255,0.5)", letterSpacing: "0.12em", fontFamily: C.mono, textTransform: "uppercase" }}>{m.l}</div>
            </div>
          ))}
        </div>

        {/* Tech Stack Legend */}
        <div style={{
          background: C.bg, border: `1px solid ${C.border}`, borderRadius: 6,
          padding: "12px 16px", display: "flex", alignItems: "center",
          gap: 20, flexWrap: "wrap", marginBottom: "1.4rem",
        }}>
          <div style={{ fontSize: "0.6rem", letterSpacing: "0.18em", color: "#8A9BB0", fontFamily: C.mono, textTransform: "uppercase", flexShrink: 0 }}>
            Tech Stack
          </div>
          {[
            { src: L.auth0,     fallback: "🔐", label: "Auth0" },
            { src: L.eth,       fallback: "📄", label: "Solidity" },
            { src: L.base,      fallback: "🔵", label: "Base Network" },
            { src: L.usdc,      fallback: "💵", label: "USDC" },
            { src: L.chainlink, fallback: "⛓️", label: "Chainlink" },
            { src: L.react,     fallback: "⚛️", label: "React" },
            { src: L.metamask,  fallback: "🦊", label: "MetaMask" },
          ].map((t, i) => (
            <div key={i} style={{ display: "flex", alignItems: "center", gap: 5 }}>
              <Logo src={t.src} fallback={t.fallback} size={18} />
              <span style={{ fontSize: "0.72rem", color: C.text, fontFamily: C.mono, fontWeight: 600 }}>{t.label}</span>
            </div>
          ))}
        </div>

        {/* Footer */}
        <div style={{ borderTop: `1px solid ${C.border}`, paddingTop: 10, display: "flex", justifyContent: "space-between", flexWrap: "wrap", gap: 6 }}>
          <div style={{ fontSize: "0.62rem", color: "#A0B4C5", fontFamily: C.mono }}>
            MediChain Pay — Confidential Project Roadmap · Built by a Home Health Agency Owner
          </div>
          <div style={{ fontSize: "0.62rem", color: "#A0B4C5", fontFamily: C.mono }}>
            github.com/darnharris37/medichain-pay
          </div>
        </div>

      </div>
    </div>
  );
}
