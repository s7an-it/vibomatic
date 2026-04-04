---
name: writing-spec
description: Use when defining a new feature or change — produces a DRAFT feature spec with user stories, ACs, and journeys before any technical design or code. Supports greenfield new-feature work and brownfield delta-spec work for extensions, bugfix behavior, and contract changes.
inputs:
  required:
    - { path: "docs/specs/vision.md", artifact: vision }
    - { path: "docs/specs/personas/P*.md", artifact: personas }
  optional:
    - { path: "docs/specs/features/*-brief.md", artifact: ship-brief }
outputs:
  produces:
    - { path: "docs/specs/features/<name>.md", artifact: feature-spec, status: DRAFT }
chain:
  lanes:
    greenfield: { position: 4, prev: feature-discovery, next: spec-ac-sync }
    brownfield-feature: { position: 3, prev: feature-discovery, next: journey-sync }
  progressive: true
  self_verify: true
  human_checkpoint: true
---

# Writing Spec

## Overview

A feature spec is the single source of truth for everything a feature is — whether that feature serves a human user or another system. It starts as a DRAFT and matures through its lifecycle:

```
DRAFT               → user stories + ACs + journeys defined, no technical design
UX-REVIEWED         → UX design approved (screen flows, states)
DESIGNED            → UI design approved (visual, components)
BASELINED           → technical design approved (architecture, data model)
CHANGE-SET-APPROVED → implementation executed and reviewed on branch
PROMOTED            → reviewed branch state squash-merged to main
VERIFIED            → implemented, tested, synced (RESOLVED annotations, QA ✅, E2E ✅)
```

This skill produces DRAFT specs. It defines WHAT we're building and HOW it's experienced — never HOW to implement it. UX design comes next in writing-ux-design.

**Announce at start:** "I'm using the writing-spec skill to define the feature requirements."

## Design Alternatives

For each key decision in this phase (feature scope, story granularity, AC approach),
follow the Design Alternatives Protocol (`references/design-alternatives.md`):

1. Identify key decisions — what's in scope vs out, how to split stories, AC specificity level
2. Generate 5 ranked alternatives with justification and trade-offs
3. If `--interactive`: present to user, wait for selection
4. If `--auto`: P0 picks based on research, documents reasoning
5. Log to `docs/specs/decisions/<feature-name>.md`

## G0: Scope Review (after spec is drafted)

Before moving to UX design, challenge the spec scope. P0 runs a CEO-mode review:

**Choose a scope mode:**

| Mode | When | What P0 does |
|------|------|-------------|
| **Expand** | Vision is ambitious, market signals are strong | Push scope up — what's the 10-star version? |
| **Selective Expand** | Good baseline, a few additions would make it great | Hold scope + cherry-pick 1-2 expansions |
| **Hold** | Spec is right-sized for the constraints | Bulletproof the spec as-is, find gaps |
| **Reduce** | Too much for the timeline/team/budget | Surgeon mode — strip to narrowest viable wedge |

In auto mode, P0 picks the mode based on research (market validation, competitor
landscape, team constraints). In interactive mode, presents the modes with
P0's recommendation and asks.

**G0 checks:**
- Is there real demand for this? (P0 searches for validation)
- Is this the narrowest wedge that tests the hypothesis?
- Are there free/existing tools that solve part of this?
- Does the scope match the constraints (timeline, team, budget)?

If G0 changes the scope, update the spec before proceeding.

### The 9 Prime Directives

Every scope review must pressure-test the spec against these directives. They are not aspirational — they are pass/fail gates. A spec that violates any directive is incomplete.

| # | Directive | What P0 checks |
|---|-----------|----------------|
| 1 | **Zero silent failures** | Every failure mode in the spec must be visible — to the user, to the operator, or to monitoring. If a story has a happy path, it must also have a failure path. If an AC says "data is saved," there must be a companion AC for "save fails → user sees error + data is not silently lost." No invisible breakage. |
| 2 | **Every error has a name** | The spec must never say "handle errors" generically. Name the specific failure: `TimeoutError`, `DuplicateEntryConflict`, `UpstreamServiceUnavailable`. If you cannot name the error, you do not understand the failure mode, and the implementing agent will guess wrong. |
| 3 | **Data flows have shadow paths** | Every data flow in the spec implies four paths: happy path, nil/null input, empty input (valid but vacuous), and upstream error (dependency returned garbage). If the spec only describes the happy path, it is 25% complete. P0 must ask: "What happens when this field is nil? Empty string? When the service it depends on is down?" |
| 4 | **Interactions have edge cases** | For user-facing features: double-click, navigate-away mid-action, slow connection (3G), stale state (user left tab open for 2 hours), concurrent edits. For system features: duplicate events, out-of-order delivery, partial failures. The spec must acknowledge these — even if the AC is "system degrades gracefully." |
| 5 | **Observability is scope, not afterthought** | Dashboards, alerts, and structured logging are first-class deliverables, not "nice to haves." If the feature ships without observability, the first production incident will be diagnosed by reading raw logs. P0 asks: "How will we know this is broken at 3am without a user telling us?" If the answer is "we won't," add an AC. |
| 6 | **Diagrams are mandatory** | Every non-trivial flow gets an ASCII diagram in the spec. Data flows, state machines, sequence interactions. If you cannot draw it, you do not understand it. The diagram is the spec's structural proof — it exposes missing transitions, impossible states, and unhandled branches that prose hides. |
| 7 | **Everything deferred must be written down** | If scope review decides "not now," it goes in TODOS.md with the reason and the trigger condition for revisiting. Verbal deferrals do not exist. If it is not written down, it was not deferred — it was forgotten. |
| 8 | **Optimize for the 6-month future** | If this spec solves today's problem but creates next quarter's nightmare (data model that cannot extend, coupling that prevents team parallelism, abstraction that leaks), say so now. The spec must include a "Known Constraints" note for any architectural choice that trades future flexibility for present speed. |
| 9 | **Permission to say "scrap it and do this instead"** | If during scope review P0 discovers a fundamentally better approach — different framing, different decomposition, different scope entirely — table it. Do not polish a suboptimal spec. Present the alternative with reasoning. The sunk cost of the current draft is zero. |

### Cognitive Patterns

These are the mental models P0 uses when making scope decisions. They are not rules — they are lenses applied in combination.

**Classification instinct — reversibility x magnitude.** Every scope decision is categorized using the Bezos one-way/two-way door framework. Two-way doors (reversible, low magnitude): decide fast, move on. One-way doors (irreversible, high magnitude): slow down, get it right. Most decisions are two-way doors disguised as one-way doors by organizational fear.

```
                    Low Magnitude    High Magnitude
                   ┌────────────────┬────────────────┐
  Reversible       │  Just do it    │  Do it, watch  │
  (two-way door)   │  (no review)   │  (monitor)     │
                   ├────────────────┼────────────────┤
  Irreversible     │  Do it, note   │  SLOW DOWN     │
  (one-way door)   │  the trade-off │  (full review) │
                   └────────────────┴────────────────┘
```

**Inversion reflex.** For every "how do we make this succeed?" also ask "what would make this fail?" Inversion reveals risks that forward-only thinking misses. In scope review, this means: after listing what the feature must do, list what would make it useless, dangerous, or abandoned. Those failure conditions become defensive ACs.

**Focus as subtraction.** The primary value of scope review is deciding what NOT to do. Steve Jobs returned to Apple and cut 350 products to 10. The scope review's job is the same — the spec is too big until proven otherwise. Every story that survives review must justify its existence against the cut list.

**Speed calibration.** Fast is the default. Only slow down for irreversible + high-magnitude decisions (upper-right quadrant above). If P0 is deliberating for more than 30 seconds on a two-way door, the deliberation itself is the waste. Make the call, document the reasoning, move.

**Proxy skepticism.** Are the metrics in the spec still serving users, or have they become self-referential? A spec that optimizes "time on page" may be optimizing for confusion, not engagement. P0 asks: "If we hit every AC perfectly, does the user's life actually get better?" If the answer requires a chain of three or more assumptions, the metrics are proxies for proxies.

### Completeness Is Cheap

> AI coding compresses implementation time 10-100x. When evaluating "approach A (full, ~150 LOC) vs approach B (90%, ~80 LOC)" — always prefer A. The 70-line delta costs seconds. "Ship the shortcut" is legacy thinking.

This principle governs every scope trade-off in the AI-assisted era. The old calculus — "is the extra coverage worth the engineering time?" — assumed that coverage had a linear cost in human-hours. It does not anymore. The cost of completeness collapsed. The cost of incompleteness (production incidents, edge case bugs, "we'll handle that later" debt) did not.

**In practice during G0 scope review:**
- When debating whether to add error-path ACs: add them. Cost is ~0. Risk of omission is real.
- When debating whether to spec the edge case: spec it. The implementing agent handles 150 LOC as easily as 80.
- When debating "MVP vs complete": redefine MVP as "complete for the narrowest scope." Do not conflate narrow scope (good — focus) with incomplete implementation (bad — debt).
- The only valid reason to defer is "we do not yet understand the requirement well enough to spec it correctly" — not "it would take too long to build."

## Authoring Modes

Choose one mode before writing:

| Mode | Use when | Output style |
|------|----------|--------------|
| `new-feature` | Net-new greenfield capability | Full DRAFT feature spec |
| `extend-feature` | Brownfield feature extension | Delta-first spec that preserves existing truth |
| `bugfix-behavior` | Intended behavior needs to be clarified for a correction | Minimal behavior contract for the broken path |
| `contract-change` | External/system contract changes without a large new feature | Focused contract and dependency updates |

Default:
- `bootstrap` repos -> `new-feature`
- `convert` repos -> prefer `extend-feature` unless the issue is clearly bug or contract driven

## What Traditional Software Development Gets Wrong

Traditional practice separates "real features" from "infrastructure work." User-facing features get specs, user stories, and acceptance criteria. Backend enablers get Jira tickets with a one-line description. This creates two classes of work — one rigorous, one not — and the unspecified plumbing is where production breaks.

In the vibe code era, AI agents implement both. An agent doesn't care if the consumer is a human clicking a button or a service calling an API — it needs the same structured input: who consumes this, what do they need, how do we verify it works. The spec format is the agent's input contract.

**Vibomatic principle:** Everything that ships gets a feature spec. The spec format is the same. The consumer type changes — not the rigor.

## Feature Types

Every feature spec carries a `Type` tag that identifies its consumer:

| Type | Consumer | Story format | Journey type | Example |
|------|----------|-------------|--------------|---------|
| `Feature` | Human user (persona) | "As P1, I want..." | User journey with UI steps | Match discovery, chat, payments |
| `Enabler` | Other service/feature | "As [service], I need..." | System journey with service interactions | Score recalculation cron, event pipeline, email service |
| `Integration` | External system boundary | "When [external event], the system must..." | Contract journey with request/response | Stripe webhooks, OAuth provider, third-party API |

**The type determines the persona, not the process.** All types go through the same pipeline: writing-spec → writing-ux-design → writing-ui-design → writing-technical-design → writing-change-set → executing-change-set → landing-change-set → verifying-promotion.

### How Types Relate

Features depend on Enablers. Enablers depend on other Enablers. Integrations connect to the outside world. A monetizable user flow typically spans all three:

```
[Integration: Stripe webhook] 
    → [Enabler: payment processing service]
        → [Enabler: subscription state manager]
            → [Feature: user sees premium content]
```

Each node is its own feature spec. The dependency chain is traced through System Dependencies tables and journey preconditions. Layer 3 analysis validates that every link in the chain exists.

## Consumer-First Stories

Traditional user stories assume a human. Vibomatic generalizes the pattern:

**Feature (human consumer):**
```markdown
**As** P1 (Solo Builder),
**I want** to filter matches by timezone,
**So that** I find co-builders available during my working hours.
```

**Enabler (system consumer):**
```markdown
**As** the match-discovery-service,
**I need** recalculated scores reflecting preference changes from the last 24h,
**So that** users see current recommendations when they open the matches tab.
```

**Integration (external system boundary):**
```markdown
**When** Stripe sends a `checkout.session.completed` webhook,
**The system must** activate the user's subscription within 30 seconds,
**So that** the user can access premium features immediately after payment.
```

The format adapts to the consumer. The AC table format stays identical.

## Journeys Are Wrappers

A user journey includes system behavior as implicit steps. The user clicks a button — behind the scenes, 5 services coordinate. The journey documents all of it:

```gherkin
Scenario: User signs up and gets first matches

  When user submits signup form
  Then account is created                            ← system step
  And welcome email is queued                        ← system step (enabler dependency)
  And "user.created" event fires                     ← system step (enabler dependency)
  And user sees confirmation screen                  ← user step

  When matching preferences are saved
  Then score calculation triggers                    ← system step (enabler dependency)
  And user sees "Finding matches..." state           ← user step

  When score calculation completes
  Then user sees top 5 matches                       ← user step
  And match notification sent to matched users       ← system step (enabler dependency)
```

Every system step (`←`) is a dependency on an Enabler or Integration. Layer 3 traces each one back to its feature spec. If the enabler spec doesn't exist, Layer 3 flags it as an **ungrounded precondition** — and writing-spec creates the enabler spec.

**Standalone system journeys** only exist for enablers with no user trigger — cron jobs, scheduled pipelines, autonomous processes. These still get journey docs, but the "persona" is the scheduler or event source, and there are no UI steps.

## When To Use

- After brainstorming or feature-discovery produces a direction/Ship Brief
- When a feature idea needs to be formalized before implementation
- When existing specs need new user stories or ACs added
- When Layer 3 flags an ungrounded precondition (create the enabler spec)
- Before invoking writing-ux-design (requires a DRAFT or higher spec)

## Prerequisites

| Artifact | Where | Required? | If missing |
|----------|-------|-----------|------------|
| Vision | `docs/specs/vision.md` | Recommended | Can proceed without, but stories may lack alignment |
| Personas | `docs/specs/personas/P*.md` | Recommended for Features | Enablers/Integrations use system consumers instead |
| Feature Ship Brief | From feature-discovery | Optional | Can work from brainstorming output or user description |
| Existing specs | `docs/specs/features/` | Check | Read existing specs to learn format and avoid duplication |

## Repository Mode

- **bootstrap:** Create `docs/specs/features/` directory if it doesn't exist. Generate first spec from scratch.
- **convert:** Read existing specs first. Match their format, header fields, and conventions. Don't force vibomatic conventions on first pass — adapt.

In `convert`, this skill should usually write a **delta spec**, not regenerate a full canonical feature document from scratch.

## Process

### Step 0: Determine Feature Type

Before writing anything, classify the work:

| Signal | Type |
|--------|------|
| A human uses it directly (UI, CLI, notification) | `Feature` |
| Other features/services depend on it, no direct user interaction | `Enabler` |
| It handles communication with an external system | `Integration` |

If unclear, ask: "Who breaks if this doesn't work?" If the answer is a user — Feature. If the answer is another service — Enabler. If the answer is "we can't talk to [external system]" — Integration.

### Step 0b: Determine Authoring Mode

Before writing anything, classify the authoring mode:

- Existing repo + new capability in an existing area -> `extend-feature`
- Existing repo + broken known behavior -> `bugfix-behavior`
- Interface or dependency contract changes -> `contract-change`
- Clean repo or new subsystem -> `new-feature`

If the repo is brownfield and has not yet been mapped into vibomatic working mode, route to `repo-conversion` first.

### Step 1: Context Scan

Read existing artifacts to ground the spec in product reality.

```bash
# What exists?
ls docs/specs/features/*.md 2>/dev/null
ls docs/specs/personas/P*.md 2>/dev/null
ls docs/specs/journeys/J*.feature.md 2>/dev/null
cat docs/specs/vision.md 2>/dev/null | head -50
```

If feature specs exist, read one to learn the project's format.

For brownfield work, also read:

```bash
cat docs/specs/project-state.md 2>/dev/null
ls docs/specs/work-items/WI-*.md 2>/dev/null | head
```

If a work item already defines the problem, reuse that framing instead of inventing a new one.

**For Enablers/Integrations:** Also scan for which existing feature specs reference this capability as a dependency or ungrounded precondition.

**Vision-to-spec traceability (MANDATORY):** After reading the vision doc, extract every distinct product concept that implies user-visible behavior. Common examples: deployment modes, pricing tiers, persona-specific flows, platform integrations, privacy/data boundaries. Each concept MUST map to at least one AC in the spec. If the vision says "three deployment modes" and the spec has zero ACs about mode-specific behavior, that is a traceability failure. The spec is the ONLY artifact the code-generation phase reads — anything in the vision that doesn't appear in the spec will be lost.

**Zero-state UX (MANDATORY):** Every user-facing feature MUST include an AC for the first-visit experience — what the user sees before they have configured anything, added any data, or created a profile. If the feature requires setup before showing value, add an AC: "[PREFIX]-ZERO: App shows useful default content before user completes setup." Empty states that say "No data yet, please configure X" are acceptable ONLY if they include a clear call-to-action AND the setup takes under 30 seconds.

**Delta-first rule for brownfield:** In `extend-feature`, `bugfix-behavior`, and `contract-change` modes, explicitly state:
- what behavior already exists and must remain invariant
- what behavior changes
- which existing journeys/specs are being extended rather than replaced

### Step 2: Define The Problem

Write a clear problem statement. This is NOT a solution description — it's what breaks or is missing without this feature.

**For Features:**
```markdown
## Problem Statement

[Who — persona] currently [pain point / gap]. This means [consequence].
[Evidence or context that validates this is worth solving.]
```

**For Enablers:**
```markdown
## Problem Statement

[Which features/services] currently [lack / cannot / must manually handle] [capability].
Without this, [consequence — what breaks for end users or other services].
[List dependent feature specs that need this.]
```

**For Integrations:**
```markdown
## Problem Statement

The system currently [has no way to / manually handles] [external interaction].
This means [consequence — data staleness, manual work, broken flow].
[External system: name, docs URL, API version.]
```

**Gate:** If you cannot articulate the problem without referencing the solution, stop and ask what breaks without this.

For `bugfix-behavior`, the problem statement should capture:
- actual behavior
- expected behavior
- why the mismatch matters

Do not turn a bugfix clarification into a net-new feature narrative unless the evidence shows the capability is actually missing.

### Step 3: Write Consumer Stories

Each story maps to a consumer — human persona, system service, or external event.

**Rules (all types):**
- One goal per story. "and" in the goal → split it.
- Order stories by flow — the sequence consumers encounter them.
- 2-7 stories per feature. >10 → decompose. 1 → might be a task, not a feature.

**Feature stories** reference personas (P1, P2) and describe user intent, not UI elements.

**Enabler stories** name the consuming service and describe the contract it needs.

**Integration stories** use "When [external event]" format and describe the system's obligation.

### Step 4: Write Acceptance Criteria

Each story gets an AC table in the shared contract format:

```markdown
### Acceptance Criteria — US-1: [Story title]

| AC | Description | QA | E2E | Test |
|----|-------------|-----|-----|------|
| [PREFIX]-01 | [Testable condition — one behavior per row] | — | 🔲 | — |
| [PREFIX]-02 | [Another testable condition] | — | 🔲 | — |
```

**Rules:**
- AC prefix derived from feature name (e.g., `MATCH-01`, `RECALC-01`, `STRIPE-01`)
- Each AC is one testable behavior — no compound conditions
- QA, E2E, and Test columns start empty — other skills fill these
- Include happy path, error cases, edge cases, and **failure modes**

**For Enablers, add SLA criteria:**
```markdown
| RECALC-05 | Recalculation completes within 30min SLA | — | 🔲 | — |
| RECALC-06 | On failure, last good data preserved (no data loss) | — | 🔲 | — |
| RECALC-07 | Failure emits alert event within 5min | — | 🔲 | — |
```

**For Integrations, add contract criteria:**
```markdown
| STRIPE-04 | Invalid webhook signature returns 401 | — | 🔲 | — |
| STRIPE-05 | Duplicate event IDs are idempotent (no double-processing) | — | 🔲 | — |
| STRIPE-06 | Webhook processing completes within 10s (Stripe timeout) | — | 🔲 | — |
```

**Gate:** Read each AC aloud. If you can't write a test for it, it's not specific enough. Rewrite.

### Step 5: Identify System Dependencies

Map what this feature depends on and what depends on it.

```markdown
## System Dependencies

### This feature depends on:

| Dependency | Type | Spec exists? | What it provides |
|-----------|------|-------------|-----------------|
| User authentication | Enabler | ✅ feature-auth.md | Authenticated session |
| Email service | Enabler | ❌ — needs spec | Transactional email delivery |
| Stripe API | Integration | ❌ — needs spec | Payment processing |

### Other features depend on this:

| Consumer | Type | What it needs from us |
|----------|------|----------------------|
| Match discovery UI | Feature | Fresh scores via API |
| Recommendation emails | Enabler | Top matches per user |
```

**When a dependency spec doesn't exist (❌):** Flag it. After this spec is complete, create the dependency spec. This is how the full chain gets built — each spec reveals what's missing below it.

### Step 6: Assemble The Feature Spec

Write the complete DRAFT spec to `docs/specs/features/<feature-name>.md`:

```markdown
# Feature: [Feature Name]

**Status:** DRAFT
**Type:** [Feature | Enabler | Integration]
**Consumers:** [P1, P3 | service names | external system]
**Priority:** [from Ship Brief or user input]
**Created:** [YYYY-MM-DD]

---

## Problem Statement

[From Step 2]

---

## User Stories

[From Step 3 — all stories with AC tables from Step 4]

---

## System Dependencies

[From Step 5]

---

## Technical Design

_To be added by writing-technical-design._

---

## Implementation Notes

_To be added by writing-change-set and executing-change-set._

---

## Journey References

_To be added in Step 7._
```

### Step 7: Trigger Journey Sync

After the spec is saved, invoke `journey-sync` to create or update journeys.

**For Features:** User journeys with UI steps + system steps marked as dependencies.

**For Enablers:** System journeys with service interactions, triggers, and SLA verification.

**For Integrations:** Contract journeys with request/response flows, error handling, and timeout behavior.

**What to expect back:**
- Journey file(s) referencing the AC IDs from Step 4
- Layer 3 analysis findings:
  - **Contradictions** → fix in spec
  - **Missing transitions** → add stories or ACs
  - **Ungrounded preconditions** → create enabler spec (recursive)
  - **Concept fragmentation** → consolidate naming in spec

**Loop:** If Layer 3 reveals gaps, go back to Steps 3-4 and fix the stories/ACs. Re-run journey-sync. Repeat until Layer 3 is clean or remaining issues are flagged as known dependencies.

**Recursive spec creation:** When Layer 3 flags an ungrounded precondition that needs its own enabler spec, queue it. Complete the current spec first, then create the enabler spec using this same skill. The dependency chain builds top-down — Features reveal Enablers, Enablers reveal other Enablers and Integrations.

### Step 8: Update Journey References

After journey-sync completes, update the spec's Journey References section:

```markdown
## Journey References

| Journey | Scenarios | ACs Covered | Type |
|---------|-----------|-------------|------|
| J05: Match discovery flow | Scenario 1, 3 | MATCH-01, MATCH-02, MATCH-05 | User |
| J12: Score recalculation | Scenario 1 | RECALC-01, RECALC-02 | System |
```

### Step 9: Dependency Spec Queue

If Steps 5 or 7 revealed missing dependency specs, present the queue:

```
Missing dependency specs to create:
  1. feature-email-service.md (Enabler) — needed by: MATCH-03, J05 step 3
  2. feature-stripe-integration.md (Integration) — needed by: US-3, J05 step 7

Create these now? (Each goes through writing-spec → writing-ux-design → writing-ui-design → writing-technical-design → writing-change-set → executing-change-set → landing-change-set → verifying-promotion)
```

This is how a single feature request cascades into the full system specification. The user approves which dependencies to spec now vs defer.

### Step 10: Handoff

The DRAFT spec is complete. Present a summary:

```
Feature spec saved: docs/specs/features/<feature-name>.md
Status: DRAFT
Type: [Feature | Enabler | Integration]
Stories: N user stories, M acceptance criteria
Journeys: [list of journey files created/updated]
Layer 3 issues: [resolved count] resolved, [open count] flagged as dependencies
Dependency queue: [count] enabler/integration specs to create

Ready for UX design. Next step:
  "Run writing-ux-design against docs/specs/features/<feature-name>.md"
```

**The terminal state is invoking writing-ux-design.** This skill does not write code, choose technologies, or make architecture decisions.

## The Cascade Effect

This is what makes vibomatic's approach different from traditional spec writing. In traditional development, you spec the feature and hand-wave the infrastructure. In vibomatic, specifying a feature **automatically reveals** every enabler and integration it depends on:

```
User says: "I want match recommendations"
    ↓
writing-spec creates: feature-match-discovery.md (Feature)
    ↓ Layer 3 finds ungrounded preconditions:
writing-spec creates: feature-score-recalculation.md (Enabler)
writing-spec creates: feature-notification-service.md (Enabler)
    ↓ Layer 3 finds more:
writing-spec creates: feature-email-delivery.md (Integration)
    ↓
Full system specified. Nothing hand-waved.
```

Each spec is its own file (agent-friendly: parallel processing, clean diffs, targeted reads). Each links to the others through System Dependencies and Journey References. The chain is traceable end-to-end.

**This is the vibe code era improvement:** The agent doesn't just implement what you ask — it discovers what you need. The spec process itself is the architecture discovery tool.

## Anti-Patterns

| Don't | Why | Instead |
|-------|-----|---------|
| Skip enabler specs ("it's just a cron") | Unspecified plumbing is where production breaks | Every shipping component gets a feature spec |
| Write implementation details in stories | Couples requirements to a solution | Describe consumer intent, let downstream design skills choose the how |
| Skip personas for Features | Stories become generic, untestable | Reference P*.md personas or flag their absence |
| Write ACs as steps | Steps describe procedure, not criteria | Write assertions: "User sees X" not "User clicks Y then sees X" |
| Create one giant story | Untestable, no granularity | Split by consumer goal — one goal per story |
| Skip journey-sync | Miss hidden dependencies between features | Always run it — Layer 3 finds what humans miss |
| Add technical design | Not this skill's job | Leave Technical Design empty for writing-ux-design and beyond |
| Hand-wave dependencies | "We'll figure out the email service later" | Create the enabler spec now or explicitly defer with reasoning |
| Put everything in one spec file | Agents work better with focused files | One spec per feature, cross-reference by ID |

## Routing

| Situation | Route to |
|-----------|----------|
| Spec complete, ready for UX design | `writing-ux-design` |
| Layer 3 reveals missing persona | `persona-builder` (then return) |
| Layer 3 reveals concept fragmentation | Fix in spec, then re-run `journey-sync` |
| Layer 3 reveals dependency on unbuilt feature | Create enabler spec (this skill, recursive) |
| User wants to validate the feature idea first | `feature-discovery` (then return here) |
| Spec exists but ACs are weak/missing | `spec-ac-sync` (can run standalone) |
| Dependency queue approved | Run this skill again for each queued spec |

## Audit Mode

When invoked with `--audit` to review existing feature specs:

1. Glob `docs/specs/features/*.md` (exclude briefs)
2. For each spec:
   - Vision-to-spec traceability: every vision concept has ≥1 AC?
   - Zero-state AC exists for Feature type?
   - AC table uses shared contract format?
   - No compound ACs?
   - System Dependencies section present?
   - Status is valid lifecycle value?
3. Report: spec-by-spec PASS/WARN/FAIL with specific gaps

## Pipeline Continuation

### Self-Verify

Before declaring done, verify:

| # | Check | How | PASS/FAIL |
|---|-------|-----|-----------|
| 1 | Feature spec file exists | `ls docs/specs/features/<name>.md` | |
| 2 | Spec has Status: DRAFT | grep for "Status: DRAFT" in spec | |
| 3 | Spec has AC table | grep for AC table header in spec | |
| 4 | Spec has System Dependencies section | grep for "System Dependencies" heading in spec | |
| 5 | Vision-to-spec traceability check | verify vision concepts map to ACs in spec | |
| 6 | Zero-state AC exists (Feature type) | grep for ZERO AC in spec (Feature type only) | |
| 7 | No unresolved questions | grep for TBD, TODO, open questions in spec | |

If any check FAILs, fix before continuing. If a fix requires upstream changes, stop and report.

### Chaining

**If `--progressive` flag is present AND self-verify passed:**
- Check `--skip` list. If this skill is in the skip list, pass through to next.
- In greenfield lane: `spec-ac-sync --progressive --lane greenfield`
- In brownfield-feature lane: `journey-sync --progressive --lane brownfield-feature`

**If `--progressive` flag is absent:**
- Report results to user
- Suggest: "Next: consider running `spec-ac-sync`" (greenfield) or "`journey-sync`" (brownfield-feature)
