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
| Reviews and audits | **Never** | Read-only analysis |

## Rules

1. **All worktrees live under `.worktrees/`** — never `/tmp/`, never a sibling directory.
   Exception: `framework-test` eval tier-2 uses temp dirs (not real worktrees).

2. **`.worktrees/` must be in `.gitignore`** — enforced by `scripts/worktree.sh preflight`
   and validated by `framework-test/evals/tier-1/validate-worktree-safety.sh`.

3. **One worktree per branch** — the branch name is the worktree directory name.

4. **Clean up after promotion** — `promoting-change-set` calls `scripts/worktree.sh remove`
   after a successful squash-merge.

5. **No orphans** — `scripts/worktree.sh cleanup` finds and removes stale worktrees.
   Run periodically or before creating new ones.

## Usage

```bash
# Create a worktree for a feature
scripts/worktree.sh create feature-notifications

# Create from a specific base
scripts/worktree.sh create bugfix-auth --from main

# List active worktrees
scripts/worktree.sh list

# Remove after promotion
scripts/worktree.sh remove feature-notifications

# Force-remove (discards uncommitted changes)
scripts/worktree.sh remove feature-notifications --force

# Clean up orphans
scripts/worktree.sh cleanup

# Run safety checks only
scripts/worktree.sh preflight
```

## Lifecycle

```
main ─────────────────────────────────────────────────► main
      │                                          ▲
      │ worktree.sh create feature-x             │ worktree.sh remove feature-x
      ▼                                          │
   .worktrees/feature-x ─── work ─── promote ────┘
```

1. **Create** — `scripts/worktree.sh create <branch>` runs preflight, creates worktree,
   installs dependencies, runs baseline tests.
2. **Work** — `executing-change-set` runs inside the worktree. Each task is TDD:
   write test → fail → implement → pass → checkpoint commit.
3. **Promote** — `promoting-change-set` squash-merges the worktree branch to main.
4. **Remove** — `scripts/worktree.sh remove <branch>` cleans up the worktree and
   deletes the branch if merged.

## Progressive Mode Integration

In `--progressive` mode, the chain handles worktree lifecycle automatically:

- `writing-change-set` outputs the manifest and suggests the branch name.
- `executing-change-set` creates the worktree (if not already in one) via
  `scripts/worktree.sh create`.
- `promoting-change-set` merges and removes via `scripts/worktree.sh remove`.
- If the chain is interrupted, `scripts/worktree.sh cleanup` recovers.
