---
name: execute-changeset
description: >
  Execute a vibomatic implementation plan directly in the worktree. Use after
  plan-changeset has produced a manifest and task graph. Applies tasks on the
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
    greenfield: { position: 13, prev: plan-changeset, next: audit-implementation }
    brownfield-feature: { position: 9, prev: plan-changeset, next: review-gate }
    bugfix: { position: 3, prev: plan-changeset, next: review-gate }
    refactor: { position: 3, prev: plan-changeset, next: review-gate }
  progressive: true
  self_verify: true
  human_checkpoint: true
---

# Executing Change Set

The change set is the branch state, not markdown code payloads.

This skill takes the implementation manifest from `plan-changeset` and carries
it out directly in the worktree. It stages one task at a time, reviews the staged
diff, creates a checkpoint commit when the task is accepted, and moves to the next task.

**Announce at start:** "I'm using the execute-changeset skill to apply the implementation plan directly in the worktree."

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
scripts/worktree.sh guard --skill execute-changeset --lane <lane> --branch <branch-name>
```

The guard handles all scenarios:
- **NEED_WORKTREE** → creates the worktree (idempotent — resumes if exists), runs setup and baseline tests
- **IN_WORKTREE** → already in the right place, proceed
- **STAY_MAIN** → should not happen for this skill (guard will warn)

The branch name comes from the manifest header. Convention: `feature-<name>`, `bugfix-<name>`, `refactor-<name>`.

After the guard, `cd` into `.worktrees/<branch-name>` if not already there.

See `WORKTREES.md` for the full lifecycle.

### Step 0b: Local-First Execution

All implementation targets localhost. No cloud deployment variants.

**Deployment target:** always `localhost` (or `127.0.0.1`).

**Paid dependencies must be mocked:**

| Dependency type | Mock approach |
|----------------|---------------|
| Payment (Stripe, PayPal) | Local mock server or test-mode keys |
| Email (SendGrid, SES) | Console logger or local SMTP (mailhog) |
| SMS (Twilio) | Console logger |
| Storage (S3, GCS) | Local filesystem or MinIO |
| Auth (Auth0, Clerk) | Local JWT issuer or mock middleware |
| Search (Algolia, Elastic Cloud) | SQLite FTS or in-memory index |
| AI/ML APIs (OpenAI, etc.) | Recorded fixtures or deterministic stubs |
| CDN (Cloudflare, Fastly) | Direct serve from localhost |

**Rules:**
1. The app must start and work on `localhost` with zero external accounts
2. Mock implementations live in `src/mocks/` or equivalent, toggled by `NODE_ENV=development` or similar
3. Tests run against mocks — never against live paid services
4. The mock must be realistic enough to exercise the AC (not just `return true`)
5. Document which dependencies are mocked in the manifest under "Mocked Dependencies"

**Why:** Prove the feature works before introducing external dependencies.
External integrations are validated separately in a later integration pass,
not during initial implementation.

### Step 1: Read the manifest and confirm branch state

Extract:

- branch name
- base SHA
- task order
- expected files
- validation commands

Verify the branch is clean before starting a task.

### Persistence Model

Execution is a verified completion loop, not a one-pass attempt. For each task:

```
LOOP per task (max 5 iterations):
  1. Write test (RED)
  2. Run test → must FAIL
  3. Write implementation
  4. Run test → must PASS
  5. Run full test suite → must PASS (no regressions)
  6. Checkpoint commit (with trailers)
  7. VERIFY: does this task's AC actually pass? (not just tests — check the behavior)
  
  If step 5 fails (regression):
    → Fix the regression, re-run, iterate
    → If same error 3 times: STOP, report fundamental issue
    
  If step 7 fails (AC not satisfied):
    → Revise implementation, re-run from step 3
    → Log what was wrong in progress tracking
```

**Progress tracking** — maintain a task status file at `docs/plans/<name>/progress.md`:

```markdown
# Execution Progress

| Task | Status | Iterations | Last error | AC verified? |
|------|--------|------------|------------|-------------|
| task-1 | ✅ done | 1 | — | yes |
| task-2 | 🔄 in progress | 3 | regression in task-1 test | no |
| task-3 | ⏳ pending | 0 | — | — |
```

This file survives session interruption. When execution resumes (worktree.sh create is idempotent), read progress.md to know which tasks are done.

**3-strike rule for stuck tasks:**
If a task fails the same way 3 times in a row:
1. STOP attempting that task
2. Log the fundamental issue in progress.md
3. Ask: skip this task and continue? Or escalate?
4. Never silently retry forever

**Completion gate:**
Execution is NOT done until:
- Every task has `status: done` and `AC verified: yes`
- Full test suite passes
- No TODO/FIXME in committed code (checked at the end)

If any task is stuck (3 strikes), execution is BLOCKED — report and stop.

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

- spec ambiguity -> loop back to `write-spec`
- UX flow impossible -> loop back to `design-ux`
- UI/design-system insufficiency -> loop back to `design-ui`
- technical infeasibility -> loop back to `design-tech`

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

### Commit Protocol

Every checkpoint commit carries structured decision metadata as git trailers:

```
feat(api): add bookmark CRUD endpoints

Implement REST endpoints for create, read, update, delete bookmarks
with tag association and full-text search.

Constraint: SQLite FTS5 for search (local-first, no Elasticsearch)
Constraint: Tags are many-to-many, stored in junction table
Rejected: MongoDB for flexible schema | adds external dependency, violates local-first
Rejected: GraphQL | REST sufficient for this scope, less complexity
Confidence: high
Scope-risk: narrow
Not-tested: Search performance with >10K bookmarks
Directive: FTS5 index rebuilds on every write — monitor if write volume increases
```

**Trailers (include when applicable):**
- `Constraint:` — active constraint that shaped this decision
- `Rejected:` — alternative considered | reason for rejection  
- `Directive:` — warning for future modifiers of this code
- `Confidence:` — high | medium | low
- `Scope-risk:` — narrow | moderate | broad
- `Not-tested:` — edge case or scenario not covered by tests

**Why trailers matter:**
Git history becomes the decision log. `git log` shows not just WHAT changed but WHY. 
`Rejected:` trailers prevent future developers from re-proposing already-rejected approaches.
`Directive:` trailers are instructions that travel with the code.
`Not-tested:` trailers are honest about coverage gaps.

Skip trailers for trivial commits (typo fixes, formatting). Include for every implementation commit.

## What Not To Do

- Do not serialize exact code into docs for later reapplication
- Do not stage multiple unrelated tasks together
- Do not continue past a phase contradiction without looping back
- Do not leave task boundaries implicit

## Handoff

When all tasks are complete and final G5 passes:

- feature status -> `CHANGE-SET-APPROVED`
- route to `audit-implementation` (or `review-gate` in lanes that have it)

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
- In greenfield lane: invoke `audit-implementation --progressive --lane greenfield`
- In brownfield-feature/bugfix/refactor lanes: invoke `review-gate --progressive --lane <lane>`

**If `--progressive` flag is absent:**
- Report results to user
- In greenfield lane: suggest "Next: run `audit-implementation`"
- In brownfield-feature/bugfix/refactor lanes: suggest "Next: consider running `review-gate`"
