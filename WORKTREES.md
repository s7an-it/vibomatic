# Worktree Model

All feature work that produces code runs in a git worktree under `.worktrees/`.
Worktrees isolate in-progress changes from main, enable parallel work, and
make promotion (squash-merge to main) clean.

## When to Create a Worktree

| Condition | Worktree? | Why |
|-----------|-----------|-----|
| `executing-change-set` | **Always** | Implementation code must never land directly on main |
| `promoting-change-set` | **Always** | Squash-merge requires a source branch in a worktree |
| `framework-test` autopilot | **Always** | Scenarios must run in isolation |
| Parallel feature work | **Always** | Each feature gets its own worktree |
| `writing-change-set` with simulation | Optional | If simulation needs to test file creation |
| `writing-technical-design` with prototype | Optional | If prototyping architecture |
| Spec writing (`writing-spec`) | **Never** | Single-file edits, safe on main |
| Vision/persona/journey work | **Never** | Foundational docs, safe on main |
| Reviews and audits (`review-protocol`) | **Never** | Read-only analysis from main via `git diff` |

## Per-Lane Worktree Map

| Lane | On main (planning) | In worktree (build + validate) | On main (merge + verify) |
|------|--------------------|-------------------------------|--------------------------|
| **Greenfield** | vision-sync → writing-change-set | executing, review-protocol, E2E | promoting, verifying-promotion |
| **Brownfield Feature** | spec-code-sync → writing-change-set | executing, review-protocol, E2E | promoting, verifying-promotion |
| **Bugfix** | bugfix-brief, writing-change-set | executing, review-protocol, E2E | promoting, verifying-promotion |
| **Refactor** | spec-code-sync, writing-change-set | executing, review-protocol, E2E | promoting, verifying-promotion |
| **Brownfield Conversion** | entire lane on main | — | — |
| **Drift** | entire lane on main | — | — |

**The worktree IS the feature branch.** Code, tests, E2E, and review all run
inside it. The feature must be fully validated before it leaves the worktree.
Only the squash-merge (`promoting-change-set`) and post-merge verification
(`verifying-promotion`) run on main.

## Branch Naming Convention

| Lane | Pattern | Example |
|------|---------|---------|
| Greenfield / Brownfield Feature | `feature-<name>` | `feature-notifications` |
| Bugfix | `bugfix-<name>` | `bugfix-auth-500` |
| Refactor | `refactor-<name>` | `refactor-api-layer` |
| Framework Test | `test-<name>` | `test-autopilot-s1` |

The branch name is defined in the `writing-change-set` manifest header.

## Rules

1. **All worktrees live under `.worktrees/`** — never `/tmp/`, never a sibling directory.
   Exception: `framework-test` eval tier-2 uses temp dirs (not git worktrees).

2. **`.worktrees/` must be in `.gitignore`** — enforced by `scripts/worktree.sh preflight`
   and validated by `framework-test/evals/tier-1/validate-worktree-safety.sh`.

3. **One worktree per branch** — the branch name is the worktree directory name.

4. **Create is idempotent** — `worktree.sh create` on an existing worktree reports it
   and exits 0, enabling chain resume after interruption.

5. **Clean up after promotion** — `promoting-change-set` Step 7 calls `worktree.sh remove`.

6. **No orphans** — `worktree.sh cleanup` finds and removes stale worktrees.

## Commands

```bash
# Create a worktree (idempotent — resumes if exists)
scripts/worktree.sh create feature-notifications

# Create from a specific base
scripts/worktree.sh create bugfix-auth --from main

# Check if you're in a worktree
scripts/worktree.sh status

# Enter an existing worktree (shows cd command)
scripts/worktree.sh enter feature-notifications

# Promote: squash-merge to main (stages but does not commit)
scripts/worktree.sh promote feature-notifications

# Remove after promotion
scripts/worktree.sh remove feature-notifications

# Force-remove (discards uncommitted changes)
scripts/worktree.sh remove feature-notifications --force

# List all active worktrees with status
scripts/worktree.sh list

# Find and remove orphans
scripts/worktree.sh cleanup

# Run safety checks only
scripts/worktree.sh preflight
```

## Worktree Guard (automatic detection)

Every skill should call the guard at startup to detect if it's in the right place:

```bash
scripts/worktree.sh guard --skill <skill-name> --lane <lane> --branch <branch>
```

The guard returns one of four actions:

| Action | Meaning | What to do |
|--------|---------|------------|
| `STAY_MAIN` | Skill runs on main, already there | Proceed normally |
| `NEED_WORKTREE` | Skill needs a worktree | Guard creates/enters it automatically |
| `IN_WORKTREE` | Skill needs a worktree, already in one | Proceed normally |
| `LEAVE_WORKTREE` | Skill runs on main but we're in a worktree | `cd` back to repo root |

The guard knows which skills need worktrees, which lanes never use them, and
handles the transitions. Skills don't need to hard-code worktree logic — they
call the guard and follow the action.

**Key transitions the guard handles:**
- `writing-change-set` → `executing-change-set`: NEED_WORKTREE — creates it
- `executing-change-set` → `review-protocol`: IN_WORKTREE — review runs in the branch
- `review-protocol` → `agentic-e2e-playwright`: IN_WORKTREE — E2E runs in the branch
- All validated → `promoting-change-set`: LEAVE_WORKTREE — squash-merge from main
- `promoting-change-set` → `verifying-promotion`: STAY_MAIN — worktree removed

The flow is: **main (plan) → worktree (build + test + review) → main (merge + verify)**.
The feature must be fully validated inside the worktree before it touches main.

## Lifecycle

```
main ─────────────────────────────────────────────────► main
      │                                          ▲
      │ worktree.sh create feature-x             │ worktree.sh remove feature-x
      ▼                                          │
   .worktrees/feature-x ─── work ─── promote ────┘
```

1. **Create** — `executing-change-set` Step 0 calls the guard, which creates the
   worktree, runs project setup, and checks baseline tests. Idempotent for resume.

2. **Build** — `executing-change-set` runs inside the worktree. Each task is TDD:
   write test → fail → implement → pass → checkpoint commit.

3. **Validate** — still inside the worktree:
   - `review-protocol` reviews the code in the branch
   - `agentic-e2e-playwright` runs E2E tests against the branch
   - All tests must pass before the feature leaves the worktree

4. **Promote** — `promoting-change-set` switches to main, runs `worktree.sh promote`.
   Squash-merges the branch, stages the diff for G6 review. After G6 pass, commit.

5. **Remove** — `promoting-change-set` runs `worktree.sh remove <branch>` after commit.
   Removes directory and deletes the merged branch.

6. **Verify** — `verifying-promotion` runs on main, confirms the merge is clean.

## Interruption Recovery

If a chain is interrupted (session ends, token limit, crash):

1. **Check what's live:** `scripts/worktree.sh list`
2. **See worktree status:** `scripts/worktree.sh enter <branch-name>`
3. **Resume execution:** re-invoke `executing-change-set` — Step 0 detects the
   existing worktree via `worktree.sh create` (idempotent) and picks up where
   the manifest checkpoints left off.
4. **If the worktree is stale:** `scripts/worktree.sh remove <branch> --force`
5. **Clean all orphans:** `scripts/worktree.sh cleanup`

The manifest's task checkpoints (commit per task) serve as resume markers.
`executing-change-set` reads checkpoint commits to know which tasks are done.
