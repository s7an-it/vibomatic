---
name: promoting-change-set
description: Use when an executed change set has passed G5 review and the reviewed branch state should be promoted to main via squash merge — validates manifest file set, branch diff, and promotion readiness, then triggers G6 review
inputs:
  required:
    - { path: "docs/plans/<date>-<name>/manifest.md", artifact: implementation-manifest }
  optional: []
outputs:
  produces:
    - { path: "(squash merge on main)", artifact: promoted-code, status: PROMOTED }
chain:
  lanes:
    greenfield: { position: 13, prev: executing-change-set, next: verifying-promotion }
    brownfield-feature: { position: 10, prev: review-protocol, next: verifying-promotion }
    bugfix: { position: 5, prev: review-protocol, next: verifying-promotion }
    refactor: { position: 5, prev: review-protocol, next: verifying-promotion }
  progressive: true
  self_verify: true
  human_checkpoint: true
---

# Promoting Change Set

Promotion is no longer "copy code from docs into the repo."

The branch already contains the reviewed implementation. Promotion validates that
the branch state matches the implementation manifest, then squash-merges it.

**Announce at start:** "I'm using the promoting-change-set skill to promote the reviewed branch state."

## Prerequisites

| Artifact | Where | Required? |
|----------|-------|-----------|
| Implementation manifest | `docs/plans/<date>-<name>/manifest.md` | Yes |
| Reviewed feature branch | git branch/worktree | Yes |
| G5 approval evidence | task checkpoints + final review output | Yes |
| Feature spec | `docs/specs/features/<name>.md` | Yes |

Do not start promotion if execution is incomplete or G5 has not passed.

## Promotion Surface

Canonical promotion inputs:

- feature branch diff relative to base
- manifest file list
- task checkpoint history
- validation results

Promotion is based on git state, not markdown code payloads.

## Process

### Step 1: Read the manifest

Extract:

- branch name
- base branch and SHA
- planned file set
- validation commands
- checkpoints

### Step 2: Compare branch diff to manifest

Use git diff to check:

- every changed file is in the manifest
- every manifest file appears in the diff, unless explicitly omitted by updated plan
- no unexpected additions
- no silent omissions

This is the G6 evidence surface.

### Step 3: Confirm checkpoint history

Verify:

- required task checkpoints exist
- ordering is sensible
- no unfinished task is being promoted

### Step 4: Run final validation commands

Run the manifest’s final validation commands before promotion.

### Step 5: Squash merge

Promotion is:

```bash
git checkout main
git merge --squash feature-<name>
```

Then inspect the staged squash diff before commit.

### Step 6: G6 review

G6 checks:

- squash diff matches manifest file set
- no unplanned changes
- validation clean
- execution history complete enough to trust the branch state

If G6 passes:

- commit squash merge
- update feature status to `PROMOTED`

If G6 fails:

- do not promote
- route back to execution or planning depending on the defect

## Anti-Patterns

- Do not reapply code from docs
- Do not promote a branch with missing task checkpoints
- Do not treat extra branch changes as acceptable drift
- Do not skip squash-diff inspection

## Handoff

After successful promotion:

- route to `verifying-promotion`

## Pipeline Continuation

### Self-Verify

Before declaring done, verify:

| # | Check | How | PASS/FAIL |
|---|-------|-----|-----------|
| 1 | Squash merge staged on main | `git diff --cached --stat` shows expected files | |
| 2 | Diff matches manifest file set | Compare `git diff --cached --name-only` against manifest planned file set; no unplanned additions | |
| 3 | No unresolved questions | grep for TBD, TODO, open questions in manifest and diff | |

If any check FAILs, fix before continuing. If a fix requires upstream changes, stop and report.

### Chaining

**If `--progressive` flag is present AND self-verify passed:**
- Check `--skip` list. If this skill is in the skip list, pass through to next.
- Invoke next skill: `verifying-promotion --progressive --lane <lane>`

**If `--progressive` flag is absent:**
- Report results to user
- Suggest: "Next: consider running `verifying-promotion`"
