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
time code is written, the implementation is determined — not by pattern matching,
but by the accumulated constraints from every prior phase.

```
Phase 1:  Vision              → infinite possibilities
Phase 2:  Personas            → narrows WHO
Phase 3:  Feature Spec        → narrows WHAT (stories, acceptance criteria)
Phase 4:  UX Design           → narrows HOW users experience it
Phase 5:  UI Design           → narrows HOW it looks
Phase 6:  Technical Design    → narrows HOW to build it
Phase 7:  Implementation      → narrows to ONE implementation (exact files in worktree)
Phase 8:  Promotion           → squash-merges the worktree to main
Phase 9:  Verification        → proves the merge matches the manifest
```

At Phase 1, the agent is generating. By Phase 7, the agent is transcribing
into actual files in a worktree branched from main. The creative work happens
in Phases 1-6 where humans review each narrowing. Phase 7 is mechanical.
Phase 8 is a squash merge. Phase 9 is checking.

## Why This Works (Technical Argument)

An LLM's output variance is inversely proportional to the constraints in its
context window. More context = less variance. The progressive narrowing model
exploits this:

1. **Context loading.** Each phase reads ALL prior artifacts. The agent writing
   the change set has read the vision, personas, spec, UX design, UI design,
   technical design, journeys, and existing code. Every constraint is in context.

2. **Variance reduction.** A one-line ticket produces 50 implementations.
   A spec with 12 acceptance criteria produces 5. A change set with exact
   file content produces 1.

3. **Review before generation.** Traditional: agent generates code, human
   reviews code. Vibomatic: human reviews intent (spec, design, plan),
   agent copies reviewed intent into code. Reviewing intent is cheaper
   than reviewing implementation.

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
| 7. Implementation | `writing-change-set` | Code in worktree, manifest, tests | G5 |
| 8. Promotion | `promoting-change-set` | Squash merge to main + deviation report | G6 |
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
| `workflow-compass` | Route to the right skill based on project state |
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
  docs/plans/manifest.md   ← what changed, why, apply order, dependencies
  checkpoint commits:
    phase-3-spec
    phase-4-ux-design
    phase-5-ui-design
    phase-6-technical-design
    phase-7-implementation
```

Each phase creates a checkpoint commit on the feature branch. The manifest
describes what changed and why, preserving reviewability. Promotion is
`git merge --squash` to main — one clean commit with the full context.

## Installation

```bash
npx skills add s7an-it/vibomatic
```

## Repository Modes

- **bootstrap** — initialize a project with no established workflow
- **convert** — adapt to an existing project's conventions

Mode contract: [`REPO_MODES.md`](REPO_MODES.md)

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
