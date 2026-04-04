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
| Vision | `vision-sync` | Product direction, boundaries, principles |
| Personas | `persona-builder` | Who uses this (human and system consumers) |
| Design System | `writing-ui-design` | Visual language: tokens, typography, colors, spacing |

### Per-Feature Pipeline

| Phase | Skill | Produces | Gate |
|-------|-------|----------|------|
| 3. Spec | `writing-spec` | User stories, ACs, system dependencies, journeys | G1 |
| 4. UX Design | `writing-ux-design` | Screen flows, states, interactions | G2 |
| 5. UI Design | `writing-ui-design` | Component specs, design tokens, visual hierarchy | G3 |
| 6. Technical Design | `writing-technical-design` | Architecture, data model, feasibility | G4 |
| 7. Implementation Planning | `writing-change-set` | Implementation manifest, task graph, AC/test mapping | — |
| 7b. Execution | `executing-change-set` | Code in worktree, staged diffs, checkpoints | G5 |
| 8. Promotion | `landing-change-set` | Squash merge to main + manifest/diff validation | G6 |
| 9. Verification | spec-code-sync + QA + E2E | VERIFIED status | G7 |

### Feature Spec Lifecycle

```
DRAFT → UX-REVIEWED → DESIGNED → BASELINED → CHANGE-SET-APPROVED → PROMOTED → VERIFIED
```

### Supporting Skills

| Skill | Purpose |
|-------|---------|
| `feature-discovery` | Validate feature ideas against existing product context |
| `spec-ac-sync` | Ensure acceptance criteria are complete and testable |
| `spec-code-sync` | Detect drift between specs and code (PLANNED/RESOLVED/DRIFT) |
| `journey-sync` | BDD journeys with Layer 3 analysis (finds hidden dependencies) |
| `journey-qa-ac-testing` | Journey-based QA against live environments |
| `agentic-e2e-playwright` | E2E test authoring (accessibility-first, journey-based) |
| `feature-marketing-insights` | Mine feature specs for marketing context |
| `workflow-compass` | Route to the right skill and lane based on project state |
| `repo-conversion` | Convert an existing repo into vibomatic working mode before full pipeline use |
| `bugfix-brief` | Root-cause-first planning for bugs and regressions |
| `work-item-sync` | Project repo-canonical work items to GitHub Issues |
| `executing-change-set` | Execute the implementation plan directly in the worktree with staged reviews and checkpoints |
| `review-protocol` | Universal review gate (self-review → cross-review → convergence) |

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

## The Worktree Model

All phases happen in a single worktree branched from main. Code lives in
actual files, not markdown documents.

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

- **bootstrap** — initialize a project with no established workflow
- **convert** — adapt to an existing project's conventions

Mode contract: [`REPO_MODES.md`](REPO_MODES.md)

### Default Recommendation

- **Clean repo / greenfield**: use vibomatic directly. Let the repo adopt the
  vibomatic workflow from day one.
- **Existing repo / brownfield**: run `repo-conversion` first. Inventory the
  current truth, map artifacts into vibomatic form, log findings as work items,
  then route to the right lane.

### Workflow Lanes

- **Greenfield feature lane**: full progressive narrowing pipeline for net-new
  products or subsystems.
- **Auto greenfield lane**: full-auto clean-repo path for prompts like
  "build me an app", with blockers only for real contradictions or missing intent.
- **Brownfield conversion lane**: establish `project-state.md`, canonical
  artifact mapping, and work-item inventory before enforcing the full pipeline.
- **Brownfield feature lane**: extend an existing system using delta specs and
  journey expansion instead of regenerating the full world.
- **Bugfix / regression lane**: root-cause-first correction work using
  `bugfix-brief`, then implementation and verification.
- **Drift / maintenance lane**: reconcile specs, journeys, and code with
  `spec-code-sync`, then route the resulting items.
- **Refactor / chore lane**: preserve behavior while making bounded structural
  or repo-state changes through implementation planning and execution.

## Included Skills

- `vision-sync`
- `domain-expert`
- `competitor-analysis`
- `persona-builder`
- `journey-sync`
- `journey-qa-ac-testing`
- `feature-discovery`
- `spec-ac-sync`
- `spec-code-sync`
- `spec-style-sync`
- `agentic-e2e-playwright`
- `feature-marketing-insights`
- `workflow-compass`
- `repo-conversion`
- `bugfix-brief`
- `work-item-sync`
- `skill-finder`
- `research`
- `writing-spec`
- `writing-ux-design`
- `writing-ui-design`
- `writing-technical-design`
- `solution-explorer`
- `writing-change-set`
- `executing-change-set`
- `review-protocol`
- `landing-change-set`
- `verifying-promotion`
- `framework-test`

## Full Doctrine

The complete methodology, including the technical argument for progressive
narrowing, the review protocol specification, the worktree model, the
promotion process, and token cost analysis:

[`DOCTRINE.md`](DOCTRINE.md)

## Skill Pack Comparison

How vibomatic compares to gstack (Garry Tan) and superpowers (Jesse Vincent):

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
