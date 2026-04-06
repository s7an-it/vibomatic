---
name: execute-changeset
description: >
  Execute a svc implementation plan directly in the worktree. Use after
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

**Context loading rule:** Do NOT scan the full source tree. Load code files
ONLY from these sources, in this priority:
1. **Manifest file list** — the manifest names every file to create/modify
2. **Spec RESOLVED annotations** — file:line pointers to existing implementations
3. **Import resolution** — when a manifest file imports from another file, load that file
4. **On-demand** — if a test fails referencing an unknown file, load it then

This scoped loading eliminates 30-100K tokens of irrelevant code. The style
contract already encodes the project's patterns — you don't need to re-derive
them from source.

## Core Rules

- **Write once.** Code is written directly on the branch — not described in
  a plan and re-implemented. The manifest provides intent and constraints.
  The execution produces code. The diff IS the changeset. No double-spend.
- Stage only the current task's changes.
- Create a lightweight checkpoint commit after each accepted task.
- **No per-task quality review.** Style contract + spec constraints are
  sufficient per task. One holistic review of the full diff after ALL tasks.
- If a task reveals a spec, UX, UI, or tech-design defect, loop back before continuing.

## Execution Architecture

### Model assignment

| Role | Model | Effort | What it does |
|------|-------|--------|-------------|
| **Orchestrator** | Opus | medium | Reads manifest, identifies parallel groups, detects conflicts, spawns subagents, runs holistic review |
| **Implementor** | Sonnet | medium-high | Receives task + context, writes test → writes code → runs test → commits |

The orchestrator does NOT write code. It coordinates. Implementor subagents
write code. This separation means the expensive model (Opus) spends tokens
on decisions, and the fast model (Sonnet) spends tokens on generation.

### Task graph execution

```
1. Read manifest → extract task graph with dependencies
2. Identify parallel groups (tasks with no mutual dependencies)
3. For each group:
   a. Check file overlap within the group
   b. No overlap → spawn all subagents on same branch
   c. Overlap detected → spawn into inner worktrees (see below)
4. Wait for group to complete
5. Merge inner worktrees if used
6. Move to next group (which may depend on this one)
7. After ALL groups: holistic review
```

### Inner worktrees for parallel conflicts

When tasks in a parallel group touch overlapping files, use inner worktrees:

```
.worktrees/feature-payments/                    (parent — execution branch)
  ├── .worktrees/task-3-validator/              (inner — isolated)
  ├── .worktrees/task-4-webhook/                (inner — isolated)
  └── .worktrees/task-5-receipt/                (inner — isolated)
```

The orchestrator decides:
- **Disjoint file sets** → run on parent branch, no isolation needed
- **Overlapping files** → inner worktree per task, merge after completion
- **Hydration dependency** (task B needs types from task A) → task A runs
  first, task B gets its output via the dependency graph

After inner worktrees complete, merge them to the parent branch sequentially.
If a merge conflict occurs, the orchestrator resolves it (or escalates).

### Subagent context (what each implementor receives)

Each implementor subagent gets ONLY what it needs. The orchestrator constructs
the prompt using this exact template:

```
You are implementing one task from a feature implementation plan.

## Your constraints
- Write code ONLY for the files listed below. Do not create files not in the file list.
- Do NOT grep, find, or scan the codebase. You have all the context you need below.
- Do NOT read files not listed in your context. If you encounter an unknown import,
  report it back to the orchestrator — do not resolve it yourself.
- Follow the style contract exactly. Do not invent conventions.
- TDD: write the test FIRST, run it (must FAIL), then write implementation (must PASS).

## Style contract
[INSERT docs/specs/style-contract.md content]

## Your task
[INSERT task intent, id, checkpoint name from manifest]

## Acceptance criteria (your slice only)
[INSERT only the AC rows this task covers — not the full AC table]

## Technical design (your component only)
[INSERT the relevant section from the tech design — not the full design]

## Existing code (targeted files only)
[INSERT content of ONLY the files listed in this task's "touched files" + any
files referenced by RESOLVED annotations for the ACs this task covers.
Nothing else.]

## File list (you may ONLY create/modify these files)
[INSERT the touched files from the manifest for this task]

## Validation command
[INSERT the validation command for this task]
```

This is ~20-35K tokens per subagent, not 100K+. The subagent does NOT re-read
the full spec, all designs, all journeys. It gets the slice it needs.

**The "do not scan" constraint is critical.** Without it, a Sonnet subagent
encountering an unfamiliar import will grep the entire codebase to resolve it,
wasting 20-50K tokens. The constraint forces it to report back instead, letting
the orchestrator provide the specific file on demand.

## Task Execution Model

Each task in the manifest defines:

- task id and title
- touched files
- dependencies (other task IDs)
- AC slice covered
- validation command
- checkpoint name
- parallel group (tasks in the same group can run concurrently)

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
2. Mock implementations live in `src/mocks/` or equivalent
3. Tests run against mocks — never against live paid services
4. The mock must be realistic enough to exercise the AC (not just `return true`)
5. Document which dependencies are mocked in the manifest under "Mocked Dependencies"
6. Every external integration has both a mock and real implementation, selected by feature toggle
7. Feature toggles default to mock ON / real OFF
8. Create or update `docs/specs/toggle-registry.md` listing every toggle, its default, and per-environment state

**Feature toggle enforcement:**
- Before writing any integration code, check the tech design for the toggle
  mechanism. If none is defined, stop and route back to `design-tech`.
- Implement the mock FIRST. Get it passing E2E. Then implement the real
  version behind the toggle. The mock is not scaffolding — it ships and
  stays as the local/test default permanently.
- The toggle registry is a deliverable, not an afterthought. It goes in
  the manifest file list alongside source code.

**First-demo test:** After the last task checkpoint, start the app with
default config (all toggles at default = mocks ON). Navigate the primary
journey. If anything fails, shows an error, or requires credentials — the
implementation is not done.

**Why:** The first iteration must be demoable, sellable, and locally complete.
External integrations are enabled per-environment by flipping toggles — not
by rewriting code.

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

### Step 2: Execute tasks (write directly)

**For sequential tasks** (or when running as single agent):

1. **If the task produces implementation code:**
   - Write the test FIRST (unit test for the behavior)
   - Run the test — it MUST FAIL (proves the test is real)
   - Write the minimal implementation to pass the test
   - Run the test — it MUST PASS
   - TDD red-green per task. Not optional for implementation tasks.

2. **Skip TDD for:** type definitions, config files, migrations, scaffolding,
   spec/journey updates.

3. Stage the task's files, run the validation command
4. Checkpoint commit: `checkpoint: task-N-<name>` (with trailers)
5. Move to next task — **no per-task quality review**

**For parallel task groups** (orchestrator mode):

1. Orchestrator identifies parallel group from manifest
2. Checks file overlap → decides: same branch or inner worktrees
3. Spawns one Sonnet subagent per task with scoped context
4. Each subagent: TDD → implement → validate → checkpoint
5. Orchestrator waits for all subagents to complete
6. If inner worktrees used: merge sequentially to parent
7. Continue to next group

**Why no per-task quality review:** The style contract constrains how code
looks. The spec ACs constrain what code does. TDD constrains correctness.
Per-task review catches nothing that these constraints don't already prevent,
and costs 5-10K tokens × N tasks. One holistic review at the end catches
cross-task issues that per-task reviews MISS.

### Step 3: Holistic review (replaces per-task review)

After ALL tasks are complete, review the full feature diff:

```bash
git diff main..HEAD
```

Check:
- Full AC coverage — every AC in the spec has code + test
- Cross-file consistency — no contradictions between tasks
- No orphaned code — nothing written that no AC requires
- Toggle registry complete — every external integration has mock + real + toggle
- Style contract compliance — one pass, not N passes
- No TODO/FIXME in committed code

This is one review pass instead of N. It catches cross-task issues
(duplicate logic, inconsistent naming, missing integration between components)
that per-task reviews inherently miss because they see each task in isolation.

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
