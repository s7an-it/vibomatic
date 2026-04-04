---
name: verifying-promotion
description: Use after a reviewed branch has been promoted to verify that the promoted implementation matches specs, passes tests, satisfies acceptance criteria, and closes the loop back into spec/journey state — triggers G7 review
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

## What Not To Do

- Do not fix code inline during verification
- Do not skip sync-back into spec/journey state
- Do not treat passing tests alone as sufficient if drift remains
