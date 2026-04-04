---
name: executing-change-set
description: >
  Execute a vibomatic implementation plan directly in the worktree. Use after
  writing-change-set has produced a manifest and task graph. Applies tasks on the
  branch, stages only the current task diff, reviews it, creates checkpoint commits,
  and supports loop-backs when implementation reveals defects in earlier phases.
inputs:
  required:
    - { path: "docs/plans/<date>-<name>/manifest.md", artifact: implementation-manifest }
    - { path: "docs/specs/features/<name>.md", artifact: feature-spec }
  optional:
    - { path: "docs/specs/style-contract.md", artifact: style-contract }
outputs:
  produces:
    - { path: "(branch checkpoint commits)", artifact: executed-code }
chain:
  lanes:
    greenfield: { position: 13, prev: writing-change-set, next: systems-analysis }
    brownfield-feature: { position: 9, prev: writing-change-set, next: review-protocol }
    bugfix: { position: 3, prev: writing-change-set, next: review-protocol }
    refactor: { position: 3, prev: writing-change-set, next: review-protocol }
  progressive: true
  self_verify: true
  human_checkpoint: true
---

# Executing Change Set

The change set is the branch state, not markdown code payloads.

This skill takes the implementation manifest from `writing-change-set` and carries
it out directly in the worktree. It stages one task at a time, reviews the staged
diff, creates a checkpoint commit when the task is accepted, and moves to the next task.

**Announce at start:** "I'm using the executing-change-set skill to apply the implementation plan directly in the worktree."

## Inputs

Read and hold in context:

| Artifact | Path | Purpose |
|----------|------|---------|
| Implementation manifest | `docs/plans/<date>-<name>/manifest.md` | Task graph, file set, validation plan |
| Feature spec | `docs/specs/features/<name>.md` | ACs, dependencies, status |
| UX/UI/tech design | `docs/specs/ux/<name>.md`, `docs/specs/ui/<name>.md`, technical design section | Execution constraints |
| Journeys | `docs/specs/journeys/J*-<name>.feature.md` | Flow constraints |
| Domain profile | `docs/specs/domain-profile.md` | Industry context, tech conventions |
| Domain conventions | `references/domains/*/conventions.md` | Framework-specific patterns |
| Style contract | `docs/specs/style-contract.md` | Naming, imports, test patterns |
| Existing code | source tree | Current patterns and boundaries |

## Core Rules

- The worktree branch is the actual implementation artifact.
- Stage only the current task's changes.
- Review `git diff --staged` for the active task before checkpointing.
- Create a lightweight checkpoint commit after each accepted task.
- If a task reveals a spec, UX, UI, or tech-design defect, loop back before continuing.

## Task Execution Model

Each task in the manifest should define:

- task id and title
- touched files
- dependencies
- AC slice covered
- validation command
- checkpoint name

Suggested task sequence:

1. `task-1-types`
2. `task-2-data-model`
3. `task-3-tests-unit`
4. `task-4-services`
5. `task-5-components`
6. `task-6-e2e`
7. `task-7-spec-updates`
8. `task-8-journey-updates`

## Process

### Step 0: Worktree Guard

Implementation code must never land directly on main. Run the worktree guard:

```bash
scripts/worktree.sh guard --skill executing-change-set --lane <lane> --branch <branch-name>
```

The guard handles all scenarios:
- **NEED_WORKTREE** → creates the worktree (idempotent — resumes if exists), runs setup and baseline tests
- **IN_WORKTREE** → already in the right place, proceed
- **STAY_MAIN** → should not happen for this skill (guard will warn)

The branch name comes from the manifest header. Convention: `feature-<name>`, `bugfix-<name>`, `refactor-<name>`.

After the guard, `cd` into `.worktrees/<branch-name>` if not already there.

See `WORKTREES.md` for the full lifecycle.

### Step 1: Read the manifest and confirm branch state

Extract:

- branch name
- base SHA
- task order
- expected files
- validation commands

Verify the branch is clean before starting a task.

### Step 2: Execute one task at a time

For each task:

1. **If the task produces implementation code (services, routes, components):**
   - Write the test FIRST (unit test for the behavior this task implements)
   - Run the test — it MUST FAIL (proves the test tests something real)
   - Write the minimal implementation to make the test pass
   - Run the test — it MUST PASS
   - This is TDD red-green per task. Not optional for implementation tasks.

2. **Skip TDD for:** type definitions, config files, migrations (no behavior to test), pure scaffolding, spec/journey updates. These tasks are written and staged directly.

3. Stage only the files for that task (test + implementation together)
4. Inspect `git diff --staged`
5. Compare the staged diff against:
   - task intent
   - AC slice
   - design constraints
   - style contract (if `docs/specs/style-contract.md` exists)
   - domain conventions (if `references/domains/` pack exists for the tech stack)
6. Run the task validation command
7. If acceptable, create checkpoint commit:
   - `checkpoint: task-N-<name>`
8. Continue to the next task

### Step 3: Task review

Task review surface:

```bash
git diff --staged
```

Check:

- only expected files changed
- no unrelated edits
- no placeholders
- task intent satisfied
- validation passed

Task review is local to the task. Full-feature review still happens before promotion.

### Step 4: Loop-back rules

If execution reveals a defect in earlier phases:

- spec ambiguity -> loop back to `writing-spec`
- UX flow impossible -> loop back to `writing-ux-design`
- UI/design-system insufficiency -> loop back to `writing-ui-design`
- technical infeasibility -> loop back to `writing-technical-design`

Do not patch through phase defects silently.

After correction, resume from the last good checkpoint rather than starting over.

### Step 5: Final G5 surface

After all tasks are complete:

- review the full feature diff against `main`
- ensure all manifest files are represented
- ensure task checkpoints are complete
- confirm AC-to-task and AC-to-test coverage

This is the final G5 review input.

## Checkpoints

Required naming:

- `checkpoint: task-1-types`
- `checkpoint: task-2-data-model`
- `checkpoint: task-3-tests`
- `checkpoint: task-4-services`
- `checkpoint: task-5-components`
- `checkpoint: task-6-e2e`
- `checkpoint: task-7-spec-updates`
- `checkpoint: task-8-journey-updates`

Use phase checkpoints from earlier phases as rollback anchors when a loop-back crosses phases.

## What Not To Do

- Do not serialize exact code into docs for later reapplication
- Do not stage multiple unrelated tasks together
- Do not continue past a phase contradiction without looping back
- Do not leave task boundaries implicit

## Handoff

When all tasks are complete and final G5 passes:

- feature status -> `CHANGE-SET-APPROVED`
- route to `landing-change-set`

## Pipeline Continuation

### Self-Verify

Before declaring done, verify:

| # | Check | How | PASS/FAIL |
|---|-------|-----|-----------|
| 1 | All manifest tasks have checkpoint commits | `git log --oneline` shows checkpoint commits for every task in the manifest | |
| 2 | No TODO/FIXME in committed code | `grep -r 'TODO\|FIXME' <changed-files>` returns empty | |
| 3 | Validation commands passed | All task-level and branch-level validation commands exit 0 | |
| 4 | No unresolved questions | grep for TBD, TODO, open questions in manifest or committed code | |

If any check FAILs, fix before continuing. If a fix requires upstream changes, stop and report.

### Chaining

**If `--progressive` flag is present AND self-verify passed:**
- Check `--skip` list. If this skill is in the skip list, pass through to next.
- In greenfield lane: invoke `landing-change-set --progressive --lane greenfield`
- In brownfield-feature/bugfix/refactor lanes: invoke `review-protocol --progressive --lane <lane>`

**If `--progressive` flag is absent:**
- Report results to user
- In greenfield lane: suggest "Next: consider running `landing-change-set`"
- In brownfield-feature/bugfix/refactor lanes: suggest "Next: consider running `review-protocol`"
