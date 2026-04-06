---
name: verify-promotion
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
    greenfield: { position: 16, prev: land-changeset, next: null }
    brownfield-feature: { position: 13, prev: land-changeset, next: null }
    bugfix: { position: 7, prev: land-changeset, next: null }
    refactor: { position: 7, prev: land-changeset, next: null }
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

**Announce at start:** "I'm using the verify-promotion skill to verify the promoted implementation."

## Inputs

Read:

| Artifact | Path | Purpose |
|----------|------|---------|
| Feature spec | `docs/specs/features/<name>.md` | ACs, implementation notes |
| Implementation manifest | `docs/plans/<date>-<name>/manifest.md` | File set, AC/test mapping |
| Promotion evidence | squash-diff / validation summary | Promotion truth |
| Live environment | localhost / preview / staging | QA and E2E runtime proof |

## Verification Passes

Each sub-skill receives scoped context — do NOT invoke them bare. Pass the
feature spec path and manifest path explicitly so they don't re-scan to find
artifacts.

1. `sync-spec-code` — pass: `--feature docs/specs/features/<name>.md`
   - convert PLANNED -> RESOLVED (with tier tags)
   - detect DRIFT / REVERTED
   - scope: only the ACs and annotations in THIS feature spec, not all specs

2. `audit-ac` — pass: `--feature docs/specs/features/<name>.md`
   - ensure AC table still matches real implementation
   - scope: single feature, not all-features mode

3. `test-journeys` — pass: `--journeys docs/specs/journeys/J*-<name>.feature.md`
   - verify runtime behavior across journeys relevant to THIS feature only
   - do NOT load journeys for other features

4. `write-e2e` — pass: `--journeys docs/specs/journeys/J*-<name>.feature.md`
   - automate stable user flows where applicable
   - scope: journeys for this feature only

**Context reuse rule:** The feature spec and manifest are already loaded by
verify-promotion. If running sub-skills in the same session, they share this
context. If spawning as subagents, pass the file paths explicitly — do NOT let
each sub-skill independently discover artifacts by scanning `docs/specs/`.

## Verification Report

Compile:

- manifest reference
- sync-spec-code results
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
  - behavior bug -> `diagnose-bug` or execution/planning path
  - spec mismatch -> `write-spec`
  - journey mismatch -> `write-journeys`

## Post-Verification: Canary Monitoring

If the feature has a live URL (localhost or deployed), run a canary check.

### Baseline Capture (BEFORE deploy)

Before any deployment, capture the pre-deploy baseline for every page in the feature's journeys:

1. Screenshot each page
2. Record console errors (if any pre-existing)
3. Measure page load time
4. Store as the comparison baseline

### Active Monitoring Loop

After deploy, monitor every 60 seconds for 5 minutes (5 checks minimum):

1. Open the app in browser (gstack browse)
2. For each page in the feature's key journeys:
   - Take a screenshot
   - Capture console errors
   - Measure page load time (performance.timing or equivalent)
   - Check for new 404 responses in network tab
3. Compare each metric against the pre-deploy baseline

### Alert Severity

| Severity | Condition | Action |
|----------|-----------|--------|
| CRITICAL | Page fails to load entirely | Stop monitoring, report immediately |
| HIGH | New console errors not present in baseline | Flag for investigation |
| MEDIUM | Page load time >= 2x baseline | Flag as performance regression |
| LOW | New 404 requests not present in baseline | Note in report |

**Transient tolerance:** only alert on patterns that persist across 2+ consecutive checks.
A single spike that resolves on the next check is logged but not alerted.

### Health Report

Produce a per-page status table at the end of monitoring:

```
CANARY HEALTH REPORT
Page                    | Load Time | Console Errors | Status
----------------------- | --------- | -------------- | -------
/dashboard              | 1.2s (ok) | 0 new          | HEALTHY
/dashboard/settings     | 3.8s (2x) | 2 new          | DEGRADED
/checkout               | TIMEOUT   | N/A            | BROKEN
```

Final verdict:
- **HEALTHY** — all pages healthy, no new errors, load times within tolerance
- **DEGRADED** — non-blocking issues found (MEDIUM/LOW alerts), feature works but needs attention
- **BROKEN** — any CRITICAL alert fired, or HIGH alerts persisted across all checks

## Post-Verification: Document Sync

After verification passes, reconcile documentation.

### Update Classification

Not all doc updates are equal. Classify each before acting:

- **Auto-update** (apply without asking): factual corrections — version numbers, file paths,
  command syntax, API signatures that changed in the diff
- **Ask-user** (present and wait for approval): narrative changes — rewording feature descriptions,
  changing architecture explanations, modifying onboarding guides, altering project positioning

### Reconciliation Steps

1. Read ONLY project docs that the shipped diff could affect. Check the diff
   file list (`git diff main~1..main --name-only`) — if no docs were touched
   and no public API changed, skip doc reconciliation entirely.
2. For touched docs: cross-reference the diff — does the doc still match?
3. Apply auto-updates; queue ask-user updates and present them as a batch

### Cross-Doc Consistency Checks

After updates, verify consistency across documents:

- README feature list matches CLAUDE.md capabilities section
- CHANGELOG latest version matches VERSION file
- Any "Getting Started" commands in README still work with current codebase
- Architecture diagrams reference files/modules that still exist

If any inconsistency is found, fix it (auto-update) or flag it (ask-user).

### TODOS.md Cleanup

1. Read TODOS.md (if it exists)
2. Mark completed items — cross-reference against the shipped diff to identify which TODOs were addressed
3. Scan the codebase for new TODO/FIXME/HACK comments introduced in the diff:
   ```bash
   git diff main..HEAD | grep -E '^\+.*\b(TODO|FIXME|HACK)\b'
   ```
4. Add any new items to TODOS.md with file location and context

### VERSION Guard

Never bump VERSION during document sync. If the VERSION file needs updating,
flag it and ask the user — version bumps belong in `land-changeset` Step 2a.

This closes the loop — documentation matches shipped reality.

## Post-Verification: Log Learnings

Append operational discoveries from this run to `docs/learnings/learnings.jsonl`:

```json
{"date": "<date>", "skill": "verify-promotion", "feature": "<name>", "learning": "<what was discovered>", "confidence": "high|medium|low", "saves_minutes": <estimate>}
```

Examples of learnings worth logging:
- "The Prisma migration script needs `--force` flag in CI"
- "Auth middleware must be loaded before rate limiter"
- "The empty state component doesn't render without at least one CSS import"

These compound across sessions — `route-workflow` reads them to make better recommendations.

## Post-Verification: Update Builder Profile

After a successful verification, update the global builder profile
(`~/.claude/builder-profile.md`) to capture what this project taught us
about the builder. This is how the pipeline gets smarter across projects.

1. **Add project to history:**
   ```markdown
   ### <Project Name> — shipped
   - **What:** <one sentence>
   - **When:** <start date> → <ship date>
   - **Stack:** <what was built with>
   - **Reached:** shipped / launched / revenue
   - **Revenue:** <if any>
   - **Reusable assets:** <code, infra, domain, learnings>
   ```

2. **Update skills** — did the builder learn a new framework, tool, or pattern?
3. **Update financial context** — did revenue start? New subscriptions? Entity registered?
4. **Update social presence** — did they grow followers? Launch on ProductHunt? Start a newsletter?
5. **Run pattern detection** — compare this project's timeline, decisions, and outcome
   against past projects. If a pattern emerges or is reinforced, append to Builder Patterns:
   ```markdown
   - **[pattern-id] <description>** — confidence: <1-10>, observed: <N> times
     Source: <which projects>
     Pipeline action: <what changes>
   ```
6. **Run gap analysis** — what blocked them this time? What tool would have saved time?
7. **Append changelog entry:**
   ```markdown
   - <date>: Post-project update from <project name> — <what changed>
   ```

If the builder profile does not exist at `~/.claude/builder-profile.md`, skip this step
(the builder has not been profiled yet — `route-workflow` handles initial creation).

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
