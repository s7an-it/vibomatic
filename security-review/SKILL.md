---
name: security-review
description: >
  OWASP Top 10 + STRIDE threat model + supply chain audit of the technical
  design before implementation. Use when "security review", "check for
  vulnerabilities", "threat model", "audit security", or automatically in
  progressive mode after writing-technical-design for features with auth,
  payments, user data, or external integrations.
inputs:
  required:
    - { path: "docs/specs/features/<name>.md", artifact: feature-spec }
  optional:
    - { path: "docs/specs/domain-profile.md", artifact: domain-profile }
outputs:
  produces:
    - { path: "docs/specs/security/<name>-review.md", artifact: security-review }
chain:
  lanes: {}
  progressive: false
  self_verify: true
  human_checkpoint: false
---

# Security Review

Security audit of the technical design before any code is written.
Catches vulnerabilities at the architecture level where they're cheapest to fix.

Blended from gstack /cso patterns. Adapted for vibomatic's spec-first pipeline.

**Announce at start:** "I'm using security-review to audit the design for security risks."

## When To Run

**Always** for features that touch:
- Authentication or authorization
- Payment processing
- Personal data (PII, health, financial)
- External API integrations
- File uploads
- Admin/elevated privilege paths

**Skip** for:
- Pure UI cosmetic changes
- Documentation updates
- Internal tooling with no user-facing surface

## Process

### Step 1: OWASP Top 10 Check

Walk through each OWASP category against the technical design:

| # | Category | Check against design |
|---|----------|---------------------|
| A01 | Broken Access Control | Are all endpoints auth-gated? Role checks on every mutation? |
| A02 | Cryptographic Failures | Passwords hashed? Tokens rotated? Secrets in env vars not code? |
| A03 | Injection | All user input parameterized? No string concatenation in queries? |
| A04 | Insecure Design | Threat model exists? Abuse cases considered? Rate limiting? |
| A05 | Security Misconfiguration | CORS locked down? Debug mode off? Default creds removed? |
| A06 | Vulnerable Components | Dependencies up to date? Known CVEs checked? |
| A07 | Auth Failures | Session management sound? MFA considered? Brute force protection? |
| A08 | Data Integrity Failures | Input validation on all boundaries? CSRF protection? |
| A09 | Logging & Monitoring | Security events logged? Alerting on suspicious patterns? |
| A10 | SSRF | External URL inputs validated? Internal network access blocked? |

For each category: PASS, FAIL (with specific finding), or N/A.

### Step 2: STRIDE Threat Model

For each component in the technical design:

| Threat | Question |
|--------|---------|
| **S**poofing | Can an attacker impersonate a user or service? |
| **T**ampering | Can data be modified in transit or at rest? |
| **R**epudiation | Can actions be performed without accountability? |
| **I**nformation Disclosure | Can sensitive data leak through logs, errors, or side channels? |
| **D**enial of Service | Can the service be overwhelmed? Rate limiting in place? |
| **E**levation of Privilege | Can a regular user gain admin access? |

### Step 3: Supply Chain Audit

Check dependencies:
```bash
# Node.js
npm audit
# Python
pip-audit or safety check
# Go
govulncheck
# Rust
cargo audit
```

Flag: outdated dependencies, known CVEs, packages with suspicious maintainer changes.

### Step 4: Secrets Archaeology

Scan for leaked credentials:
```bash
grep -rn "password\|secret\|api_key\|token\|credential" src/ --include="*.ts" --include="*.py" --include="*.go" | grep -v "test\|mock\|example"
```

Check `.env.example` exists (not `.env` committed). Check `.gitignore` has secrets patterns.

### Output: `docs/specs/security/<feature-name>-review.md`

```markdown
# Security Review: <feature name>

**Date:** <timestamp>
**Reviewer:** P0 (automated) or human

## OWASP Top 10
| Category | Status | Finding |
|----------|--------|---------|
| A01 Broken Access Control | PASS/FAIL | <detail> |
| ... | ... | ... |

## STRIDE Threat Model
| Component | S | T | R | I | D | E |
|-----------|---|---|---|---|---|---|
| API layer | ✅ | ⚠️ | ✅ | ❌ | ✅ | ✅ |
| ... | ... | ... | ... | ... | ... | ... |

## Supply Chain
- Dependencies: <count>
- Known CVEs: <count>
- Outdated: <count>

## Secrets
- Leaked credentials found: yes/no
- .env in .gitignore: yes/no

## Verdict
- [ ] PASS — no Critical/High findings
- [ ] CONDITIONAL — High findings that need mitigation
- [ ] FAIL — Critical findings, do not proceed to implementation
```

## Pipeline Continuation

### Self-Verify

| # | Check | How | PASS/FAIL |
|---|-------|-----|-----------|
| 1 | Review report exists | `test -f docs/specs/security/<name>-review.md` | |
| 2 | OWASP section complete | all 10 categories have a status | |
| 3 | No Critical unresolved | grep for Critical + FAIL | |

### Chaining

Standalone skill — not in progressive chains by default. Invoke between
`writing-technical-design` and `writing-change-set` for security-sensitive features.
