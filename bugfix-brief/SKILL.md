---
name: bugfix-brief
description: >
  Root-cause-first bug and regression planning for vibomatic repos. Use when a work item
  describes broken behavior, a regression, or a production issue that needs correction
  without forcing full feature-spec authoring. Produces an implementation-ready bugfix
  brief with reproduction, root cause, expected behavior, smallest safe fix surface,
  and proof-of-fix plan.
---

# Bugfix Brief

Bug work is not feature discovery.

A bugfix lane should answer: what is broken, why is it broken, what is the smallest
safe fix, and how do we prove it is fixed?

This skill is influenced by systematic debugging approaches: reproduce first, isolate
the fault, reason about root cause, then define the correction and verification.

**Announce at start:** "I'm using the bugfix-brief skill to plan a root-cause-first fix."

## When To Use

- Existing behavior is wrong
- A regression broke something that worked before
- A work item is classified as `bugfix` or `regression`
- The repo is brownfield and the correction should not go through full feature authoring

## Inputs

Read:

- the work-item file in `docs/specs/work-items/WI-*.md`
- relevant code paths
- relevant tests
- relevant specs or journeys, if they exist
- any reproduction evidence

## Outputs

Update the work item with:

- reproduction steps
- expected behavior
- actual behavior
- root cause summary
- smallest safe fix surface
- verification plan
- whether specs need updating after the fix

Optional output:

- a short bugfix brief section in the work item, or a linked brief file if the repo prefers that pattern

## Process

### 1. Reproduce

State the shortest reliable repro.

If repro is not yet reliable, record the best-known repro and the uncertainty.

### 2. Define expected behavior

Use the strongest available source in this order:

1. current shipped behavior before regression
2. existing spec or journey
3. user-visible contract in code/tests/docs
4. explicit stakeholder intent

Do not silently invent the expected behavior.

### 3. Isolate the fault surface

Identify the smallest relevant subsystem:

- UI state/rendering
- request validation
- business logic
- integration boundary
- persistence/data model
- background process

### 4. Write root cause

Summarize:

- immediate cause
- enabling condition
- why the system allowed it

If true root cause is still unknown, say so plainly and log the current best hypothesis.

### 5. Define smallest safe fix

Specify:

- file/class/module scope
- behavior to preserve
- behavior to change
- whether this is a code-only fix or requires spec/journey updates

### 6. Define proof of fix

List the exact validation:

- targeted unit/integration test
- manual repro replay
- journey or regression verification
- monitoring/log check if needed

## Regression vs Bugfix

- **Bugfix**: behavior is wrong or incomplete
- **Regression**: behavior used to work and stopped working

Regression briefs should explicitly capture the last-known-good behavior and how confidence in that expectation was established.

## What Not To Do

- Do not turn a small bug into a full feature-spec rewrite
- Do not skip root cause and jump to patch ideas
- Do not patch widely when a smaller safe fix is available
- Do not update product specs unless intended behavior actually changes

## Routing After This Skill

- implementation work -> `writing-change-set` or direct execution flow, depending on repo practice
- drift discovered instead of bug -> `spec-code-sync`
- issue is actually missing capability -> `feature-discovery`
