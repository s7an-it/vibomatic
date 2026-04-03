---
name: writing-technical-design
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
    greenfield: { position: 9, prev: writing-ui-design, next: spec-style-sync }
    brownfield-feature: { position: 5, prev: journey-sync, next: spec-style-sync }
  progressive: true
  self_verify: true
  human_checkpoint: false
---

# Writing Technical Design

## Overview

Technical design answers HOW to build what the spec defines. It takes a DESIGNED feature spec (after UX and UI design) and produces the architecture, component design, data model, and technology decisions needed to implement it.

This skill transitions a feature spec from DESIGNED → BASELINED.

```
writing-spec              → DRAFT (WHAT: stories, ACs, journeys)
writing-ux-design         → UX-REVIEWED (HOW users experience it: flows, states)
writing-ui-design         → DESIGNED (HOW it looks: components, visual language)
writing-technical-design  → BASELINED (HOW to build it: architecture, data model)
writing-change-set        → implementation manifest + task graph
executing-change-set      → CHANGE-SET-APPROVED (DO: execute the plan on branch)
promoting-change-set      → PROMOTED (APPLY: reviewed branch state to codebase)
verifying-promotion       → VERIFIED (PROVE: tests pass, QA complete)
```

**Announce at start:** "I'm using the writing-technical-design skill to define the technical approach."

## When To Use

- After writing-ui-design produces a DESIGNED feature spec
- When a feature's requirements are clear but the technical approach isn't
- When the team needs to evaluate feasibility before committing to implementation
- Before invoking writing-change-set

## Prerequisites

| Artifact | Where | Required? |
|----------|-------|-----------|
| Feature spec (DESIGNED) | `docs/specs/features/<feature>.md` | Yes — must have user stories + ACs + UX and UI design |
| Journey doc(s) | `docs/specs/journeys/J*.feature.md` | Yes — must reference the feature's ACs |
| Existing codebase | Project root | Read to understand current patterns |

**Gate:** Do not start technical design without a DESIGNED spec (after UX and UI design). If the spec doesn't exist or lacks user stories and ACs, route to `writing-spec` first. If UX/UI design hasn't been done, route to `writing-ux-design` first.

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
- Flag as a **feedback loop** to writing-spec — the AC or story may need revision

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
  "Run writing-change-set against docs/specs/features/<feature-name>.md"
```

**The terminal state is invoking writing-change-set, which then hands off to executing-change-set.**

## Feedback Loops

Technical design often reveals problems upstream. Handle them:

| Discovery | Action |
|-----------|--------|
| AC is technically impossible | Route back to `writing-spec` to revise the AC |
| Story assumes nonexistent capability | Route to `feature-discovery` for the dependency |
| Design requires new persona understanding | Route to `persona-builder` (then return) |
| Journey flow doesn't match what's technically possible | Route to `writing-spec` to re-run `journey-sync` |
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
| Design complete, spec BASELINED | `writing-change-set` then `executing-change-set` |
| AC not feasible, spec needs revision | `writing-spec` (feedback loop) |
| Missing dependency discovered | `feature-discovery` |
| Design reveals persona gap | `persona-builder` (then return) |
| No DESIGNED spec exists | `writing-ux-design` (prerequisite, or `writing-spec` if no spec at all) |

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
- Invoke next skill: `spec-style-sync --progressive --lane <lane>`
  - In greenfield lane: `spec-style-sync --progressive --lane greenfield`
  - In brownfield-feature lane: `spec-style-sync --progressive --lane brownfield-feature`

**If `--progressive` flag is absent:**
- Report results to user
- Suggest: "Next: consider running `spec-style-sync`"
