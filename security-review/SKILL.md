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

## Confidence Gate

Every finding MUST include a confidence score from 1 to 10. The gate filters
noise before it reaches the report.

| Score | Meaning | Action |
|-------|---------|--------|
| 9-10 | Verified by reading specific code; concrete exploit demonstrated | Show normally |
| 7-8 | High-confidence pattern match against known vulnerability class | Show normally |
| 5-6 | Moderate; could be a false positive | Show with explicit caveat |
| 3-4 | Low confidence; pattern present but context unclear | Suppress from main report; appendix only |
| 1-2 | Speculation or theoretical-only | Only report if severity would be P0 |

**Default mode:** 8/10 gate (zero noise). Only findings scored 8+ appear in the
main report. This is the right default for most reviews.

**Comprehensive mode:** 2/10 gate. Use when the feature handles payments,
medical data, or other high-consequence domains where a miss costs more than
noise. Invoke with `--comprehensive` or when the feature spec indicates P0
data sensitivity.

## Parallel Finding Verification

For each candidate finding above the confidence gate:

1. **Launch independent verification** with fresh context. The verifier reads
   only the code/spec references cited by the finding — not the finding itself.
2. The verifier produces its own confidence score and exploit path.
3. **Discard** any finding where the verifier scores it below the active
   confidence gate.
4. If the verifier confirms but at a lower score, use the lower score.

This eliminates findings that look plausible in context but don't survive
independent scrutiny.

## Key Rules

- **Think like an attacker, report like a defender** — show the exploit path,
  then the fix.
- **Zero noise > zero misses** — 3 real findings beats 3 real + 12 theoretical.
- **Every finding MUST include a concrete exploit scenario** — step-by-step
  attack path, not "an attacker could potentially..."
- **Read-only** — never modify code. Produce findings and recommendations only.

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

#### Specific Checks Per Category

**A01 — Broken Access Control:**
- Missing auth middleware on controllers/routes (grep for unprotected handlers)
- Direct object reference: can user A access user B's resource by changing an ID?
- Horizontal privilege escalation: same role, different tenant/org
- Vertical privilege escalation: regular user accessing admin endpoints
- Verify authorization checks happen server-side, not just UI hiding

**A03 — Injection:**
- SQL injection: raw queries, string interpolation in SQL (`${var}`, `f"...{var}..."`, `+ var +`)
- Command injection: `system()`, `exec()`, `spawn()`, `child_process` with user input
- Template injection: user input rendered in server-side templates without escaping
- LLM prompt injection: user-controlled text concatenated into system prompts or tool calls
- NoSQL injection: `$where`, `$regex`, unvalidated query operators

**A05 — Security Misconfiguration:**
- CORS: wildcard `*` origins in production (check for `Access-Control-Allow-Origin: *`)
- CSP headers: missing or overly permissive `Content-Security-Policy`
- Debug mode enabled in production (`DEBUG=true`, `NODE_ENV=development`, verbose error pages)
- Default credentials or API keys shipped in config files
- Unnecessary ports/services exposed

**A07 — Authentication Failures:**
- JWT: missing or excessive expiration (`exp` claim), no refresh token rotation
- MFA: required for admin paths? Bypassable via API?
- Password reset: rate-limited? Token single-use? Expires?
- Session fixation: new session ID issued on login?

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

### False Positive Exclusions

Do NOT report findings in these categories — they generate noise without
actionable signal:

1. **DoS / resource exhaustion** — unless it's LLM cost amplification, which is
   a financial risk (not DoS). A single prompt that triggers $500 in API calls
   is a real finding.
2. **Secrets on disk** if the file is encrypted and has correct file permissions
   (0600 or stricter, owned by service user).
3. **Input validation on non-security-critical fields** without a proven impact
   chain. "Username allows unicode" is not a finding unless it enables injection.
4. **Race conditions** unless concretely exploitable with a step-by-step
   scenario. "Two requests could theoretically interleave" is not enough.
5. **Vulnerabilities in outdated dependencies** — handled by the supply chain
   phase (Step 3), not as individual findings. Don't double-count.
6. **Missing hardening** — flag actual vulnerabilities, not absent best
   practices. "No rate limiting on /health" is not a finding.
7. **Files that are only test fixtures** — `test/fixtures/`, mock data,
   `*.test.*` files. Unless the fixture is deployed to production.
8. **Regex complexity** in code that does not process untrusted input. Internal
   config parsing with complex regex is not ReDoS.
9. **Security concerns in documentation files** — EXCEPTION: `SKILL.md` files
   are executable prompt code and MUST be reviewed for prompt injection.
10. **Git history secrets** committed AND removed in the same PR. The secret
    never reached a long-lived branch.

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
