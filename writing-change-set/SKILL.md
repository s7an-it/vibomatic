---
name: writing-change-set
description: Use when you have a BASELINED feature spec with technical design and need to produce the implementation plan for branch-first execution — task graph, file set, validation plan, checkpoints, and AC/test mapping
inputs:
  required:
    - { path: "docs/specs/features/<name>.md", artifact: feature-spec }
  optional:
    - { path: "docs/specs/style-contract.md", artifact: style-contract }
    - { path: "docs/specs/ux/<name>.md", artifact: ux-design }
    - { path: "docs/specs/ui/<name>.md", artifact: ui-design }
outputs:
  produces:
    - { path: "docs/plans/<date>-<name>/manifest.md", artifact: implementation-manifest }
chain:
  lanes:
    greenfield: { position: 11, prev: spec-style-sync, next: executing-change-set }
    brownfield-feature: { position: 7, prev: spec-style-sync, next: executing-change-set }
    bugfix: { position: 2, prev: bugfix-brief, next: executing-change-set }
    refactor: { position: 2, prev: spec-code-sync, next: executing-change-set }
  progressive: true
  self_verify: true
  human_checkpoint: true
---

# Writing Change Sets

The change set is not a markdown dump of exact code.

The branch is the territory. This skill writes the **implementation plan** that
execution will follow directly in the worktree.

Think Obra/Superpowers `writing-plans` depth, but grounded in vibomatic specs,
journeys, and technical design.

**Announce at start:** "I'm using the writing-change-set skill to produce the implementation plan."

## Inputs

Before writing anything, read and hold in context:

| Artifact | Path | What You Extract |
|----------|------|-----------------|
| Feature Spec | `docs/specs/features/<name>.md` | Stories, ACs, dependencies, technical design section |
| UX Design | `docs/specs/ux/<name>.md` | Screen flows, states, error handling |
| UI Design | `docs/specs/ui/<name>.md` | Component specs, design tokens, responsive behavior |
| Design System | `docs/specs/design-system.md` | Tokens, typography, spacing, component patterns |
| Journey Docs | `docs/specs/journeys/J*-<name>.feature.md` | Gherkin scenarios, AC cross-references, Layer 3 findings |
| Personas | `docs/specs/personas/P*.md` | Who uses this, skill implications |
| Vision | `docs/specs/vision.md` | Boundaries, principles |
| Existing Code | source tree | Current patterns, naming, imports, tests |

If required upstream artifacts are stale or missing, stop and route back before planning implementation.

## Output

Write:

```text
docs/plans/<YYYY-MM-DD>-<feature-name>/manifest.md
```

This manifest is the implementation contract. It should be detailed enough for
`executing-change-set` to apply directly in the branch without inventing structure.

Do **not** create markdown part files with exact code payloads.

## Manifest Contents

Every manifest should include:

### 1. Header

- feature spec path
- branch name
- **Status:** DRAFTED (lifecycle: DRAFTED → SIMULATED → EXECUTING → CHECKPOINTED → PROMOTED → VERIFIED)
- base branch and base SHA
- status: `BASELINED`
- creation timestamp

### 2. Implementation Summary

- what this feature changes
- what must remain invariant
- major constraints from spec/UX/UI/tech design

### 3. Files Planned

Table:

| File | Action | Task | Purpose |
|------|--------|------|---------|

Actions:
- `CREATE`
- `MODIFY`
- `DELETE` (rare, must be justified)

### 4. Task Graph

Task list with:

- task id
- title
- touched files
- dependencies
- AC coverage
- validation command
- checkpoint name
- parallel group, if any

Suggested baseline tasks:

- `task-1-types`
- `task-2-data-model`
- `task-3-tests-unit`
- `task-4-services`
- `task-5-components`
- `task-6-e2e`
- `task-7-spec-updates`
- `task-8-journey-updates`

For smaller work, collapse tasks. For larger work, split by subsystem.

### 5. AC-to-Task Mapping

Every AC must map to one or more implementation tasks.

### 6. AC-to-Test Mapping

Every AC must map to exactly one of:

- `Unit`
- `E2E`
- `Manual`
- `N/A` (with reason)

### 7. Validation Plan

Include:

- task-level validation commands
- final branch-level validation commands

### 8. Checkpoint Plan

List:

- required checkpoint names
- expected order
- rollback anchors

### 9. Promotion Readiness Checklist

Checklist should confirm:

- all planned files accounted for
- all tasks have validation
- all ACs mapped
- all checkpoints named
- final diff should contain only manifest-listed files

## Review Surface

This skill does **not** produce the final reviewed code. It produces the execution map.

The real review surfaces are:

- per-task: `git diff --staged`
- final feature review: `git diff <base>...HEAD` or equivalent final staged diff

## TDD Rule

Tests still come before implementation where applicable.

That means the manifest should schedule:

- unit tests before services/components they constrain
- e2e after the relevant implementation exists

## Checkpoints and Loop-Backs

The manifest must explicitly anticipate loop-backs.

Record likely loop-back targets:

- spec ambiguity -> `writing-spec`
- UX contradiction -> `writing-ux-design`
- UI/design-system gap -> `writing-ui-design`
- technical infeasibility -> `writing-technical-design`

This keeps execution honest when reality disagrees with the plan.

## What Not To Do

- Do not write full file contents into markdown
- Do not write giant BEFORE/AFTER code payloads
- Do not leave task boundaries vague
- Do not omit AC/test mapping
- Do not pretend the manifest itself is the implementation

## Pre-Implementation Simulation (Dry Run)

After the manifest is complete but BEFORE handoff, trace through each planned task against the actual codebase state. This catches wrong assumptions before code is written.

### Two-Layer Resolution Model

The simulation checks against two layers:
1. **Disk layer** — files that exist in the actual codebase right now
2. **Planned layer** — files that earlier tasks in the graph will CREATE (accumulated as the graph is walked in dependency order)

Rules:
- **CREATE targets**: added to the planned layer (NOT checked against disk — they don't exist yet)
- **MODIFY targets**: checked against disk (must exist)
- **Imports from planned files**: resolved against the planned layer
- **Imports from existing files**: resolved against disk (grep for the export)

### Per-Task Checks

Walk the task graph in dependency order. For each task:

1. CREATE targets: verify path does NOT already exist on disk. If it does → MODIFY, not CREATE.
2. MODIFY targets: verify the file exists. Read it, confirm expected functions/exports/types are present.
3. Imports: check disk layer first, then planned layer. Verify expected export names exist.
4. New dependencies: check `package.json`. If missing, add install to task prerequisites.
5. For modified functions: verify parameter signatures match assumptions.
6. For new API routes: grep for path conflicts.
7. For test tasks: verify the test framework matches (vitest vs jest vs mocha).

### Simulation Report

Append to the manifest:

```markdown
## Simulation Report

| Task | Check | Result | Action |
|------|-------|--------|--------|
| task-1-types | src/types/match.ts does not exist | PASS (CREATE) | — |
| task-3-tests | vitest config found | PASS | Use vitest |
| task-4-services | src/services/db.ts exports getDb | PASS | Import valid |
| task-4-services | Package zod not in package.json | FAIL | Add to prerequisites |
```

If any FAIL: fix the manifest, re-check, proceed only when all PASS or acknowledged WARN.

### Scenario Walkthrough (after file-level checks)

For each journey scenario in `docs/specs/journeys/J*.feature.md`:

1. Read the Given/When/Then steps
2. For each step, identify which planned task implements it
3. If a step has no implementing task: WARN — scenario coverage gap
4. Log in the simulation report:

```markdown
## Scenario Coverage

| Journey | Scenario | Steps | Tasks | Coverage |
|---------|----------|-------|-------|----------|
| J01 | First-time setup | 5 | task-1, task-4 | 5/5 ✅ |
| J02 | Daily trend review | 4 | task-4, task-5 | 3/4 ⚠️ "Then sees learning path" has no task |
```

Update manifest Status from DRAFTED to SIMULATED when simulation passes.

## Handoff

After the manifest and simulation are complete:

- route to `executing-change-set`
- G5 happens after execution, using staged diffs and task checkpoints

The manifest is the map. The branch is the territory.

## Pipeline Continuation

### Self-Verify

Before declaring done, verify:

| # | Check | How | PASS/FAIL |
|---|-------|-----|-----------|
| 1 | Manifest file exists | `test -f docs/plans/<date>-<name>/manifest.md` | |
| 2 | Task graph has ≥1 task | grep for `task-` in manifest | |
| 3 | AC-to-task mapping complete | every AC from spec maps to ≥1 task | |
| 4 | AC-to-test mapping complete | every AC maps to a test type | |
| 5 | Simulation report appended | Simulation Report section in manifest | |
| 6 | No unresolved FAIL in simulation | all FAIL items fixed or acknowledged | |
| 7 | No unresolved questions | grep for TBD, TODO | |

If any check FAILs, fix before continuing.

### Chaining

**If `--progressive` flag is present AND self-verify passed:**
- Check `--skip` list. If this skill is in the skip list, pass through to next.
- Invoke next skill: `executing-change-set --progressive --lane <lane>`

**If `--progressive` flag is absent:**
- Report manifest summary to user
- Suggest: "Next: run `executing-change-set` to apply the plan"
