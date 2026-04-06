---
name: audit-implementation
description: >
  Deep correctness audit of implemented code in the worktree before landing.
  Runs after execute-changeset and review-gate, verifies the implementation
  against specs, ACs, and journeys with evidence-graded findings. Use when
  "audit the implementation", "check correctness", "systems analysis",
  "is it ready to ship", "pre-landing audit", or automatically in progressive
  mode for features with new data models, external integrations, or concurrency.
inputs:
  required:
    - { path: "docs/specs/features/<name>.md", artifact: feature-spec }
    - { path: "docs/plans/<date>-<name>/manifest.md", artifact: implementation-manifest }
  optional:
    - { path: "docs/specs/journeys/J*.feature.md", artifact: journeys }
    - { path: "docs/specs/explorations/<name>/DECISION.md", artifact: solution-decision }
    - { path: "docs/specs/vision.md", artifact: vision }
    - { path: "docs/specs/domain-profile.md", artifact: domain-profile }
outputs:
  produces:
    - { path: "docs/specs/audit/<name>-analysis.md", artifact: audit-implementation-report }
chain:
  lanes:
    greenfield: { position: 14, prev: execute-changeset, next: land-changeset }
    brownfield-feature: { position: 11, prev: review-gate, next: land-changeset }
    bugfix: { position: 5, prev: review-gate, next: land-changeset }
    refactor: { position: 5, prev: review-gate, next: land-changeset }
  progressive: true
  self_verify: true
  human_checkpoint: false
---

# Systems Analysis

Evidence-driven correctness audit of implemented code before landing.
Review-protocol catches design issues in the diff. This skill goes deeper —
traces behavior end-to-end, tests hypotheses about failure modes, and produces
findings graded by evidence strength.

Derived from petekp/claude-code-setup exhaustive-audit-implementation (MIT,
Copyright 2024 Pete Petrash). Adapted for svc's spec-first pipeline
with AC-traced verification.

**Announce at start:** "I'm using audit-implementation to audit the implementation for correctness before landing."

## When To Run

**Always** (in progressive mode) for:
- New data models or schema changes
- External integrations (APIs, services, payment, auth)
- Concurrency or real-time features
- Security-sensitive paths (auth, permissions, secrets)

**Skip** for:
- Pure UI changes with no data/API layer
- Documentation-only changes
- Config changes with no behavioral impact

## Failure Modes To Prevent

1. Surface scans that don't follow behavior end-to-end
2. Reporting suspicions as bugs without evidence
3. Cosmetic findings that miss correctness risks
4. Missing the gap between what the spec promises and what the code does

## Process

This skill runs **inside the worktree** where the code lives.

### Phase 0: Load Upstream Context

Read everything the pipeline has produced:

| Source | What to extract |
|--------|----------------|
| Feature spec | ACs — these are the MUST-verify criteria |
| Feature spec revision log | Any ACs that changed mid-pipeline — verify code matches the REVISED version, not the original |
| Manifest | Task list, file-touch plan, validation commands |
| Journeys | User flows that exercise this feature — trace through code |
| Solution decision | What paradigm was chosen and why — check if implementation matches |
| Domain profile | Domain conventions — check if respected |

**Build the verification contract:** for each AC, write what the code MUST do
to satisfy it. This becomes the audit checklist.

### Phase 1: Build Coverage Ledger

Map the implemented code into subsystems before deep analysis:

| Subsystem | Entrypoints | Files | ACs Covered | Risk | Status |
|-----------|-------------|-------|-------------|------|--------|
| API routes | `src/routes/*.ts` | 4 files | AC-01, AC-02 | High | planned |
| Data model | `src/models/*.ts` | 2 files | AC-03 | High | planned |
| Services | `src/services/*.ts` | 3 files | AC-01, AC-04 | Medium | planned |
| Components | `src/components/*.tsx` | 5 files | AC-05, AC-06 | Low | planned |

Prioritize by: AC criticality → side effects → concurrency → auth → recent churn.

### Phase 2: Generate Hypotheses

For each high/medium-risk subsystem, write 2-3 concrete, falsifiable hypotheses
BEFORE reading the code deeply:

**Good hypotheses** (tied to ACs and behavior boundaries):
- "AC-03 says items persist across sessions, but the code uses in-memory storage that resets on restart"
- "The retry logic in the payment service can double-charge because idempotency keys aren't checked"
- "The journey J01 step 'user sees updated list' assumes real-time sync, but the implementation uses polling with a 30s delay"

**Bad hypotheses** (vague, unfalsifiable):
- "The code might have bugs"
- "Error handling could be better"

### Phase 3: Audit One Subsystem At A Time

For each subsystem:

1. **Trace the happy path** from entrypoint to response
2. **Trace error paths** — what happens on invalid input, timeout, DB failure?
3. **Trace cleanup/shutdown** — any resources leaked? Connections unclosed?
4. **Compare against ACs** — does the implementation actually satisfy each AC it claims to cover?
5. **Compare against journeys** — walk through the Gherkin steps, does each map to working code?
6. **Run validation commands** from the manifest — do they still pass?

**Parallel subsystem audit with subagents:**

When subagents are available, assign one subsystem per subagent. Each subagent
receives a scoped context — use this template:

```
You are auditing one subsystem of a feature for correctness.

## Constraints
- Audit ONLY the files listed below. Do NOT scan directories or grep the codebase.
- If you need to check a consumer of an export, report the question back to the
  orchestrator — do not search for it yourself.
- Trace behavior through YOUR files only. Report boundary assumptions
  (what you expect other subsystems to provide) rather than verifying cross-boundary.

## Your subsystem files (disjoint — no other auditor has these)
[INSERT only files from the manifest assigned to this subsystem]

## AC slice
[INSERT only the AC rows this subsystem covers]

## Hypotheses to test
[INSERT hypotheses from Phase 2 for this subsystem]

## Validation commands
[INSERT relevant validation commands from manifest]
```

File disjointness is enforced by the orchestrator. Cross-subsystem questions
(e.g., "does service A call service B correctly?") are reported back and
resolved in Phase 5 convergence, not by individual subagents scanning beyond
their boundary.

### Phase 4: Classify Findings

Every finding must separate observation from inference:

```markdown
### Finding F-<N>: <title>

**Severity:** Critical | High | Medium | Low
**Confidence:** Confirmed | Likely | Needs follow-up
**Type:** Bug | Race condition | Security | AC violation | Spec drift | Dead code
**Location:** <file:line>
**AC Impact:** <which AC is affected>

**Observed:** <what the code actually does — exact citation>
**Expected:** <what the AC/spec/journey says should happen>
**Evidence:** <command output, test result, code trace>
**Checked:** <what was verified to rule out false positive>
**Fix:** <smallest credible fix>
```

**Confidence levels:**
- **Confirmed**: directly demonstrated by code, failing test, or hard contradiction
- **Likely**: strong reasoning but not directly reproduced
- **Needs follow-up**: suspicious but evidence incomplete

### Phase 5: Convergence

After all subsystems:

1. **Deduplicate** cross-cutting findings
2. **Re-rank** by AC impact (AC violation > bug > style)
3. **Sweep for residue**: stale TODO/FIXME, dead code, orphaned imports, temp flags
4. **List coverage gaps** — which ACs were NOT fully verified and why

### Output: `docs/specs/audit/<name>-analysis.md`

```markdown
# Systems Analysis: <feature name>

**Date:** <timestamp>
**Branch:** <branch name>
**Spec:** <feature spec path>

## Verification Contract
| AC | What code must do | Verified? |
|----|-------------------|-----------|
| AC-01 | ... | ✅ Confirmed |
| AC-02 | ... | ⚠️ Likely OK (see F-2) |
| AC-03 | ... | ❌ Violation (see F-1) |

## Coverage Ledger
| Subsystem | Risk | Status | Findings |
|-----------|------|--------|----------|
| API routes | High | done | F-1, F-2 |
| Data model | High | done | none |
| Services | Medium | done | F-3 |

## Findings

### F-1: <title>
...

## Residue
<TODO/FIXME count, dead code, orphaned imports>

## Unverified Surfaces
<what was not checked and why>

## Verdict
- [ ] READY TO LAND — no Critical/High findings
- [ ] BLOCKED — Critical findings must be fixed first
- [ ] CONDITIONAL — High findings should be fixed, Medium acceptable
```

## Evidence Standard

Strongest to weakest:
1. Failing test
2. Reproducible path with exact steps
3. Direct code contradiction with citations
4. Command/search output
5. Static reasoning

Static reasoning alone → "Likely", not "Confirmed".

## Anti-Patterns

- Scanning files without tracing behavior end-to-end
- Reporting style issues as findings
- Calling something dead code without a consumer search
- Claiming a bug without showing the violated AC or broken behavior
- Hiding uncertainty — mark "Needs follow-up" honestly

## Audit Mode

When invoked with `--audit` on existing code (no active worktree):

Same process but against main branch. Useful for periodic health checks.

## Pipeline Continuation

### Self-Verify

| # | Check | How | PASS/FAIL |
|---|-------|-----|-----------|
| 1 | Analysis report exists | `test -f docs/specs/audit/<name>-analysis.md` | |
| 2 | Every AC has a verification row | count AC rows vs spec AC count | |
| 3 | No Critical findings unresolved | grep for `Critical` + check if fixed | |
| 4 | Verdict section present | grep for `## Verdict` | |

### Chaining

**If verdict is READY TO LAND or CONDITIONAL (no Critical):**
- If `--progressive`: invoke `land-changeset --progressive --lane <lane>`
- If not progressive: suggest "Ready to land. Run `land-changeset`"

**If verdict is BLOCKED:**
- Stop the chain. Report Critical findings.
- Route back to `execute-changeset` for fixes in the worktree.
- After fixes: re-run `audit-implementation`.
