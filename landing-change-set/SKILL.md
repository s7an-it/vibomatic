---
name: landing-change-set
description: Use when an executed change set has been validated (tests, E2E, review all pass in the worktree) and is ready to land on main — validates manifest coverage, pushes branch, opens PR, merges via squash, cleans up worktree
inputs:
  required:
    - { path: "docs/plans/<date>-<name>/manifest.md", artifact: implementation-manifest }
  optional: []
outputs:
  produces:
    - { path: "(PR merged to main)", artifact: landed-code, status: PROMOTED }
chain:
  lanes:
    greenfield: { position: 15, prev: systems-analysis, next: verifying-promotion }
    brownfield-feature: { position: 12, prev: systems-analysis, next: verifying-promotion }
    bugfix: { position: 6, prev: systems-analysis, next: verifying-promotion }
    refactor: { position: 6, prev: systems-analysis, next: verifying-promotion }
  progressive: true
  self_verify: true
  human_checkpoint: true
---

# Landing Change Set

Land validated work from a feature worktree onto main via PR.

By the time this skill runs, the feature has been built, tested (unit + E2E),
and reviewed — all inside the worktree. This skill validates that the branch
matches the plan, then lands it through a proper PR flow.

**Announce at start:** "I'm using the landing-change-set skill to land the validated branch onto main."

## Prerequisites

| Artifact | Where | Required? |
|----------|-------|-----------|
| Implementation manifest | `docs/plans/<date>-<name>/manifest.md` | Yes |
| Validated feature branch | `.worktrees/<branch-name>` | Yes |
| G5 approval evidence | task checkpoints + review output | Yes |
| Tests passing | all tests green in the worktree | Yes |
| Feature spec | `docs/specs/features/<name>.md` | Yes |

Do not start landing if tests are failing or G5 has not passed.

## Process

### Step 1: Validate in the worktree

Run these checks inside the worktree (where the code lives):

**1a. Read the manifest** — extract branch name, planned file set, validation commands, checkpoints.

**1b. Compare branch diff to manifest:**

```bash
git diff --name-only main..HEAD
```

Check:
- every changed file is in the manifest
- every manifest file appears in the diff
- no unexpected additions or silent omissions

**1c. Confirm checkpoint history** — all task checkpoints exist, ordering is sensible, no unfinished tasks.

**1d. Run final validation commands** — execute the manifest's validation commands one last time. All must pass.

If any check fails, fix in the worktree before proceeding.

### Step 2: Ship Preparation

Before pushing, prepare the release. Commit order matters for bisectability:
1. Infrastructure changes (config, build, CI) first
2. Models + their tests
3. Controllers/services + their tests
4. VERSION + CHANGELOG last (single atomic commit)

**2a. Version bump** — 4-digit `MAJOR.MINOR.PATCH.MICRO` format:

Read current version from `package.json`, `VERSION`, `Cargo.toml`, or equivalent.

**Idempotency check first:** compare the VERSION value on the base branch vs HEAD.
If already bumped (values differ), skip the bump entirely.

```bash
BASE_VERSION=$(git show main:VERSION 2>/dev/null || echo "0.0.0.0")
HEAD_VERSION=$(cat VERSION 2>/dev/null || echo "0.0.0.0")
if [ "$BASE_VERSION" != "$HEAD_VERSION" ]; then
  echo "VERSION already bumped ($BASE_VERSION -> $HEAD_VERSION), skipping"
fi
```

Bump level rules:
- **MICRO** (+0.0.0.1): fewer than 50 changed lines, trivial fix, no new files
- **PATCH** (+0.0.1.0): 50+ changed lines, no feature signals
- **MINOR** (+0.1.0.0): feature signals detected — ASK user before bumping
  - Feature signals: new routes, new migrations, new test files, `feat/` branch prefix
- **MAJOR** (+1.0.0.0): milestones only — ALWAYS ASK user

Bumping a digit resets all digits to its right to 0.
Example: `1.3.2.7` with PATCH bump becomes `1.3.3.0`.

**2b. CHANGELOG update**:

1. Read the existing CHANGELOG.md header to match its formatting style
2. Enumerate all commits on the branch: `git log --oneline main..HEAD`
3. Group changes by theme using conventional headings:
   - **Added** — new capabilities the user can now use
   - **Changed** — modifications to existing behavior
   - **Fixed** — bug fixes
   - **Removed** — features or code removed
4. Lead each bullet with what the user can now DO, not what the code does
   - Good: "Users can now reset passwords via email link"
   - Bad: "Added resetPassword() method to AuthService"
5. Cross-check: every commit in the log MUST map to at least one bullet.
   If a commit is missing, either add a bullet or justify the omission (e.g., pure refactor with no user-visible change).
6. Create `CHANGELOG.md` if it doesn't exist

**2c. Test audit** with coverage diagram:

Run the full test suite one final time. Report: total tests, passing, failing, new tests added.
If any tests fail: STOP — fix in worktree before proceeding.

Then produce a code path coverage diagram for every changed source file:

```
CODE PATH COVERAGE
[+] src/services/billing.ts
    ├── processPayment()
    │   ├── [★★★ TESTED] Happy path + card declined
    │   └── [GAP] Network timeout — NO TEST
    ├── refundPayment()
    │   └── [★★ TESTED] Happy path only
[+] src/controllers/checkout.ts
    ├── handleCheckout()
    │   └── [★ TESTED] Smoke test, no edge cases
```

Quality ratings:
- ★★★ — edge cases covered (happy path + error paths + boundary conditions)
- ★★ — happy path tested
- ★ — smoke test only (function called, result not deeply verified)

**Coverage gate:**
- Default minimum: 60% of changed code paths must have at least ★ coverage
- Target: 80% of changed code paths at ★★ or above
- If below minimum: WARN and ask user whether to proceed or write more tests

### Step 3: Push the branch

Still in the worktree:

```bash
git push -u origin <branch-name>
```

### Step 3: Switch to main and open PR

```bash
scripts/worktree.sh guard --skill landing-change-set --lane <lane> --branch <branch-name>
cd <repo-root>
```

Create the PR:

```bash
gh pr create \
  --title "<type>: <short description>" \
  --body "## Summary
<what this changes and why>

## Manifest
docs/plans/<date>-<name>/manifest.md

## Validation
- [ ] All task checkpoints present
- [ ] Branch diff matches manifest file set
- [ ] Tests pass (unit + E2E)
- [ ] G5 review passed
"
```

PR title convention:
- `feat: <description>` for greenfield / brownfield features
- `fix: <description>` for bugfix lane
- `refactor: <description>` for refactor lane

### Step 4: Merge or wait for approval

**Solo / auto-approve mode** (`--auto-approve` or solo contributor):

Merge immediately:

```bash
gh pr merge <pr-number> --squash --delete-branch
```

Then continue to Step 5.

**Team / review-required mode** (default for external projects or when reviewers are assigned):

Stop here. The PR is open and waiting for approval.

```
Landing paused — PR #<number> open, waiting for approval.
Worktree preserved at .worktrees/<branch-name>.
Resume after merge: scripts/worktree.sh remove <branch-name>
```

The worktree stays alive so fixes can be pushed if reviewers request changes.
When the PR is approved and merged (by a teammate or CI), resume with Step 5.

**How to detect which mode:**
- If `gh pr view <number> --json reviewRequests` shows reviewers → wait
- If the repo has branch protection rules requiring approvals → wait
- If `--auto-approve` flag is set → merge immediately
- If solo contributor (no reviewers, no protection) → merge immediately

### Step 5: Clean up worktree (after merge)

After the PR is merged (either by you or by a reviewer):

```bash
git checkout main && git pull
scripts/worktree.sh remove <branch-name>
```

This removes `.worktrees/<branch-name>` and deletes the local branch.

### Step 6: Update spec status

Update the feature spec status to `PROMOTED`:

```
**Status:** PROMOTED
```

## Anti-Patterns

- Do not land a branch with failing tests
- Do not land without a PR (no local squash-merges)
- Do not land with missing task checkpoints
- Do not land files not in the manifest
- Do not skip the final validation run

## Pipeline Continuation

### Self-Verify

Before declaring done, verify:

| # | Check | How | PASS/FAIL |
|---|-------|-----|-----------|
| 1 | PR was created | `gh pr view <number>` shows the PR | |
| 2 | PR was merged OR waiting for approval | `gh pr view <number> --json state` shows MERGED or OPEN | |
| 3 | If merged: worktree removed | `.worktrees/<branch>` no longer exists | |
| 4 | If merged: spec updated | spec shows `PROMOTED` status | |

If waiting for approval: checks 1-2 pass (PR exists and is OPEN). Checks 3-4 are
deferred until the PR is merged. Report the PR URL and stop — do not chain to
`verifying-promotion` until the PR is merged.

### Chaining

**If PR was merged (auto-approve or post-approval):**
- If `--progressive`: invoke `verifying-promotion --progressive --lane <lane>`
- If not progressive: suggest "Next: run `verifying-promotion`"

**If PR is open and waiting for approval:**
- Stop the progressive chain. Report:
  "PR #<number> open, waiting for approval. After merge, run:
  `scripts/worktree.sh remove <branch>` then `verifying-promotion`"
- The chain resumes in a future session after the PR is merged.
