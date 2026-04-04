---
name: journey-qa-ac-testing
description: >
  Journey-first manual QA that validates real user flows against journey scenarios
  and mapped acceptance criteria. Use when the user says "run QA by journey",
  "validate journeys", "manual QA pass", "regression pass", "smoke test with ACs",
  or "verify this flow on staging/local/prod". This skill verifies runtime behavior
  at any reachable URL (localhost, preview, staging, production), captures evidence,
  and writes QA status back to feature spec AC tables.
inputs:
  required:
    - { path: "docs/specs/journeys/J*.feature.md", artifact: journey-docs }
    - { path: "docs/specs/features/<name>.md", artifact: feature-spec }
  optional: []
outputs:
  produces:
    - { path: "docs/specs/features/<name>.md", artifact: qa-updated-spec }
chain:
  lanes: {}
  progressive: false
  self_verify: true
  human_checkpoint: false
---

# Journey QA AC Testing

## Purpose

Run agentic manual QA the way real QA teams operate:

1. Start from user journeys (`docs/specs/journeys/*.feature.md`)
2. Execute runtime flows at a target environment
3. Validate linked acceptance criteria in feature specs
4. Save evidence and update QA status in AC tables

This skill is manual/agentic QA, not test-file generation.

---

## Scope and Inputs

Required input:
- `target_url`: any reachable app URL (`http://localhost:3000`, preview URL, staging, prod)

Optional inputs:
- `env=local|preview|staging|prod|custom` (reporting label only)
- `mode=smoke|regression|feature-ac|exploratory`
- `journey=<journey-id-or-file>`
- `feature=<feature-spec-file>`

Environment policy:
- Do not assume "live-only". Test whichever URL the user provided.
- Record `target_url` and `env` in every run summary.

---

## Repository Mode Gate

Detect mode from `REPO_MODES.md` before running:

- `bootstrap`: if journey/spec structure is missing, route to `journey-sync` and/or
  `spec-ac-sync` first.
- `convert`: adapt to existing file naming/layout and preserve current conventions.

If ambiguous, default to `convert`.

---

## Prerequisites

Before testing:

1. Journey docs exist: `docs/specs/journeys/*.feature.md`
2. Feature specs exist: `docs/specs/features/*.md`
3. AC tables use the standard format:
   `| AC | Description | QA | E2E | Test |`

If AC tables are missing or malformed, run `spec-ac-sync` first.

---

## Core Modes

### 1) `smoke`

Run only critical paths for selected journeys:
- Auth/session entry
- Primary user action
- Success state visibility
- Critical failure guardrail

Use for fast confidence after deploy or risky merges.

### 2) `regression`

Run full journey scenarios and all mapped ACs for selected scope.

Use for release readiness or wide-impact changes.

### 3) `feature-ac`

Run AC-focused QA for one feature spec while still executing through journey flow
contexts (not isolated clicks).

Use when a team asks for "verify feature X against spec".

### 4) `exploratory`

Run unscripted, risk-guided QA around journey transitions and edge states.
Record discovered gaps and route them to the right skill.

**Exploratory testing patterns** (run through each in the browser):

| Pattern | What to try | Looking for |
|---------|------------|-------------|
| **Boundary values** | Min/max lengths, zero, negative, huge numbers | Crashes, truncation, overflow |
| **Empty states** | Fresh account, no data, cleared filters | Missing empty state UI, errors |
| **Rapid actions** | Double-click submit, rapid navigation, back/forward | Duplicate submissions, race conditions |
| **Invalid input** | SQL injection, XSS payloads, Unicode, emoji, RTL text | Security holes, encoding bugs |
| **Interruption** | Refresh mid-form, close tab mid-upload, network offline | Lost data, stuck states |
| **Permission edges** | Access URLs directly without auth, tamper with IDs in URL | Auth bypass, IDOR |
| **Responsive** | Resize to mobile/tablet/desktop breakpoints | Broken layout, unreachable elements |
| **Accessibility** | Tab through all interactive elements, screen reader flow | Missing focus indicators, broken tab order |
| **State persistence** | Refresh page, navigate away and back, close and reopen | Lost form data, reset state |
| **Concurrency** | Open same page in two tabs, edit same resource | Conflicts, stale data |

For each discovered issue, record:
- What you tried (exact steps)
- What happened (screenshot)
- What should have happened (from spec/journey/common sense)
- Severity: Critical / High / Medium / Low

---

## Execution Workflow

### Step 1: Select Journey Scope

- Load target journey docs.
- Extract scenarios and expected outcomes.
- For each scenario, identify mapped AC IDs from related feature specs.

If mapping is missing, create a gap note and continue with explicit assumptions.

### Step 2: Preflight Target Environment

Validate:
- `target_url` reachable
- authentication path usable for the scenario
- required test data/state available

If preflight fails, stop with a concise blocker report.

### Step 3: Execute Scenario Runtime Flow (Real Browser)

Use a real browser for all testing. Preferred tools in order:
1. **Playwright MCP** (`browser_navigate`, `browser_click`, `browser_snapshot`, `browser_take_screenshot`) — if available
2. **Browse tool** (if gstack `/browse` is installed) — persistent headless Chromium
3. **Manual browser** — instruct user to perform actions, describe what they see

For each scenario:

**Navigate and interact like a real user:**
```
browser_navigate → target_url
browser_snapshot → capture initial state
browser_click → interact with elements (buttons, links, forms)
browser_fill_form → enter test data
browser_take_screenshot → evidence for each step
```

**Verify observable outcomes:**
- Page content matches expected state from journey Given/When/Then
- Error states render correctly (not raw stack traces)
- Loading states appear and resolve
- Empty states show correct messaging
- Navigation flows match UX design

**Capture evidence for each AC:**
- Screenshot per AC verification (PASS or FAIL)
- Console errors captured via `browser_console_messages`
- Network failures captured via `browser_network_requests`

For non-UI-testable ACs (background jobs, data integrity), use code inspection as fallback.

### Step 4: Update Feature Specs (Source of Truth)

Write QA column statuses in AC tables:
- `✅ MM-DD`
- `✅ MM-DD (code) path:line`
- `❌ MM-DD`
- `⚠️ MM-DD`
- `⏭️ reason`
- `—`

For failures, add bug blockquotes directly under the relevant AC section.

### Step 5: Save Evidence and Summary

Evidence path:
- `docs/specs/features/test-evidence/{YYYY-MM-DD}-{env}-{journey-or-feature}/`

Summary output must include:
- target URL + env
- mode
- pass/fail counts by journey and by feature AC table
- unresolved blockers and routed follow-ups

---

## Routing Rules

Route findings automatically:

- Missing ACs or vague AC wording -> `spec-ac-sync`
- Missing/incorrect journey transitions -> `journey-sync`
- Spec-vs-code contradictions -> `spec-code-sync`
- Stable validated flow ready for automation -> `agentic-e2e-playwright`

---

## Guardrails

1. Do not create separate QA truth docs when feature specs already hold AC status.
2. Keep bug blockquotes current: remove them after re-verification passes.
3. Do not mark AC `✅` without evidence or explicit code verification reference.
4. Keep environment details explicit so results are reproducible.

---

## Relationship to E2E

- `journey-qa-ac-testing`: manual/agentic runtime verification and evidence.
- `agentic-e2e-playwright`: durable automated tests after flows are validated.

Recommended sequence:
1. `journey-qa-ac-testing`
2. Fix defects
3. `agentic-e2e-playwright`

## Pipeline Continuation

### Self-Verify

Before declaring done, verify:

| # | Check | How | PASS/FAIL |
|---|-------|-----|-----------|
| 1 | QA column in AC tables updated | grep for QA status markers in `docs/specs/features/<name>.md` | |
| 2 | Evidence captured | `test -d docs/specs/features/test-evidence/` and evidence files exist | |
| 3 | No unresolved questions | grep for TBD, TODO, open questions in updated specs | |

If any check FAILs, fix before continuing. If a fix requires upstream changes, stop and report.

### Chaining

**If `--progressive` flag is absent:**
- Report results to user
- Suggest: "Next: consider running `agentic-e2e-playwright` for stable validated flows"

Not part of progressive chains (invoked standalone or by verifying-promotion).
