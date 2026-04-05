---
name: design-tech
description: Use when you have a DESIGNED feature spec (after UX and UI design) and need to define architecture, tech choices, and component design before implementation
inputs:
  required:
    - { path: "docs/specs/features/<name>.md", artifact: feature-spec }
    - { path: "docs/specs/journeys/J*-<name>.feature.md", artifact: journeys }
  optional:
    - { path: "docs/specs/ux/<name>.md", artifact: ux-design }
    - { path: "docs/specs/ui/<name>.md", artifact: ui-design }
outputs:
  produces:
    - { path: "docs/specs/features/<name>.md", artifact: feature-spec, status: BASELINED }
chain:
  lanes:
    greenfield: { position: 9, prev: design-ui, next: explore-solutions }
    brownfield-feature: { position: 5, prev: write-journeys, next: explore-solutions }
  progressive: true
  self_verify: true
  human_checkpoint: false
---

# Writing Technical Design

## Overview

Technical design answers HOW to build what the spec defines. It takes a DESIGNED feature spec (after UX and UI design) and produces the architecture, component design, data model, and technology decisions needed to implement it.

This skill transitions a feature spec from DESIGNED → BASELINED.

```
write-spec              → DRAFT (WHAT: stories, ACs, journeys)
design-ux         → UX-REVIEWED (HOW users experience it: flows, states)
design-ui         → DESIGNED (HOW it looks: components, visual language)
design-tech  → BASELINED (HOW to build it: architecture, data model)
plan-changeset        → implementation manifest + task graph
execute-changeset      → CHANGE-SET-APPROVED (DO: execute the plan on branch)
land-changeset      → PROMOTED (APPLY: reviewed branch state to codebase)
verify-promotion       → VERIFIED (PROVE: tests pass, QA complete)
```

**Announce at start:** "I'm using the design-tech skill to define the technical approach."

## Design Alternatives

For each key decision in this phase (architecture, data model, API pattern,
state management), follow the Design Alternatives Protocol
(`references/design-alternatives.md`).

## Adversarial Engineering Review (after tech design is drafted)

P0 challenges the architecture before it's finalized. This is a structured
adversarial review using the three-layer framework. Every recommendation
must be tagged. Work through each review section interactively (max 8 issues
per section).

### The Three Layers

Every technical recommendation falls into one of three layers. Tag each one.

**[Layer 1] Tried and true** — don't reinvent. Use what exists. Flag any
custom solution where a built-in or well-established library already solves
the problem. Search npm, PyPI, crates.io, or the relevant ecosystem before
building. If the team is writing a custom date parser, a bespoke HTTP client,
or a hand-rolled state machine that `xstate` already handles — that's a
Layer 1 violation.

**[Layer 2] New and popular** — scrutinize. Adoption enthusiasm does not
equal proven reliability. When the design reaches for a trending library,
a new framework feature, or a pattern that went viral on Twitter last month,
apply extra skepticism. Ask: how many production-hours does this have? What's
the bus factor on the maintainer team? Is the API stable or still churning?
Layer 2 choices need stronger justification than Layer 1.

**[Layer 3] First principles** — prize above all. When first-principles
reasoning produces a better answer than convention, that is a **[EUREKA]**
moment. These are rare and valuable: a novel data structure that eliminates
an entire class of bugs, an unconventional architecture that halves latency,
a simplification that removes three services. Document the reasoning chain
clearly. If someone can't follow the logic from axioms to conclusion, it's
not a real EUREKA — it's a Layer 2 risk dressed up.

Tag every recommendation: `[Layer 1]`, `[Layer 2]`, `[Layer 3]`, or `[EUREKA]`.

### Review Sections

Work through each section interactively. Max 8 issues per section. Present
findings with the layer tag and a recommended fix.

#### 1. Architecture

- Data flow: trace every user action through the system end-to-end. Where
  does data enter? Where does it rest? Where does it exit?
- Component boundaries: are responsibilities cleanly separated? Can you
  describe each component's job in one sentence?
- Dependency graph: draw it. Are there circular dependencies? Is the
  coupling appropriate (stable dependencies principle)?
- Integration points: where does this feature touch existing code? What's
  the contract at each boundary?

#### 2. Code Quality

- **DRY** — any duplicated patterns across proposed components? Extract
  shared logic before it ships, not after.
- **Explicit over clever** — can a new team member read this design and
  understand what happens? If a component requires a paragraph of
  explanation for its "elegant" approach, simplify it.
- **Boring by default** — standard patterns unless there's a documented
  reason to deviate. Every deviation costs future-you.
- **Naming** — do component, service, and model names describe what they
  do without needing context?

#### 3. Tests

- **Test matrix** — for each component, what needs unit tests, integration
  tests, and E2E tests? Make the decision explicit.
- **Coverage gaps** — which code paths have no proposed test? Especially:
  error paths, edge cases, permission boundaries.
- **E2E vs unit** — E2E for critical user journeys, unit for logic-heavy
  functions. Don't E2E what a unit test covers faster. Don't unit-test
  what only makes sense as an integration.
- **Test data** — where does test data come from? Fixtures, factories,
  or mocks? Is the strategy consistent?

#### 4. Performance

- **N+1 queries** — any list endpoint that fetches related data in a loop?
  Propose eager loading or batch fetching.
- **Unnecessary re-renders** — in frontend designs, are component
  boundaries drawn to minimize re-render blast radius? Are expensive
  computations memoized?
- **Cold start impact** — does this feature add to cold start time? New
  DB connections, large imports, initialization logic?
- **Payload size** — are API responses shaped for the consumer? No
  over-fetching, no sending the kitchen sink?

### Cognitive Patterns

These are the mental models that guide the review. Apply them as lenses
across all four sections above.

1. **State diagnosis** — is this team falling behind, treading water,
   repaying debt, or innovating? (Larson) The review's tone and
   recommendations change based on which state the project is in.

2. **Blast radius instinct** — what's the worst case? How many systems
   are affected? If this component fails at 3am, what breaks downstream?

3. **Boring by default** — "3 innovation tokens" (McKinley). Every
   project gets roughly three. Is this design spending one? Is it
   spending one wisely, or burning a token on something that doesn't
   differentiate the product?

4. **Incremental over revolutionary** — strangler fig, not big bang
   (Fowler). Can this design be shipped in slices that each deliver
   value? If it's all-or-nothing, that's a red flag.

5. **Systems over heroes** — design for tired humans at 3am. If the
   on-call engineer needs to understand a 4-layer abstraction to fix
   a production issue, the design is too clever.

6. **Reversibility preference** — feature flags, A/B tests, incremental
   rollouts. How easy is it to undo this change if it goes wrong?
   Irreversible decisions need proportionally more scrutiny.

7. **Failure is information** — blameless postmortems, error budgets
   (Google SRE). Does the design include observability? Can you tell
   when it's failing and why?

8. **Essential vs accidental complexity** — "Is this solving a real
   problem or one we created?" (Brooks). If the complexity exists to
   serve the abstraction rather than the user, remove the abstraction.

9. **Make the change easy, then make the easy change** (Beck) — if
   the design requires restructuring existing code, do the restructuring
   as a separate, testable step first.

10. **Two-week smell test** — if a competent engineer can't ship a small
    feature in 2 weeks using this architecture, it's an onboarding
    problem. The architecture is too complex or the documentation is
    insufficient.

### Confidence Scoring

Every finding must include a confidence score. This prevents speculation
from being presented as fact.

| Score | Meaning | Usage |
|-------|---------|-------|
| 9-10 | Verified by reading specific code — cite the file and line | Report as fact |
| 7-8 | High confidence pattern match — seen this exact failure mode before | Report with brief rationale |
| 5-6 | Moderate — plausible but not verified | Show with explicit caveat |
| 3-4 | Low — educated guess | Appendix only |
| 1-2 | Speculation — "this might..." | Only if P0 severity (production risk) |

Format: `[Layer N] [Confidence: X/10] Finding description.`

Example: `[Layer 1] [Confidence: 9/10] Custom date formatting in
src/utils/dates.ts duplicates what date-fns already provides — we
import date-fns elsewhere in the project (see package.json L42).`

### ASCII Diagram Requirements

Diagrams are mandatory, not decorative.

**Mandatory for:**
- Data flow (user action → frontend → API → backend → database → response)
- State machines (every state, every transition, every terminal state)
- Dependency graphs (component A depends on B depends on C)
- Processing pipelines (input → transform → validate → persist → respond)

**In code comments:**
- Models: data relationships between entities
- Services: processing pipelines and decision trees
- Tests: setup/teardown sequences for complex test fixtures

**Maintenance rule:** diagram maintenance is part of the change. A stale
diagram is worse than no diagram — it actively misleads. When the design
changes, the diagram changes in the same commit.

```
Example: Data Flow Diagram

  User Action
       |
       v
  +------------+     +-----------+     +----------+
  | Controller | --> | Service   | --> | Database |
  | (validate) |     | (process) |     | (persist)|
  +------------+     +-----------+     +----------+
       |                   |                |
       v                   v                v
  +------------+     +-----------+     +----------+
  | Response   | <-- | Transform | <-- | Query    |
  | (shape)    |     | (format)  |     | (fetch)  |
  +------------+     +-----------+     +----------+
```

### Scope Reduction Trigger

**If the design produces 8+ new files or introduces 2+ new classes/services:**

Stop the review. This is a scope reduction trigger.

1. **Explain what's overbuilt** — which components go beyond what the ACs
   require? Which abstractions are premature?
2. **Propose the minimal version** — what's the smallest set of changes
   that satisfies the ACs? What can be deferred to a follow-up?
3. **Ask whether to reduce** — present both versions (full and minimal)
   with the trade-offs. The team decides.

Rule of thumb: if you can't explain the feature's technical design in a
5-minute standup, it's too big for one change set.

### Mandatory Checks (summary)

| Check | What P0 verifies | Layer |
|-------|-----------------|-------|
| Scope smell | >8 new files or 2+ new classes/services → trigger scope reduction | All |
| Search-before-build | Every new dependency: is there a simpler built-in way? | [Layer 1] |
| Completeness | Build/deploy pipeline included? Not just app code? | [Layer 1] |
| DRY | Any duplicated patterns across the proposed components? | [Layer 1] |
| Boring by default | Using well-known patterns unless there's a strong reason not to? | [Layer 1] |
| Scrutinize the new | Any trending/new tech in the design? Justify harder. | [Layer 2] |
| First-principles wins | Any EUREKA moments? Document the reasoning chain. | [Layer 3] |
| ASCII diagrams | Data flow, state machines, dependency graphs present? | All |
| Confidence scores | Every finding tagged with a confidence score? | All |
| Reversibility | Can this be rolled back? Feature flags? Incremental rollout? | All |

For anything that fails: explain why and fix. In auto mode: P0 fixes.
In interactive mode: present findings with the layer tag, confidence
score, and P0's recommended fix.

## When To Use

- After design-ui produces a DESIGNED feature spec
- When a feature's requirements are clear but the technical approach isn't
- When the team needs to evaluate feasibility before committing to implementation
- Before invoking plan-changeset

## Prerequisites

| Artifact | Where | Required? |
|----------|-------|-----------|
| Feature spec (DESIGNED) | `docs/specs/features/<feature>.md` | Yes — must have user stories + ACs + UX and UI design |
| Journey doc(s) | `docs/specs/journeys/J*.feature.md` | Yes — must reference the feature's ACs |
| Existing codebase | Project root | Read to understand current patterns |

**Gate:** Do not start technical design without a DESIGNED spec (after UX and UI design). If the spec doesn't exist or lacks user stories and ACs, route to `write-spec` first. If UX/UI design hasn't been done, route to `design-ux` first.

## Process

### Step 1: Read The Spec And Journeys

Read the DESIGNED feature spec and all referenced journey docs. Understand:
- What user stories need to be satisfied
- What ACs define "done"
- What journey flows exercise this feature
- What Layer 3 findings were flagged (dependencies, gaps)

### Step 2: Codebase Analysis

Scan the existing codebase to understand current patterns and constraints.

```bash
# Project structure
ls -la src/ app/ lib/ components/ 2>/dev/null

# Tech stack
cat package.json 2>/dev/null | head -30
cat go.mod 2>/dev/null | head -20
cat requirements.txt pyproject.toml 2>/dev/null | head -20

# Existing patterns
ls src/components/ src/services/ src/models/ 2>/dev/null
```

Identify:
- **Tech stack:** Languages, frameworks, libraries already in use
- **Patterns:** How existing features are structured (MVC, services, hooks, etc.)
- **Data layer:** Database, ORM, API patterns
- **Testing:** What test frameworks and conventions exist
- **Boundaries:** Where this feature touches existing code

### Step 3: Architecture Decision

Define the high-level approach. This is where you answer:

1. **Where does this feature live?** New module, extension of existing, new service?
2. **What components are needed?** UI components, services, models, API endpoints
3. **What data model changes?** New tables, columns, relationships, migrations
4. **What external dependencies?** Third-party APIs, libraries, services
5. **What's the data flow?** User action → frontend → API → backend → database → response

**Template:**
```markdown
## Technical Design

### Architecture

[2-3 sentences: high-level approach, where it fits in the codebase]

### Components

| Component | Type | Responsibility | New/Modify |
|-----------|------|---------------|------------|
| [Name] | [UI/Service/Model/API/Migration] | [What it does] | [New/Modify existing] |

### Data Model

[Schema changes, new tables/columns, relationships]
[If no data changes: "No data model changes required."]

### Data Flow

[Step-by-step: user action through system and back]

### External Dependencies

[New libraries, APIs, services — or "None"]

### Technology Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| [What needs deciding] | [What we chose] | [Why — reference existing patterns or constraints] |
```

### Step 4: Feasibility Check Against ACs

Walk through each AC from the spec and verify the technical design can satisfy it.

```markdown
### Feasibility Matrix

| AC | Description | Feasible? | Notes |
|----|-------------|-----------|-------|
| MATCH-01 | User sees matches sorted by compatibility | ✅ | Sorting in query, no new index needed |
| MATCH-02 | Matches update in real-time | ⚠️ | Requires WebSocket — adds complexity |
| MATCH-03 | User can filter by timezone | ✅ | Filter on existing timezone column |
```

**If an AC is not feasible:**
- Explain why (technical constraint, dependency, cost)
- Propose alternatives that satisfy the user intent
- Flag as a **feedback loop** to write-spec — the AC or story may need revision

**This is the critical gate.** If the design can't satisfy the spec, the spec needs to change. Don't proceed with a design that leaves ACs unsatisfied.

### Step 5: Risk And Trade-offs

Identify what could go wrong and what trade-offs the design makes.

```markdown
### Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| [What could go wrong] | [Consequence] | [How to prevent or handle] |

### Trade-offs

| Trade-off | Chose | Over | Rationale |
|-----------|-------|------|-----------|
| [What's being traded] | [This approach] | [Alternative] | [Why] |
```

### Step 6: Update The Feature Spec

Write the technical design into the feature spec's Implementation Notes section and update status:

```markdown
# Feature: [Feature Name]

**Status:** BASELINED
```

Add the full technical design (architecture, components, data model, data flow, technology decisions, feasibility matrix, risks, trade-offs) under `## Implementation Notes`.

Mark all planned items as `PLANNED`:
```markdown
## Implementation Notes

- `PLANNED` — UserProfile service (new: src/services/userProfile.ts)
- `PLANNED` — ProfileCard component (new: src/components/ProfileCard.tsx)
- `PLANNED` — users table: add timezone column (migration)
```

### Step 7: Handoff

Present a summary:

```
Feature spec updated: docs/specs/features/<feature-name>.md
Status: BASELINED (was DRAFT)
Components: N new, M modified
Data model changes: [yes/no — summary]
Feasibility: [all ACs feasible / N ACs need spec revision]
Risks: [count]

Ready for change set authoring. Next step:
  "Run plan-changeset against docs/specs/features/<feature-name>.md"
```

**The terminal state is invoking plan-changeset, which then hands off to execute-changeset.**

## Feedback Loops

Technical design often reveals problems upstream. Handle them:

| Discovery | Action |
|-----------|--------|
| AC is technically impossible | Route back to `write-spec` to revise the AC |
| Story assumes nonexistent capability | Route to `validate-feature` for the dependency |
| Design requires new persona understanding | Route to `build-personas` (then return) |
| Journey flow doesn't match what's technically possible | Route to `write-spec` to re-run `write-journeys` |
| Existing code is too tangled to extend | Include refactoring as part of the design |

**Key principle:** It's cheaper to revise the spec now than to discover infeasibility during implementation.

## Anti-Patterns

| Don't | Why | Instead |
|-------|-----|---------|
| Write code or over-spec exact file contents | That's not technical design's job | Define architecture, responsibilities, constraints, and file-level intent |
| Invent new patterns when existing ones work | Increases codebase complexity | Follow established project patterns unless they're clearly broken |
| Ignore existing tech stack | Creates maintenance burden | Use what's already there unless there's a strong reason not to |
| Design without reading ACs | Design may not satisfy requirements | Walk through every AC in the feasibility check |
| Skip risks and trade-offs | Surprises during implementation | Name them now — the team can decide if they're acceptable |
| Over-design | Premature abstraction, wasted effort | Design what the ACs require, not what might be needed someday |

## Routing

| Situation | Route to |
|-----------|----------|
| Design complete, spec BASELINED | `plan-changeset` then `execute-changeset` |
| AC not feasible, spec needs revision | `write-spec` (feedback loop) |
| Missing dependency discovered | `validate-feature` |
| Design reveals persona gap | `build-personas` (then return) |
| No DESIGNED spec exists | `design-ux` (prerequisite, or `write-spec` if no spec at all) |

## Audit Mode

When invoked with `--audit` to review existing technical design:

1. Read the technical design section in the feature spec
2. Check feasibility matrix: every AC still marked feasible given current codebase?
3. Check architecture against actual code: do the components described actually exist?
4. Check data model against actual schema: tables/columns match?
5. Check dependency versions: still current? Breaking changes since design was written?
6. Report: section-by-section PASS/WARN/FAIL

## Pipeline Continuation

### Self-Verify

Before declaring done, verify:

| # | Check | How | PASS/FAIL |
|---|-------|-----|-----------|
| 1 | Feature spec status is BASELINED | grep for "BASELINED" in `docs/specs/features/<name>.md` | |
| 2 | Technical design section exists | grep for "## Technical Design" or "## Implementation Notes" in feature spec | |
| 3 | Feasibility matrix covers all ACs | Every AC from the spec has a row in the feasibility matrix | |
| 4 | No unresolved questions | grep for TBD, TODO, open questions in feature spec technical design section | |

If any check FAILs, fix before continuing. If a fix requires upstream changes, stop and report.

### Chaining

**If `--progressive` flag is present AND self-verify passed:**
- Check `--skip` list. If this skill is in the skip list, pass through to next.
- Invoke next skill: `explore-solutions --progressive --lane <lane>`
  - In greenfield lane: `explore-solutions --progressive --lane greenfield`
  - In brownfield-feature lane: `explore-solutions --progressive --lane brownfield-feature`

**If `--progressive` flag is absent:**
- Report results to user
- Suggest: "Next: consider running `explore-solutions` to challenge the design with alternatives, or `define-code-style` if the approach is well-established"
