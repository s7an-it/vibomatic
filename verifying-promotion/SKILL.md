---
name: verifying-promotion
description: Use after a reviewed branch has been promoted to verify that the promoted implementation matches specs, passes tests, satisfies acceptance criteria, and closes the loop back into spec/journey state — triggers G7 review
inputs:
  required:
    - { path: "docs/specs/features/<name>.md", artifact: feature-spec }
    - { path: "docs/plans/<date>-<name>/manifest.md", artifact: implementation-manifest }
  optional: []
outputs:
  produces:
    - { path: "docs/specs/features/<name>.md", artifact: feature-spec, status: VERIFIED }
chain:
  lanes:
    greenfield: { position: 16, prev: landing-change-set, next: null }
    brownfield-feature: { position: 13, prev: landing-change-set, next: null }
    bugfix: { position: 7, prev: landing-change-set, next: null }
    refactor: { position: 7, prev: landing-change-set, next: null }
  progressive: true
  self_verify: true
  human_checkpoint: false
---

# Verifying Promotion

Verification is the final proof pass after promotion.

It confirms that the promoted branch state:

- matches the intended behavior
- satisfies ACs
- passes QA and E2E
- syncs back into specs and journeys

**Announce at start:** "I'm using the verifying-promotion skill to verify the promoted implementation."

## Inputs

Read:

| Artifact | Path | Purpose |
|----------|------|---------|
| Feature spec | `docs/specs/features/<name>.md` | ACs, implementation notes |
| Implementation manifest | `docs/plans/<date>-<name>/manifest.md` | File set, AC/test mapping |
| Promotion evidence | squash-diff / validation summary | Promotion truth |
| Live environment | localhost / preview / staging | QA and E2E runtime proof |

## Verification Passes

1. `spec-code-sync`
   - convert PLANNED -> RESOLVED
   - detect DRIFT / REVERTED

2. `spec-ac-sync`
   - ensure AC table still matches real implementation

3. `journey-qa-ac-testing`
   - verify runtime behavior across journeys

4. `agentic-e2e-playwright`
   - automate stable user flows where applicable

## Verification Report

Compile:

- manifest reference
- spec-code-sync results
- AC coverage
- QA coverage
- E2E coverage
- findings

## G7 Review

G7 checks:

- no unresolved critical/high drift
- AC coverage is complete or explicitly justified
- QA and E2E results are current
- spec/journey state reflects what shipped

If G7 passes:

- feature status -> `VERIFIED`

If G7 fails:

- route back based on failure type:
  - behavior bug -> `bugfix-brief` or execution/planning path
  - spec mismatch -> `writing-spec`
  - journey mismatch -> `journey-sync`

## Post-Verification: Canary Monitoring

If the feature has a live URL (localhost or deployed), run a canary check:

1. Open the app in browser (gstack browse)
2. Navigate through the feature's key journeys
3. Watch for: console errors, network failures, visual regressions
4. Compare against visual-tracker baseline (if exists)
5. Duration: 2-5 minutes of active monitoring

Report: CLEAN (no issues), DEGRADED (non-blocking issues), BROKEN (blocking).

## Post-Verification: Document Sync

After verification passes, reconcile documentation:

1. Read all project docs: README, ARCHITECTURE, CONTRIBUTING, CLAUDE.md
2. Cross-reference the shipped diff — what changed?
3. Update any docs that reference changed behavior
4. Clean up stale TODOs that were completed
5. Update CHANGELOG if not already done in landing step

This closes the loop — documentation matches shipped reality.

## Post-Verification: Log Learnings

Append operational discoveries from this run to `docs/learnings/learnings.jsonl`:

```json
{"date": "<date>", "skill": "verifying-promotion", "feature": "<name>", "learning": "<what was discovered>", "confidence": "high|medium|low", "saves_minutes": <estimate>}
```

Examples of learnings worth logging:
- "The Prisma migration script needs `--force` flag in CI"
- "Auth middleware must be loaded before rate limiter"
- "The empty state component doesn't render without at least one CSS import"

These compound across sessions — `workflow-compass` reads them to make better recommendations.

## What Not To Do

- Do not fix code inline during verification
- Do not skip sync-back into spec/journey state
- Do not treat passing tests alone as sufficient if drift remains

## Pipeline Continuation

### Self-Verify

Before declaring done, verify:

| # | Check | How | PASS/FAIL |
|---|-------|-----|-----------|
| 1 | Feature spec status updated to VERIFIED | grep for `status: VERIFIED` in `docs/specs/features/<name>.md` | |
| 2 | Tests pass | Run test suite; all pass | |
| 3 | QA complete | AC tables have current QA status, no unresolved critical/high drift | |

If any check FAILs, fix before continuing. If a fix requires upstream changes, stop and report.

### Chaining

**If `--progressive` flag is present AND self-verify passed:**
- This is the end of all lanes. Report completion.

**If `--progressive` flag is absent:**
- Report results to user
- Pipeline complete. No further skills to chain.
