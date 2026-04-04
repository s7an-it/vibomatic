---
name: repo-conversion
description: >
  Convert an existing repository into the vibomatic way of working before applying
  the full pipeline. Use when the repo already has shipped behavior, docs, tests,
  or conventions that must be preserved and mapped instead of overwritten. Produces
  repo-canonical project state, compatibility notes, and structured work items for
  discovered features, bugs, regressions, drift, and chores.
---

# Repo Conversion

Brownfield work should not start by pretending the repo is clean.

This skill is the first step for existing repositories. It inventories the current
truth, maps it into vibomatic artifact types, logs problems as work items, and stops
when the terrain is understood. It does not turn into an endless audit, and it does
not fix everything it finds while still mapping the system.

**Announce at start:** "I'm using the repo-conversion skill to map this existing repo into vibomatic working mode."

## When To Use

- Existing repo with active product behavior
- Existing repo with docs/tests/process that predate vibomatic
- Brownfield adoption
- Team asks "how do we bring this repo into vibomatic?"
- Before running the full pipeline on an existing product

## Core Rule

**Log then triage. Do not fix as found.**

Conversion discovers findings and records them as work items. Resolution begins only
after the map is complete, unless the repo is so broken that mapping cannot continue.

## Outputs

Create or update these canonical files:

- `docs/specs/project-state.md`
- `docs/specs/work-items/INDEX.md`
- `docs/specs/work-items/WI-*.md`

These repo files are the source of truth. External trackers are projections.

## Project State File

`docs/specs/project-state.md` should capture:

- repo mode: `convert`
- conversion status: `identified | mapping | mapped | triaged`
- active workflow lanes in use
- foundational artifact status:
  - vision
  - personas
  - journeys
  - feature specs
  - tests
  - tracker sync
- subsystem map
- compatibility notes
- work-item summary by type and status

## Work Item Types

Use these canonical types:

- `conversion`
- `feature`
- `bugfix`
- `regression`
- `refactor`
- `drift`
- `chore`

Status values:

- `identified`
- `mapped`
- `triaged`
- `planned`
- `in_progress`
- `blocked`
- `resolved`
- `verified`
- `deferred`

Severity values:

- `critical`
- `high`
- `medium`
- `low`

## Work Item Template

Each file in `docs/specs/work-items/` should include:

```markdown
# WI-001: Short title

**Type:** bugfix
**Status:** identified
**Severity:** high
**Lane:** bugfix
**Repo Mode:** convert
**Source Skill:** repo-conversion
**Source Artifact:** path/to/file-or-area
**GitHub Issue:** —

## Problem

What is wrong or missing.

## Evidence

Concrete files, runtime behavior, docs, or test references.

## Route Recommendation

Which skill or lane should take this next and why.

## Notes

Anything needed for triage, not full implementation.
```

## Process

### 1. Inventory current truth

Read:

- code layout
- existing docs
- existing tests
- existing workflow/status files
- issue tracker references if present

Answer:

- what is actually shipped?
- what conventions already exist?
- what docs appear canonical?
- what parts are obviously drifting?

### 2. Map current artifacts into vibomatic form

Do not rename everything on day one.

Instead, classify current truth into the nearest vibomatic concepts:

- vision or product direction
- personas or user segments
- journeys or flow descriptions
- feature specs
- implementation notes
- work queues

Record compatibility notes where current structure differs from vibomatic.

### 3. Capture findings as work items

For each discovered issue, create a work item instead of trying to solve it inline.

Examples:

- shipped bug -> `bugfix`
- behavior regressed from expected state -> `regression`
- spec and code disagree -> `drift`
- missing canonical product artifact -> `conversion`
- real new capability request -> `feature`

### 4. Triage, then stop

Assign each item:

- type
- severity
- lane
- next skill

Conversion ends when:

- the repo has a `project-state.md`
- the work-item index exists
- major findings are logged
- every logged item has a route recommendation

That is the stopping rule. No endless audit loop.

## Routing Rules

- `feature` -> `feature-discovery` then `writing-spec` in delta mode
- `bugfix` / `regression` -> `bugfix-brief`
- `drift` -> `spec-code-sync`
- `conversion` -> stay in conversion until mapped, then route
- `chore` / `refactor` -> implementation planning or change-set planning based on scope

## What Not To Do

- Do not force a clean vibomatic structure on first pass
- Do not rewrite existing docs just because they are not canonical yet
- Do not fix every bug you notice while still mapping the repo
- Do not leave findings in freeform prose when they should be tracked as work items

## Tracker Integration

After the repo-canonical work items exist, use `work-item-sync` to project them to GitHub Issues.
GitHub is a projection. Repo files remain canonical.
