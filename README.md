# vibomatic

> Progressive Deterministic Development — a methodology for reliable agentic software engineering

A development methodology for the agentic era.

## The Problem

Large language models generate code through pattern matching. Given a spec,
an LLM produces different implementations on different runs — different
abstractions, different edge cases, different integration patterns. Each one
is confidently presented as correct. This is not a bug. It is how these
systems work.

Every methodology that goes from ticket to code, from spec to implementation,
from design to "let the agent figure it out" is accepting non-determinism as
a feature. Most of the time it works. Sometimes it doesn't. You find out in
QA, or in production, or when two agents implemented the same feature
differently in parallel branches.

Vibomatic rejects that.

## The Solution: Progressive Narrowing

Each phase constrains the space of possible outputs for the next phase. By the
time code is written, the implementation surface is tightly constrained — not by
pattern matching alone, but by the accumulated constraints from every prior phase.

```
Phase 1:  Vision              → infinite possibilities
Phase 2:  Personas            → narrows WHO
Phase 3:  Feature Spec        → narrows WHAT (stories, acceptance criteria)
Phase 4:  UX Design           → narrows HOW users experience it
Phase 5:  UI Design           → narrows HOW it looks
Phase 6:  Technical Design    → narrows HOW to build it
Phase 7:  Implementation      → narrows to ONE reviewed branch outcome
Phase 8:  Promotion           → squash-merges the worktree to main
Phase 9:  Verification        → proves the merge matches the manifest
```

At Phase 1, the agent is generating. By Phase 7, the agent is executing against
a constrained implementation plan inside a worktree branched from main. The
creative work happens in Phases 1-6 and in any explicit loop-backs. Phase 7 is
controlled execution with task reviews and checkpoints. Phase 8 is a squash
merge. Phase 9 is checking.

## Why This Works (Technical Argument)

An LLM's output variance is inversely proportional to the constraints in its
context window. More context = less variance. The progressive narrowing model
exploits this:

1. **Context loading.** Each phase reads ALL prior artifacts. The agent writing
   the change set has read the vision, personas, spec, UX design, UI design,
   technical design, journeys, and existing code. Every constraint is in context.

2. **Variance reduction.** A one-line ticket produces 50 implementations.
   A spec with 12 acceptance criteria produces 5. A detailed implementation
   manifest with explicit tasks, files, validations, and checkpoints reduces
   the remaining variance to a small, reviewable branch diff.

3. **Review before generation.** Traditional: agent generates code, human
   reviews code. Vibomatic: human reviews intent (spec, design, plan),
   then the agent executes that intent task by task on a branch. Reviewing
   intent early is cheaper than reviewing a fully improvised implementation late.

4. **Deterministic promotion.** The worktree IS the code. Promotion is
   `git merge --squash` to main. Deviations are detected by diffing the
   merged result against the manifest. Nothing is left to interpretation.

5. **Attention decay mitigation.** LLMs suffer from positional attention
   decay — tokens loaded early in context receive less attention during
   generation. Checkpoints (commits at each phase boundary) reset this by
   forcing the agent to re-read artifacts fresh. The worktree keeps all
   artifacts consistent and accessible as the agent's external memory.

## The Review Protocol

Every phase transition is gated by a structured review designed around LLM
failure modes:

```
Step 1: SELF-REVIEW      → agent reviews own work, produces findings
Step 2: SELF-JUDGMENT     → agent accepts/rejects own findings with reasoning
Step 3: CROSS-REVIEW      → second agent independently evaluates
Step 4: CONVERGENCE       → medium/low only = PASS; critical/high = fix; 3 iterations = escalate
```

This catches: agents missing own errors (Step 3), agents agreeing too easily
(Step 2 forces adversarial self-reasoning), review theater (severity classification
+ convergence criteria), infinite loops (3-iteration cap).

## The Pipeline

### Foundational Artifacts (created once, evolved)

| Artifact | Skill | Purpose |
|----------|-------|---------|
| Vision | `write-vision` | Product direction, boundaries, principles |
| Domain Profile | `analyze-domain` | Industry, tech stack, domain reference packs |
| Competitor Analysis | `analyze-competitors` | Competitive landscape, whitespace, differentiation |
| Personas | `build-personas` | Who uses this (human and system consumers) |
| Design System | `design-ui` | Visual language: tokens, typography, colors, spacing |

### Per-Feature Pipeline

| Phase | Skill | Produces | Gate |
|-------|-------|----------|------|
| 3. Discovery | `validate-feature` | Feature Ship Brief (8 business questions) | — |
| 3. Spec | `write-spec` | User stories, ACs, system dependencies | G1 |
| 3b. AC Audit | `audit-ac` | Rewritten/added acceptance criteria | — |
| 3c. Journeys | `write-journeys` | BDD journey docs (.feature.md) with AC traceability | — |
| 4. UX Design | `design-ux` | Screen flows, states, interactions | G2 |
| 5. UI Design | `design-ui` | Component specs, design tokens, visual hierarchy | G3 |
| 6. Technical Design | `design-tech` | Architecture, data model, feasibility | G4 |
| 6b. Alternatives | `explore-solutions` | Challenge baseline with alternative paradigms | — |
| 6c. Code Style | `define-code-style` | Code style contract for the project | — |
| 7. Plan | `plan-changeset` | Implementation manifest, task graph, AC/test mapping | — |
| 7b. Execute | `execute-changeset` | Code in worktree, staged diffs, checkpoint commits | G5 |
| 7c. Correctness | `audit-implementation` | Deep correctness audit before landing | — |
| 8. Promote | `land-changeset` | Squash merge to main, version bump, PR | G6 |
| 9. Verify | `verify-promotion` | VERIFIED status (spec-sync + QA + E2E proof) | G7 |

### Feature Spec Lifecycle

```
DRAFT → UX-REVIEWED → DESIGNED → BASELINED → CHANGE-SET-APPROVED → PROMOTED → VERIFIED
```

## Feature Types

Every feature spec carries a type that identifies its consumer:

| Type | Consumer | Example |
|------|----------|---------|
| Feature | Human user | Match discovery, chat, payments |
| Enabler | Other service | Score recalculation cron, email service |
| Integration | External system | Stripe webhooks, OAuth provider |

All types go through the same pipeline. The type changes the consumer, not the
rigor. Specifying a Feature automatically reveals every Enabler and Integration
it depends on (the cascade effect).

## Workflow Lanes

Vibomatic routes work into lanes based on repo state and change type.
Use `route-workflow` to detect the right lane automatically, or pick one manually.

### Greenfield

Full progressive narrowing pipeline for new products or features in clean repos.

```
write-vision → analyze-domain → analyze-competitors → build-personas →
validate-feature → write-spec → audit-ac → write-journeys →
design-ux → design-ui → design-tech → explore-solutions →
define-code-style → plan-changeset → execute-changeset →
audit-implementation → land-changeset → verify-promotion
```

Use when: starting a new project, adding a major feature to an empty or
near-empty repo, or the user says "build me an app."

### Brownfield Conversion

Onboard an existing repo into vibomatic before applying other lanes.

```
onboard-repo → sync-work-items
```

Use when: the repo has shipped code, docs, tests, or conventions that must be
inventoried and mapped before vibomatic can govern it. Does not rewrite anything
— logs findings as work items and routes each to the right lane.

### Brownfield Feature

Extend an existing system with delta specs instead of regenerating the full world.
Skips UX and UI design by default (override with `--include design-ux,design-ui`).

```
sync-spec-code → validate-feature → write-spec → write-journeys →
design-tech → explore-solutions → define-code-style →
plan-changeset → execute-changeset → review-gate →
audit-implementation → land-changeset → verify-promotion
```

Use when: adding a feature to a repo that already has specs, journeys, and
working code. Starts with drift check to ensure the spec baseline is accurate.

### Bugfix

Root-cause-first correction. Skips code style by default.

```
diagnose-bug → plan-changeset → execute-changeset →
review-gate → audit-implementation → land-changeset → verify-promotion
```

Use when: a work item describes broken behavior, a regression, or a production
issue. The diagnosis produces a brief with root cause, fix surface, and proof
plan before any code is touched.

### Drift / Maintenance

Reconcile specs, journeys, and code without shipping new behavior.

```
sync-spec-code → write-journeys → sync-work-items
```

Use when: specs have drifted from code (PLANNED items are now implemented,
code contradicts spec, journeys reference stale behavior). Produces updated
annotations and work items.

### Refactor

Preserve behavior while making bounded structural changes.

```
sync-spec-code → plan-changeset → execute-changeset →
review-gate → audit-implementation → land-changeset → verify-promotion
```

Use when: renaming, restructuring, extracting, or cleaning up code without
changing user-facing behavior.

## The Worktree Model

All implementation phases happen in a single worktree branched from main.
Code lives in actual files, not markdown documents.

```
feature/match-discovery (worktree branch)
  src/...                  ← real code, real tests, real files
  docs/plans/manifest.md   ← what changed, why, task graph, validations
  checkpoint commits:
    phase-3-spec
    phase-4-ux-design
    phase-5-ui-design
    phase-6-technical-design
    task-1-types
    task-2-data-model
    task-3-tests
    ...
```

Each phase creates a checkpoint commit on the feature branch. The manifest
describes what changed, how tasks are grouped, and what validation should
happen, preserving reviewability. Promotion is `git merge --squash` to main —
one clean commit with the full context.

Full worktree model: [`WORKTREES.md`](WORKTREES.md)

## Token Efficiency

Vibomatic uses a four-layer cache architecture that reduces token costs by
50-60% compared to naive approaches:

| Layer | Scope | Cached across | Tokens |
|-------|-------|---------------|--------|
| 1. Project | Vision, personas, design system | All features, all tasks | ~15K |
| 2. Feature | Spec, UX, UI, tech design | All tasks of one feature | ~20K |
| 3. Code | Only files referenced by spec annotations | Parallel sub-agents | ~30K |
| 4. Task | Task instructions (unique) | Never cached | ~10K |

Key optimizations:
- **Phases 3-6 don't load source code.** The spec IS the codebase index
  (RESOLVED annotations with file:line). Code is loaded only in Phase 7.
- **Stable loading order** maximizes cache prefix matches across tasks.
- **Parallel sub-agents** share Layer 1-3 cache when dispatched together.
- **Phase-skipping** for non-UI features (Enablers skip Phases 4-5).

## Installation

```bash
npx skills add s7an-it/vibomatic
```

## Repository Modes

- **bootstrap** — greenfield, no established workflow. Vibomatic creates the
  structure from scratch.
- **convert** — brownfield, existing code and conventions. Vibomatic inventories
  first, adapts second.

Mode contract and detection logic: [`REPO_MODES.md`](REPO_MODES.md)

## Included Skills

### Pipeline (ordered)

| Skill | Action |
|-------|--------|
| `write-vision` | Create or refine the product vision |
| `analyze-domain` | Build domain expertise and reference packs |
| `analyze-competitors` | Map competitive landscape (runs parallel with analyze-domain) |
| `build-personas` | Build user personas from vision and challenge libraries |
| `validate-feature` | Validate a feature idea with 8 business questions |
| `write-spec` | Write feature spec with user stories and ACs |
| `audit-ac` | Audit and rewrite acceptance criteria for completeness |
| `write-journeys` | Generate BDD journey docs with AC traceability |
| `design-ux` | Define screen flows, state machines, interaction patterns |
| `design-ui` | Define component specs, design tokens, visual hierarchy |
| `design-tech` | Define architecture, data model, feasibility matrix |
| `explore-solutions` | Challenge the chosen approach with alternative paradigms |
| `define-code-style` | Define or audit the project code style contract |
| `plan-changeset` | Produce implementation manifest with task graph |
| `execute-changeset` | Execute the plan in a worktree with TDD and checkpoints |
| `audit-implementation` | Deep correctness audit before landing |
| `land-changeset` | Validate, version, PR, squash-merge, clean up |
| `verify-promotion` | Post-merge verification (spec-sync + QA + E2E) |

### Review

| Skill | Action |
|-------|--------|
| `review-gate` | Run the 5-step adversarial review at gates G1-G7 |
| `review-security` | OWASP Top 10 + STRIDE + supply chain audit |
| `review-cross-model` | Adversarial review via a second model |

### Sync

| Skill | Action |
|-------|--------|
| `sync-spec-code` | Reconcile spec annotations against codebase |
| `sync-work-items` | Push repo-canonical work items to GitHub Issues |

### Test

| Skill | Action |
|-------|--------|
| `test-journeys` | Journey-first QA against a live URL |
| `write-e2e` | Write E2E test files from journey docs |
| `test-framework` | Benchmark the vibomatic pipeline itself |

### Utility

| Skill | Action |
|-------|--------|
| `route-workflow` | Detect lane and route to the next skill |
| `diagnose-bug` | Root-cause investigation before any fix |
| `onboard-repo` | Inventory and map a brownfield repo |
| `research` | Resolve uncertainty about APIs, libraries, patterns |
| `discover-skills` | Find and install external skills |
| `extract-bootstrap` | Extract patterns from a codebase into templates |
| `track-visuals` | Capture and diff screenshots across breakpoints |
| `analyze-marketing` | Mine feature specs for marketing angles |
| `manage-learnings` | Review, search, prune, export project learnings |

## Full Doctrine

The complete methodology — technical argument for progressive narrowing,
review protocol specification, worktree model, promotion process, token cost
analysis, and execution model:

[`DOCTRINE.md`](DOCTRINE.md)

## Skill Pack Comparison

How vibomatic compares to gstack and superpowers:

[`references/skill-pack-comparison.md`](references/skill-pack-comparison.md)

## External Add-Ons

Optional skill ecosystems: [`EXTERNAL_ADDONS.md`](EXTERNAL_ADDONS.md)

- `coreyhaines` marketing pack (12 skills: CRO, copy, SEO, launch strategy)

## Third-Party Attribution

Components derived from MIT-licensed projects: [`NOTICES`](NOTICES)

## License

BSL 1.1 — free for development, testing, learning, marketing, and demos.
Revenue-generating production use requires approval. Converts to Apache 2.0
on 2027-04-03 or at 50,000 GitHub stars, whichever comes first.

See [`LICENSE`](LICENSE) for full terms.
