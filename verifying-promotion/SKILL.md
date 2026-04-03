---
name: verifying-promotion
description: Use after a change set has been promoted (PROMOTED status) to verify the implementation matches specs, passes tests, and satisfies acceptance criteria — triggers G7 review
---

# Verifying Promotion

## Overview

Verification is the final phase. It proves that the promoted code matches
the specs, passes all tests, and satisfies every acceptance criterion. This
skill orchestrates existing verification skills and triggers the G7 review
gate to transition the feature from PROMOTED → VERIFIED.

```
promoting-change-set   → PROMOTED (code applied, deviations checked)
verifying-promotion    → VERIFIED (tests pass, specs synced, QA complete)
```

**Announce at start:** "I'm using the verifying-promotion skill to verify the promoted change set."

## What This Skill Orchestrates

Verification is not one check — it is four verification passes that together
prove the implementation is correct:

| Pass | Skill | What It Checks |
|------|-------|---------------|
| 1. Spec-code sync | `spec-code-sync` | PLANNED items → RESOLVED with file:line proof. Detects DRIFT. |
| 2. AC audit | `spec-ac-sync` | All ACs are specific, testable, and reflect current implementation. |
| 3. Journey QA | `journey-qa-ac-testing` | Journey scenarios pass against the live environment. QA column updated. |
| 4. E2E tests | `agentic-e2e-playwright` | Automated E2E tests pass. E2E column updated. Test column has file refs. |

Each pass updates the feature spec's AC table. After all four passes, every
AC should have QA and E2E columns filled.

## Prerequisites

| Artifact | Where | Required? |
|----------|-------|-----------|
| Feature spec (PROMOTED) | `docs/specs/features/<name>.md` | Yes — status must be PROMOTED |
| Change set | `docs/plans/<date>-<name>/manifest.md` | Yes — for reference |
| Promotion deviation report | From promoting-change-set | Yes — must show G6 passed |
| Live environment | localhost / preview / staging | Yes — for QA and E2E |

**Gate:** Do not start verification without PROMOTED status. If the feature
is not yet promoted, route to `promoting-change-set`.

## Process

### Step 1: Read The Feature Spec And Change Set

Read the feature spec and the change set manifest. Identify:
- All acceptance criteria (AC table)
- All PLANNED implementation notes
- All journey references
- All files that were created or modified

### Step 2: Run spec-code-sync

Invoke `spec-code-sync` on the feature spec.

**Expected outcomes:**
- PLANNED items that were implemented → marked RESOLVED with file:line proof
- Items that were implemented differently → marked DRIFT
- Items that were removed → marked REVERTED

**If DRIFT or REVERTED found:** These are findings for the G7 review. Do not
fix them here — log them.

### Step 3: Run spec-ac-sync

Invoke `spec-ac-sync` on the feature spec.

**Expected outcomes:**
- ACs are complete and testable
- New ACs added if implementation revealed edge cases not covered
- Compound ACs split
- AC table format is correct

### Step 4: Run journey-qa-ac-testing

Invoke `journey-qa-ac-testing` in regression mode against the live environment.

**Expected outcomes:**
- Journey scenarios execute successfully
- QA column in AC table updated (✅ / ❌ / ⚠️)
- Evidence screenshots saved to `docs/specs/features/test-evidence/`
- Failed scenarios logged as findings

**If no live environment available:** Use smoke mode against localhost, or
mark QA as `⏭️ no env` and note in findings.

### Step 5: Run agentic-e2e-playwright

Invoke `agentic-e2e-playwright` to verify automated tests pass.

**Expected outcomes:**
- All E2E tests from the change set pass
- E2E column in AC table updated (✅ / ❌)
- Test column has file:line references
- Failed tests logged as findings

**If E2E tests were not part of the change set** (e.g., Enabler with no UI):
Mark E2E as `⛔ not applicable` with reason.

### Step 6: Compile Verification Report

```markdown
# Verification Report

**Feature:** <feature-name>
**Spec:** docs/specs/features/<name>.md
**Verified:** <timestamp>

## spec-code-sync Results

| Status | Count |
|--------|-------|
| RESOLVED | N |
| DRIFT | N |
| REVERTED | N |
| Still PLANNED | N |

## AC Coverage

| Total ACs | QA ✅ | QA ❌ | E2E ✅ | E2E ❌ | Untested |
|-----------|-------|-------|--------|--------|----------|
| N | N | N | N | N | N |

## Journey QA Results

| Journey | Scenarios Passed | Scenarios Failed |
|---------|-----------------|-----------------|
| J05: ... | N | N |

## E2E Test Results

| Test File | Tests Passed | Tests Failed |
|-----------|-------------|-------------|
| e2e/specs/... | N | N |

## Findings

### VER-001: [description]
**Severity:** [critical/high/medium/low]
**Source:** [spec-code-sync / journey-qa / e2e]
**Details:** ...
```

### Step 7: Trigger G7 Review

Enter the review protocol at Gate G7 with the verification report.

**G7 checks:**
- Zero DRIFT or REVERTED annotations (or justified exceptions)
- All ACs have QA and/or E2E coverage
- All journey scenarios pass (or justified skips)
- All E2E tests pass
- No critical/high findings remain

**If G7 passes:** Feature spec status → VERIFIED

**If G7 fails:** Findings become fix tasks. Fixes go through a new change
set (writing-change-set → promoting-change-set → verifying-promotion).

### Step 8: Update Feature Spec Status

```markdown
**Status:** VERIFIED
```

Add verification metadata:

```markdown
## Verification Record

**Verified:** <timestamp>
**spec-code-sync:** N RESOLVED, 0 DRIFT
**AC coverage:** N/N QA, N/N E2E
**Journey QA:** N/N scenarios passed
**E2E tests:** N/N passed
```

### Step 9: Completion

The feature is VERIFIED. Present a summary:

```
Feature verified: <feature-name>
Status: VERIFIED
AC coverage: N/N with QA, N/N with E2E
Spec-code sync: N RESOLVED, 0 DRIFT
Journey QA: N/N scenarios passed
E2E tests: N/N passed

The feature development lifecycle is complete.
```

## Feedback Loops

| Discovery | Action |
|-----------|--------|
| DRIFT found by spec-code-sync | Decision: fix code to match spec, or update spec to match code |
| Journey scenario fails | Fix code or update journey if the scenario was wrong |
| E2E test fails | Fix code — tests were written against approved ACs |
| AC not coverable by E2E | Mark as manual QA only, with justification |
| Still-PLANNED items | Either implementation was missed (re-promote) or spec was wrong (update spec) |

## Anti-Patterns

| Don't | Why | Instead |
|-------|-----|---------|
| Skip spec-code-sync | PLANNED items stay unverified forever | Always run it — it catches what tests miss |
| Mark everything ⏭️ | Defeats verification purpose | Only skip with specific justification |
| Fix bugs during verification | Creates unreviewed changes | Bugs found → new change set through the pipeline |
| Run E2E without spec-code-sync first | Tests may pass against drifted implementation | spec-code-sync first, then tests |

## Routing

| Situation | Route to |
|-----------|----------|
| G7 passed, feature VERIFIED | Done — or `feature-marketing-insights` if marketing context needed |
| G7 failed, code bugs | `writing-change-set` (new fix change set) |
| G7 failed, spec wrong | `writing-spec` (revise spec, re-run pipeline) |
| Feature not yet PROMOTED | `promoting-change-set` |
| Change set not yet approved | `writing-change-set` + `review-protocol` G5 |
