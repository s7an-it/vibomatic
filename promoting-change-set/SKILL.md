---
name: promoting-change-set
description: Use when a change set is approved (CHANGE-SET-APPROVED) and needs to be applied to the actual codebase — applies files exactly as written, detects deviations, triggers G6 review
---

# Promoting Change Set

## Overview

Promotion is the act of applying a reviewed change set to the actual codebase.
It is a separate, auditable step — not "the agent writes code."

This skill transitions a feature from CHANGE-SET-APPROVED → PROMOTED.

```
writing-change-set        → produces the change set (multi-part, exact bytes)
  [G5 Review]             → change set approved
promoting-change-set      → applies to codebase, detects deviations
  [G6 Review]             → promotion verified
verifying-promotion       → tests pass, QA, E2E, spec-code-sync
  [G7 Review]             → VERIFIED
```

**Announce at start:** "I'm using the promoting-change-set skill to apply the approved change set to the codebase."

## Why Promotion Is Separate From The Change Set

When an LLM applies pre-written code, it still does pattern matching. It may:
- "Improve" a function while copying it (content deviation)
- Adjust an import path based on its own judgment (content deviation)
- Skip a file it considers unnecessary (omission)
- Add a file not in the plan (addition)
- Reorder statements for "readability" (content deviation)
- Reformat code style (formatting deviation)

Each of these is a deviation from the reviewed change set. The change set was
reviewed and approved as a coherent whole. Any deviation — even an "improvement" —
breaks the review guarantee.

**The promotion agent's job is to COPY, not to THINK.**

## Prerequisites

| Artifact | Where | Required? |
|----------|-------|-----------|
| Change set (APPROVED) | `docs/plans/<date>-<name>/manifest.md` | Yes — must have passed G5 review |
| Feature spec (BASELINED) | `docs/specs/features/<name>.md` | Yes — status must be BASELINED or CHANGE-SET-APPROVED |
| All change set parts | `docs/plans/<date>-<name>/part-*.md` | Yes — manifest references them |

**Gate:** Do not start promotion without a CHANGE-SET-APPROVED change set. If the change set hasn't passed G5 review, route to `review-protocol`.

## Process

### Step 1: Read The Manifest

Read `docs/plans/<date>-<name>/manifest.md`. Extract:
- Apply order (which parts in which sequence)
- Files touched (complete list of creates and modifies)
- Dependencies between parts

Verify the manifest is complete:
- Every part file referenced in the manifest exists
- Every file listed in "Files Touched" appears in exactly one part
- Apply order respects dependencies

If the manifest is incomplete or inconsistent, STOP. Route back to `writing-change-set`.

### Step 2: Pre-Promotion Snapshot

Before touching any file, capture the current state:

```bash
# Create a snapshot branch for rollback
git checkout -b pre-promotion-<feature-name>
git checkout -  # return to working branch

# Record current state of all files that will be modified
# (new files don't need snapshots — they don't exist yet)
```

For each MODIFY action in the manifest, read and record the current file content. This enables deviation detection and rollback.

### Step 3: Apply Parts In Order

For each part in the manifest's apply order:

1. **Read the part document** — extract every file block with its target path and action (CREATE or MODIFY)
2. **For CREATE actions:**
   - Verify the file does NOT already exist (if it does, STOP — unexpected state)
   - Write the exact content from the part document to the target path
   - Log: `CREATED <path> (<bytes> bytes)`
3. **For MODIFY actions:**
   - Read the current file
   - Apply the exact changes specified in the part document
   - If the part contains full file content: replace the entire file
   - If the part contains a diff/patch: apply the patch exactly
   - Log: `MODIFIED <path> (<lines changed> lines)`
4. **After each file:**
   - Verify the file was written successfully (read it back)
   - Compare the written content against the part document
   - If ANY difference: log as DEVIATION and continue (don't fix — deviations are caught at G6)

### Step 4: Produce The Deviation Report

After all parts are applied, generate a deviation report:

```markdown
# Promotion Deviation Report

**Change Set:** docs/plans/<date>-<name>/
**Feature:** <feature-name>
**Promoted:** <timestamp>

## Summary

| Metric | Count |
|--------|-------|
| Files created | N |
| Files modified | N |
| Total deviations | N |
| Critical deviations | N |
| Formatting deviations | N |

## Deviations

### DEV-001: [file path]
**Class:** Content deviation
**Severity:** Critical
**Plan says:**
```
[exact content from change set]
```
**Applied as:**
```
[actual content written]
```
**Difference:** [description of what changed]

### (repeat for each deviation)

## Files Applied Successfully (No Deviations)

| File | Action | Part | Bytes |
|------|--------|------|-------|
| src/types/match.ts | CREATE | 01 | 1,234 |
| ... | ... | ... | ... |
```

### Deviation Classes

| Class | Description | Severity |
|-------|-------------|----------|
| Content deviation | Agent changed logic, variable names, function signatures | Critical |
| Omission | Agent skipped a file from the plan | Critical |
| Addition | Agent created a file not in the plan | High |
| Partial application | Agent applied some but not all changes to a file | High |
| Formatting deviation | Agent reformatted code (whitespace, line breaks) | Low |
| Import reordering | Agent changed import order without changing functionality | Low |
| Comment deviation | Agent added, removed, or modified comments | Low |

### Step 5: Zero-Deviation Check

**If zero deviations:** Skip to Step 7.

**If any critical/high deviations:**
- Do NOT attempt to fix them
- The fix is to re-apply the specific file from the change set
- Re-read the part document, re-apply the exact content
- Re-run deviation check for that file only
- If the deviation persists after 2 re-apply attempts: log as PERSISTENT DEVIATION

**If only low deviations (formatting, import order):**
- These are acceptable IF they don't change behavior
- Log them but they should not block G6

### Step 6: Run Validation Commands

Execute every validation command from the change set manifest:

```bash
# Per-part validation (from manifest)
npm run typecheck
npm run test -- matchScore
npx playwright test e2e/specs/matching.spec.ts

# Full suite validation
npm run lint
npm run test
```

Log each result:

```markdown
## Validation Results

| Command | Part | Status | Output |
|---------|------|--------|--------|
| `npm run typecheck` | all | PASS | 0 errors |
| `npm run test -- matchScore` | 03 | PASS | 5 tests, 0 failures |
| `npx playwright test matching.spec.ts` | 06 | FAIL | 1 failure: timeout |
```

### Step 7: Trigger G6 Review

Enter the review protocol at Gate G6 with:
- The deviation report
- The validation results
- The change set manifest (for reference)

**G6 checks:**
- Zero critical/high deviations (or all resolved by re-apply)
- All validation commands pass
- Every file in the manifest was applied
- No files were changed that aren't in the manifest

**If G6 passes:** Feature spec status → PROMOTED

**If G6 fails:** Findings become fix tasks. Fix and re-enter at Step 3 for affected files only.

### Step 8: Update Feature Spec Status

```markdown
**Status:** PROMOTED
```

Add promotion metadata:

```markdown
## Promotion Record

**Promoted:** <timestamp>
**Change Set:** docs/plans/<date>-<name>/
**Deviations:** <count> (<count> resolved)
**Validation:** <pass/fail summary>
```

### Step 9: Handoff

Present a summary:

```
Promotion complete: <feature-name>
Status: PROMOTED (was CHANGE-SET-APPROVED)
Files created: N
Files modified: N
Deviations: N total, N resolved, N low (accepted)
Validation: N/N commands passed

Ready for verification. Next step:
  "Run verifying-promotion against docs/specs/features/<feature-name>.md"
```

**The terminal state is invoking verifying-promotion** (or the verification
skills: `spec-code-sync`, `journey-qa-ac-testing`, `agentic-e2e-playwright`).

## Rollback

If promotion fails irreparably (persistent deviations, validation failures
that indicate the change set itself is wrong):

```bash
# Restore pre-promotion state
git checkout pre-promotion-<feature-name> -- .
git branch -d pre-promotion-<feature-name>
```

Route back to `writing-change-set` with the findings. The change set needs revision.

Feature spec status reverts to BASELINED.

## Anti-Patterns

| Don't | Why | Instead |
|-------|-----|---------|
| "Improve" code while applying | Breaks the review guarantee | Copy exactly — improvements go through a new change set |
| Fix deviations by editing the applied code | Creates unreviewed changes | Re-apply from the change set document |
| Skip validation commands | Deviations may compile but fail at runtime | Run every command from the manifest |
| Apply parts out of order | Dependencies between parts exist for a reason | Follow the manifest's apply order exactly |
| Ignore low-severity deviations | They accumulate into drift | Log them even if they don't block G6 |
| Modify files not in the manifest | Creates untracked changes | Only touch files listed in the manifest |

## Routing

| Situation | Route to |
|-----------|----------|
| Promotion complete, G6 passed | `verifying-promotion` / verification skills |
| G6 failed, deviations fixable by re-apply | Re-enter Step 3 for affected files |
| G6 failed, change set itself is wrong | `writing-change-set` (revise the plan) |
| Manifest incomplete or inconsistent | `writing-change-set` (fix the manifest) |
| Change set not approved | `review-protocol` (run G5 first) |
