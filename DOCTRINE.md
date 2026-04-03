# The Vibomatic Doctrine

> Progressive Deterministic Development — a methodology for reliable agentic software engineering

> A development methodology for the agentic era, grounded in the operational
> limitations of large language models.

## The Problem This Solves

Large language models generate code through pattern matching against training
data. This produces three failure modes that no amount of prompt engineering
eliminates:

1. **Non-determinism.** The same input produces different output on different
   runs. A spec that says "sort matches by compatibility" yields fifty valid
   implementations — different abstractions, different edge case handling,
   different integration patterns. Each one is confidently presented as correct.

2. **Context blindness.** An LLM knows only what is in its context window. If
   the spec is in file A and the code is in file B and the journey is in file C,
   the agent editing file B cannot ensure consistency with A and C unless it has
   read them in the same session. Unlike a human developer who carries months of
   project context in their head, an agent starts every session empty.

3. **Lossy translation.** Each boundary crossing — spec to design, design to
   plan, plan to code — is a probabilistic translation. Information is lost or
   hallucinated at every step. The more boundaries, the more drift. The less
   context at each boundary, the more pattern matching fills the gaps.

Traditional software development assumes the developer IS the context holder.
The developer reads the ticket, remembers the architecture, understands the
codebase, and produces coherent code. When the developer is an LLM, this
assumption breaks. The methodology must compensate.

## The Science

The scientific foundation of why progressive narrowing works, based on LLM
architecture.

### Attention Decay and Drift

LLMs use self-attention to relate every token to every other token in context.
But attention is not uniform — positional encoding biases attention toward
recent tokens. When generating line 400 of a service file, spec tokens loaded
at the beginning of the context receive diminishing attention. The agent follows
code-internal patterns instead of the spec. This is drift.

### Checkpoints as Attention Resets

Each task checkpoint forces a stop. The next task re-reads the spec (fresh,
high attention) and the code so far (fresh, high attention). The positional
bias resets. The spec is never more than one task's worth of tokens from the
generation point.

### The Worktree as External Memory

An LLM has no long-term memory. Its context window IS its entire mind. When a
session ends, everything is gone. The worktree is the agent's external brain —
every artifact from every phase persists on disk, accessible by reading a file.
The worktree guarantees that everything the agent reads is consistent with a
single point in time (the base commit).

### The Entropy Argument

An LLM's output entropy (variance) is bounded by:
`H(output) ≤ H(model) + H(context)`. We cannot control `H(model)`. We CAN
minimize `H(context)` through progressive constraint accumulation. Each phase
eliminates a specific class of uncertainty:

| Phase | Uncertainty Eliminated |
|-------|----------------------|
| Vision | What product? What boundaries? |
| Personas | Who uses it? What do they need? |
| Spec | What features? What acceptance criteria? |
| UX Design | How do users experience it? What states? |
| UI Design | How does it look? What components? |
| Tech Design | How to build it? What architecture? |
| Code | Only remaining: exact syntax |

Sequential narrowing compounds. Six small entropy reductions are more effective
than one large reduction because each phase catches a DIFFERENT CLASS of
uncertainty. A single "detailed ticket" tries to eliminate all uncertainty at
once — it cannot, because the ticket author hasn't resolved UX states,
component design, or data model implications.

### Review Gates as Adversarial Debiasing

During generation, attention is biased toward producing coherent output
(generation mode). During self-review, attention shifts to finding errors
(evaluation mode). Self-judgment forces a third pattern: evaluating the
evaluation. Cross-review introduces a completely fresh attention state with
no bias from the generation process. Each step creates a different attention
pattern over the same content.

### The Fundamental Claim

For any LLM with fixed model entropy `H(model)`, output reliability is
maximized by minimizing context entropy `H(context)` through sequential
phase-gated constraint accumulation, where each phase: (a) reduces a specific
class of uncertainty, (b) is reviewed before the next phase begins, (c)
persists in a consistent accessible state (the worktree), and (d) is re-loaded
into the attention window at each checkpoint to prevent positional attention
decay.

## The Core Principle

**Progressive narrowing eliminates non-determinism.**

Each phase of the pipeline constrains the space of possible outputs for the
next phase. By the time code is written, the implementation is essentially
determined — not by the agent's pattern matching, but by the accumulated
constraints from every prior phase.

```
Phase 1: Vision          → infinite possibilities
Phase 2: Personas        → narrows WHO
Phase 3: Feature Spec    → narrows WHAT (stories, acceptance criteria)
Phase 4: UX Design       → narrows HOW users experience it (flows, states)
Phase 5: UI Design       → narrows HOW it looks (components, visual language)
Phase 6: Technical Design → narrows HOW to build it (architecture, data model)
Phase 7: Change Set      → narrows to ONE implementation (exact files, exact code)
Phase 8: Promotion       → applies the change set to the codebase
Phase 9: Verification    → proves the promotion matches the change set
```

At Phase 1, the agent is generating. By Phase 7, the agent is transcribing.
The creative work happened in Phases 1-6 where humans reviewed and approved
each narrowing. Phase 7 is mechanical — constrained by everything above it.

## Phases and Artifacts

Every phase produces a specific artifact. Every artifact has a lifecycle state.
Every state transition requires a review gate.

### Phase Table

| # | Phase | Skill | Artifact | Format | State Transition |
|---|-------|-------|----------|--------|-----------------|
| 1 | Vision | `vision-sync` | `docs/specs/vision.md` | Single file, 12-section canonical structure | — → ACTIVE |
| 2 | Personas | `persona-builder` | `docs/specs/personas/P*.md` | One file per persona | — → ACTIVE |
| 3 | Feature Spec | `writing-spec` | `docs/specs/features/<name>.md` | One file per feature (Feature/Enabler/Integration) | — → DRAFT |
| 4 | UX Design | `writing-ux-design` | `docs/specs/ux/<name>.md` | Screen flows, states, interactions, information architecture | DRAFT → UX-REVIEWED |
| 5 | UI Design | `writing-ui-design` | `docs/specs/ui/<name>.md` + `docs/specs/design-system.md` | Component specs, visual language, responsive behavior | UX-REVIEWED → DESIGNED |
| 6 | Technical Design | `writing-technical-design` | Updated feature spec: Technical Design section | Architecture, data model, feasibility matrix | DESIGNED → BASELINED |
| 7 | Change Set | `writing-change-set` | `docs/plans/<date>-<name>/` | Multi-part: manifest + parts (types, services, components, tests, specs, journeys) | BASELINED → CHANGE-SET-APPROVED |
| 8 | Promotion | `promoting-change-set` | Actual codebase files | Applied changes + deviation report | CHANGE-SET-APPROVED → PROMOTED |
| 9 | Verification | `verifying-promotion` | Updated feature spec: VERIFIED status | Test results, QA status, E2E status | PROMOTED → VERIFIED |

### Artifact Lifecycle

```
Feature Spec States:
  DRAFT               → requirements defined (stories, ACs, journeys)
  UX-REVIEWED         → UX design approved (screen flows, states)
  DESIGNED            → UI design approved (visual, components)
  BASELINED           → technical design approved (architecture, data model)
  CHANGE-SET-APPROVED → implementation plan reviewed and approved
  PROMOTED            → change set applied to codebase
  VERIFIED            → tests pass, QA complete, E2E complete
```

Each state transition is gated by the Review Protocol (see below).

### Foundational Artifacts (Project-Level)

These are not per-feature — they are created once and evolved:

| Artifact | Skill | Path | Purpose |
|----------|-------|------|---------|
| Vision | `vision-sync` | `docs/specs/vision.md` | Product direction, boundaries, principles |
| Personas | `persona-builder` | `docs/specs/personas/P*.md` | Who uses this product (human and system consumers) |
| Design System | `writing-ui-design` | `docs/specs/design-system.md` | Visual language: tokens, typography, colors, spacing, motion |
| Journey Index | `journey-sync` | `docs/specs/journeys/JOURNEY_INDEX.md` | Cross-reference of all journeys |

### Per-Feature Artifacts

Each feature produces these artifacts as it moves through the pipeline:

| Artifact | Created at Phase | Path |
|----------|-----------------|------|
| Feature Spec | 3 (writing-spec) | `docs/specs/features/<name>.md` |
| UX Design | 4 (writing-ux-design) | `docs/specs/ux/<name>.md` |
| UI Design | 5 (writing-ui-design) | `docs/specs/ui/<name>.md` |
| Journey Doc(s) | 3 (writing-spec triggers journey-sync) | `docs/specs/journeys/J*-<name>.feature.md` |
| Change Set | 7 (writing-change-set) | `docs/plans/<date>-<name>/` |

## Feature Types

Every feature spec carries a Type that identifies its consumer. The type
determines the persona, not the process. All types go through the same pipeline.

| Type | Consumer | Story Format | Journey Type |
|------|----------|-------------|--------------|
| Feature | Human user (persona) | "As P1, I want..." | User journey with UI + system steps |
| Enabler | Other service/feature | "As [service], I need..." | System journey with service interactions |
| Integration | External system boundary | "When [event], system must..." | Contract journey with request/response |

### The Cascade Effect

Specifying a Feature automatically reveals every Enabler and Integration it
depends on. Layer 3 journey analysis flags ungrounded preconditions — system
steps that have no producer. Each ungrounded precondition becomes a new feature
spec (Enabler or Integration). The chain builds top-down until the full system
is specified.

```
User says: "I want match recommendations"
  → Feature: match-discovery (Feature)
    → Layer 3 finds: "scores must be fresh" — no producer
      → Feature: score-recalculation (Enabler)
    → Layer 3 finds: "notification sent to matches" — no producer
      → Feature: notification-service (Enabler)
        → Layer 3 finds: "email delivery" — no producer
          → Feature: email-delivery (Integration)
```

Nothing hand-waved. Nothing deferred. The spec process IS the architecture
discovery tool.

## The Change Set

The change set is the worktree branch itself. Code lives in actual files, not
in markdown documents. The agent writes real code into real files during
Phase 7, and those files are committed as checkpoints on the feature branch.

### Why the Branch IS the Change Set

Traditional approach (superpowers/obra):
```
Plan says: "Create src/services/matchScore.ts with a function that
           calculates compatibility scores"
Executor: reads the plan, reads the codebase, GENERATES the code
Problem:  the generation is probabilistic — different every time
```

Vibomatic approach:
```
Agent writes: src/services/matchScore.ts directly in the worktree
Agent writes: tests/matchScore.test.ts directly in the worktree
Agent writes: src/routes/matches.ts changes directly in the worktree
Each file:    committed as a checkpoint on the feature branch
Review:       git diff main...feature-branch shows exactly what changed
Promotion:    git merge --squash — deterministic, no re-generation
```

The agent writes code while holding full context — every spec, every journey,
every AC is in the worktree. The code is reviewed on the branch before it
touches main. Promotion is a mechanical merge, not a probabilistic generation.

### The Manifest

The manifest still exists as a document (`docs/plans/<date>-<name>/manifest.md`)
for reviewability. It describes what changed and why — a table of contents for
the branch diff. But the actual code lives in the branch, not in the manifest.

```markdown
# Change Set: Match Discovery

**Feature Spec:** docs/specs/features/feature-matching.md
**Branch:** feature-match-discovery
**Base:** main @ <sha>
**Status:** BASELINED → CHANGE-SET-APPROVED (pending review)
**Created:** 2026-04-03

## Files Changed

| File | Action | Task | Purpose |
|------|--------|------|---------|
| src/types/match.ts | CREATE | task-1-types | Type definitions, interfaces |
| migrations/003-match-scores.sql | CREATE | task-2-data-model | Score table migration |
| tests/matchScore.test.ts | CREATE | task-3-tests | Unit tests (TDD — written first) |
| src/services/matchScore.ts | CREATE | task-4-services | Score calculation logic |
| src/components/MatchCard.tsx | CREATE | task-5-components | Match display component |
| e2e/specs/matching.spec.ts | CREATE | task-6-e2e | End-to-end test coverage |
| docs/specs/features/feature-matching.md | MODIFY | task-7-spec | Status update, AC annotations |

## Checkpoint History

| Checkpoint | Commit | What It Contains |
|------------|--------|-----------------|
| checkpoint: phase-3-spec | abc1234 | Feature spec with stories, ACs |
| checkpoint: phase-4-ux | def5678 | UX design with flows, states |
| checkpoint: phase-5-ui | ghi9012 | UI design with components |
| checkpoint: phase-6-tech | jkl3456 | Technical design, architecture |
| checkpoint: task-1-types | mno7890 | Type definitions |
| checkpoint: task-2-data-model | pqr1234 | Database migration |
| checkpoint: task-3-tests | stu5678 | Unit tests |
| checkpoint: task-4-services | vwx9012 | Service implementation |
| checkpoint: task-5-components | yza3456 | UI components |
| checkpoint: task-6-e2e | bcd7890 | E2E tests |
| checkpoint: task-7-spec | efg1234 | Spec status updates |
```

The manifest is the map. The branch is the territory.

## The Review Protocol

Every state transition is gated by a review. The review protocol is designed
around the specific failure modes of LLM agents: they miss their own errors,
they agree too easily, and they rationalize incorrect output.

### The Protocol

```
Step 1: SELF-REVIEW
  Agent A reviews the artifact.
  Produces: list of findings, each with:
    - Finding ID
    - Severity (critical / high / medium / low)
    - Description
    - Location (file:line or section reference)
    - Justification (why this is an issue)

Step 2: SELF-JUDGMENT
  Agent A reviews its own findings.
  For each finding, produces:
    - ACCEPT or REJECT
    - Analysis (why the finding is valid or why it was a false positive)
  This forces critical reasoning — the agent must argue with itself,
  not just list issues.

Step 3: CROSS-REVIEW
  Agent B receives:
    - The artifact
    - Agent A's findings
    - Agent A's self-judgments
  Agent B produces:
    - ACCEPT or REJECT for each of Agent A's accepted findings
    - NEW findings Agent A missed
    - Justification for every decision

Step 4: CONVERGENCE CHECK
  If only medium/low severity issues remain → PASS (proceed to next phase)
  If critical/high issues remain → fix and re-enter Step 1
  Maximum 3 iterations → escalate to human with full findings history

Step 5: GATE DECISION
  PASS → artifact transitions to next state
  FAIL → artifact stays in current state, findings become fix tasks
  ESCALATE → human reviews findings, makes final call
```

### Why This Protocol Works

| LLM Failure Mode | How the Protocol Catches It |
|---|---|
| Agent doesn't see its own errors | Step 3: fresh agent with different "perspective" |
| Agent lists issues but doesn't evaluate them | Step 2: forced accept/reject with reasoning |
| Agent agrees with everything | Step 3: cross-agent must independently justify |
| Infinite review loops | Step 4: max 3 iterations, then escalate |
| Review theater (finding trivial issues to seem thorough) | Severity classification + convergence on medium/low = pass |

### Review Gates

| Gate | Artifact | Transition | What the Review Checks |
|------|----------|------------|----------------------|
| G1 | Feature Spec | DRAFT → ready for UX | Stories testable? ACs specific? Layer 3 clean? Dependencies identified? |
| G2 | UX Design | DRAFT → UX-REVIEWED | Flows cover all stories? States complete? Error handling? Accessibility? |
| G3 | UI Design | DRAFT → DESIGNED | Design system consistency? Responsive? Dark mode? Component reuse? |
| G4 | Technical Design | DESIGNED → BASELINED | All ACs feasible? Architecture sound? Risks identified? Trade-offs explicit? |
| G5 | Change Set | BASELINED → CHANGE-SET-APPROVED | Code matches design? Tests cover ACs? Cross-file consistency? No placeholders? |
| G6 | Promotion | CHANGE-SET-APPROVED → PROMOTED | Applied code matches change set? No deviations? No unplanned changes? |
| G7 | Verification | PROMOTED → VERIFIED | Tests pass? QA complete? E2E complete? Spec annotations updated? |

## Promotion

Promotion is `git merge --squash feature-branch` into main. The entire feature
branch — specs, designs, code, tests — lands as a single atomic commit.

### Promotion Process

```
1. Ensure feature branch has passed G5 review (change set approved)
2. git checkout main && git merge --squash feature-<name>
3. Deviation check: git diff --staged should match expected changes
   (compare against the manifest's file list)
4. If deviations found → enter Review Protocol at G6
5. If clean → commit, run validation commands, status → PROMOTED
```

### Why Squash Merge

The feature branch contains many intermediate checkpoints — useful during
development but noisy in main's history. The squash merge collapses them into
a single commit that represents the complete, reviewed change set. The feature
branch is preserved (not deleted) so checkpoint history remains available.

## Checkpoints

Every phase ends with a checkpoint — a commit on the feature branch. Checkpoints
are the mechanism that makes the worktree model work.

### Why Checkpoints Matter

1. **Attention resets.** When the agent starts a new task, it re-reads the
   relevant artifacts fresh. The checkpoint guarantees those artifacts are on
   disk and consistent. The positional attention bias resets — the spec is at
   the top of the context, not buried under 10K tokens of generated code.

2. **Rollback to any phase.** If Phase 6 reveals that the spec is wrong, you
   can roll back to the Phase 3 checkpoint and re-run from there. No
   reconstructing state from memory. No hoping the agent remembers what the
   spec said before you changed it.

3. **Lightweight commits.** Checkpoints are ordinary git commits. They carry
   no ceremony — no PR, no review, no CI. They exist for the agent's benefit.
   All of them get squashed at promotion anyway.

4. **Audit trail.** The checkpoint history tells the story of how the feature
   was built: what was designed first, what changed during technical design,
   which tasks were completed in what order.

### Checkpoint Naming

```
checkpoint: phase-3-spec
checkpoint: phase-4-ux
checkpoint: phase-5-ui
checkpoint: phase-6-tech
checkpoint: task-1-types
checkpoint: task-2-data-model
checkpoint: task-3-tests
checkpoint: task-4-services
checkpoint: task-5-components
checkpoint: task-6-e2e
checkpoint: task-7-spec-updates
```

The prefix `checkpoint:` is mandatory. It distinguishes checkpoint commits from
any other commits on the branch. Phase checkpoints use `phase-N-<name>`. Task
checkpoints (within Phase 7) use `task-N-<name>`.

## UX Design vs UI Design

These are fundamentally different concerns and must be separate documents
in separate phases with separate review gates.

### UX Design (Phase 4)

**What it answers:** How does the user move through the feature? What do
they see at each state? What happens when things go wrong?

**Artifact:** `docs/specs/ux/<feature-name>.md`

**Contains:**
- Screen inventory (what screens/views exist)
- State machine (what states each screen can be in)
- Flow diagram (how users navigate between screens)
- Information hierarchy (what's most important on each screen)
- Error states and recovery paths
- Loading states and transitions
- Accessibility requirements
- Responsive behavior strategy (mobile-first, breakpoints)

**Does NOT contain:** Colors, fonts, spacing, visual style. Those are UI design.

**Input:** Feature spec (stories, ACs) + Personas + Journeys
**Output:** UX-REVIEWED feature spec (screen flows and states validated)

### UI Design (Phase 5)

**What it answers:** How does it look? What's the visual language? What
specific components render the UX design's screens?

**Artifact:** `docs/specs/ui/<feature-name>.md` + `docs/specs/design-system.md`

**Contains:**
- Component specifications (what renders each screen element)
- Design token usage (which colors, spacing, typography from the design system)
- Visual hierarchy (size, weight, contrast decisions)
- Dark mode behavior
- Animation and motion specifications
- Component states (hover, active, disabled, error, loading)
- Responsive layout specifics (grid, breakpoints, reflow)

**References:** Design System (`docs/specs/design-system.md`) for tokens
and patterns. If the design system doesn't exist, UI design creates it first.

**Input:** UX Design (screen flows, states) + Design System (tokens, patterns)
**Output:** DESIGNED feature spec (visual specifications locked)

### Design System (Foundational)

**What it is:** The project's visual language. Created once, evolved as
features demand new patterns.

**Artifact:** `docs/specs/design-system.md`

**Contains:**
- Color palette (semantic: primary, error, warning — not hex values as names)
- Typography scale (headings, body, code, captions — sizes, weights, line heights)
- Spacing system (base unit, scale)
- Component patterns (card, modal, form, button, navigation)
- Motion principles (durations, easing, when to animate)
- Dark mode strategy
- Brand personality (voice, tone, visual feeling)

**Influenced by:** Google Material Design, Stitch, Tailwind — but adapted
to the project's specific brand. Not a copy of any framework.

## Token Cost Considerations

This methodology is more expensive per feature than "give the agent a ticket
and let it code." That is the point. The cost of fixing a bad implementation
exceeds the cost of preventing it.

### Cost Model

| Phase | Estimated Tokens | Parallelizable? |
|-------|-----------------|-----------------|
| Feature Spec (writing-spec) | 10K-30K | No (sequential) |
| UX Design (writing-ux-design) | 15K-40K | No (needs spec) |
| UI Design (writing-ui-design) | 15K-40K | No (needs UX) |
| Technical Design (writing-technical-design) | 20K-50K | No (needs designs) |
| Change Set (writing-change-set) | 50K-200K | Parts are parallelizable |
| Review Protocol per gate (x7 gates) | 10K-30K each | Steps 1-2 and Step 3 are parallelizable |
| Promotion | 20K-50K | Parts are parallelizable |
| Verification | 10K-30K | Tests are parallelizable |

**Total per feature:** 150K-600K tokens (varies by feature size)

**Compare to "ticket → code":** 20K-50K tokens, but with:
- 3-5 fix cycles averaging 15K tokens each = 75K-125K additional
- Spec drift requiring manual detection and correction
- Integration bugs found in QA, not in review
- Actual total: often exceeds the structured approach

### Optimization Strategies

1. **Skip phases for small changes.** A one-line bug fix doesn't need UX design.
   The doctrine defines phase gates — but the first gate is "does this phase
   apply?" A change with no user-facing impact skips Phases 4-5.

2. **Parallelize change set parts.** Parts with no dependencies can be written
   by parallel agents. Types + data model first, then services + components in
   parallel.

3. **Parallelize review steps.** Self-review (Steps 1-2) and cross-review
   (Step 3) can run in parallel when reviewing different parts.

4. **Reuse foundational artifacts.** Vision, personas, and design system are
   written once. Each new feature reads them but doesn't recreate them.

5. **Batch features.** Multiple small features can share a single change set
   if they don't conflict.

## Why This Is Necessary Now

In 2024-2025, AI coding meant "copilot autocompletes your line." The developer
held the context, the AI filled in syntax. The developer was the deterministic
element; the AI was a stochastic accelerator.

In 2026, AI coding means "agent implements your feature." The agent holds no
persistent context. The agent IS the stochastic element. If the methodology
doesn't account for this, every feature is a gamble — sometimes the agent
produces what you wanted, sometimes it produces something confidently wrong.

Vibomatic is the methodology that makes agentic development deterministic.
Not by fixing the models — that's Anthropic's, OpenAI's, and Google's job.
But by structuring the process so that by the time the agent generates code,
the code is already determined by everything that came before it.

**The progressive narrowing model is not optional.** It is the only way to
get reliable output from a probabilistic system. Every methodology that skips
phases — that goes from ticket to code, from spec to implementation, from
design to "let the agent figure it out" — is accepting non-determinism as
a feature. Vibomatic rejects that.

## The Complete Pipeline

All phases happen in a single worktree branched from main. Each phase produces
a checkpoint. The worktree is the time capsule — nothing changes under the
agent between phases. Promotion is a squash merge to main.

```
main (frozen at SHA)
  └── worktree: feature-<name>
        Phase 3: writing-spec             → checkpoint → [G1 Review]
        Phase 4: writing-ux-design        → checkpoint → [G2 Review]
        Phase 5: writing-ui-design        → checkpoint → [G3 Review]
        Phase 6: writing-technical-design → checkpoint → [G4 Review]
        Phase 7: writing code + tests     → checkpoint per task → [G5 Review]
        Phase 8: squash merge to main = promotion → [G6 Review]
        Phase 9: verify on main           → [G7 Review]
```

## Feedback Loops

The pipeline is not strictly linear. Later phases reveal problems in earlier
phases. These feedback loops are explicit and expected:

| Discovery | Source Phase | Loops Back To |
|-----------|-------------|---------------|
| AC not feasible | Technical Design (6) | Feature Spec (3) |
| Screen flow impossible | UX Design (4) | Feature Spec (3) |
| Design system insufficient | UI Design (5) | Design System (foundational) |
| Missing enabler | Journey Layer 3 (3) | Feature Spec (3, recursive) |
| Code doesn't match ACs | Verification (9) | Change Set (7) |
| Promotion deviated | Promotion Review (8) | Promotion (8, re-apply) |

Each feedback loop re-enters the Review Protocol at the destination phase.
The artifact's state regresses to the destination phase's state (e.g., if
Technical Design reveals an infeasible AC, the feature spec goes back to DRAFT).
