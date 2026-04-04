---
name: writing-change-set
description: Use when you have a BASELINED feature spec with technical design and need to produce the implementation plan for branch-first execution — task graph, file set, validation plan, checkpoints, and AC/test mapping
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

## Handoff

After the manifest is complete:

- route to `executing-change-set`
- G5 happens after execution, using staged diffs and task checkpoints

The manifest is the map. The branch is the territory.
