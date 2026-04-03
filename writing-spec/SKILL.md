---
name: writing-spec
description: Use when defining a new feature or change — produces a DRAFT feature spec with user stories, ACs, and journeys before any technical design or code
---

# Writing Spec

## Overview

A feature spec is the single source of truth for everything a feature is. It starts as a DRAFT (business requirements only) and matures through its lifecycle:

```
DRAFT      → user stories + ACs + journeys defined, no technical design
BASELINED  → technical design added by writing-plans, approved for implementation
VERIFIED   → implemented, tested, synced (RESOLVED annotations, QA ✅, E2E ✅)
```

This skill produces DRAFT specs. It defines WHAT we're building and HOW users experience it — never HOW to implement it. Technical design comes later in writing-plans.

**Announce at start:** "I'm using the writing-spec skill to define the feature requirements."

## When To Use

- After brainstorming or feature-discovery produces a direction/Ship Brief
- When a feature idea needs to be formalized before implementation
- When existing specs need new user stories or ACs added
- Before invoking writing-plans (writing-plans requires a DRAFT or higher spec)

## What A Feature Is

A feature is a cohesive unit of user value. It contains one or more user stories that together deliver a capability. The feature spec is the complete record of that feature — from requirements through verification.

A feature spec contains:
- **Problem statement** — what breaks without this feature
- **User stories** — "As [persona], I want [goal] so that [value]"
- **Acceptance criteria** — testable conditions per story (shared AC table format)
- **Journey references** — which journeys exercise this feature
- **Implementation notes** — added later by writing-plans (PLANNED/RESOLVED)
- **QA + E2E status** — added later by testing skills

This skill writes the first three and triggers the fourth. The rest come later.

## Prerequisites

Before writing a spec, these should exist (or be created as part of this process):

| Artifact | Where | Required? | If missing |
|----------|-------|-----------|------------|
| Vision | `docs/specs/vision.md` | Recommended | Can proceed without, but stories may lack alignment |
| Personas | `docs/specs/personas/P*.md` | Recommended | Stories will lack persona grounding — flag this |
| Feature Ship Brief | From feature-discovery | Optional | Can work from brainstorming output or user description |
| Existing specs | `docs/specs/features/` | Check | Read existing specs to learn format and avoid duplication |

## Repository Mode

- **bootstrap:** Create `docs/specs/features/` directory if it doesn't exist. Generate first spec from scratch.
- **convert:** Read existing specs first. Match their format, header fields, and conventions. Don't force vibomatic conventions on first pass — adapt.

## Process

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

### Step 2: Define The Problem

Write a clear problem statement. This is NOT a solution description — it's what breaks or is missing without this feature.

**Template:**
```markdown
## Problem Statement

[Who] currently [pain point / gap]. This means [consequence].
[Evidence or context that validates this is worth solving.]
```

**Gate:** If you cannot articulate the problem without referencing the solution, stop and ask the user what user pain this addresses.

### Step 3: Write User Stories

Each user story follows the standard format and maps to a persona:

```markdown
## User Stories

### US-1: [Story title]

**As** [persona from P*.md],
**I want** [specific goal — what the user does],
**So that** [value — why it matters to them].
```

**Rules:**
- One goal per story. If a story has "and" in the goal, split it.
- Reference real personas (P1, P2, etc.) when they exist.
- Stories describe user intent, not UI elements. "I want to filter by timezone" not "I want a dropdown with timezone options."
- Order stories by user flow — the sequence a user would naturally encounter them.

**How many stories?** A feature typically has 2-7 stories. If you have more than 10, the feature may need decomposition. If you have 1, it might be a task, not a feature.

### Step 4: Write Acceptance Criteria

Each user story gets an AC table in the shared contract format:

```markdown
### Acceptance Criteria — US-1: [Story title]

| AC | Description | QA | E2E | Test |
|----|-------------|-----|-----|------|
| [PREFIX]-01 | [Testable condition — one behavior per row] | — | 🔲 | — |
| [PREFIX]-02 | [Another testable condition] | — | 🔲 | — |
```

**Rules:**
- AC prefix derived from feature/story name (e.g., `MATCH-01`, `ONBOARD-01`)
- Each AC is one testable behavior — no compound conditions ("X and Y" → two rows)
- QA, E2E, and Test columns start empty (`—` / `🔲` / `—`) — other skills fill these
- Include happy path, error cases, and edge cases
- ACs are assertions, not steps: "User sees confirmation toast" not "User clicks submit and sees confirmation toast"

**Gate:** Read each AC aloud. If you can't write a test for it, it's not specific enough. Rewrite.

### Step 5: Assemble The Feature Spec

Write the complete DRAFT spec to `docs/specs/features/<feature-name>.md`:

```markdown
# Feature: [Feature Name]

**Status:** DRAFT
**Personas:** [P1, P3]
**Priority:** [from Ship Brief or user input]
**Created:** [YYYY-MM-DD]

---

## Problem Statement

[From Step 2]

---

## User Stories

[From Step 3 — all stories with AC tables from Step 4]

---

## Implementation Notes

_To be added by writing-technical-design._

---

## Journey References

_To be added in Step 6._
```

### Step 6: Trigger Journey Sync

After the spec is saved, invoke `journey-sync` to create or update journeys that exercise the new feature's user stories.

**What to pass:** The new spec file path and the personas involved.

**What to expect back:**
- Journey file(s) referencing the AC IDs from Step 4
- Layer 3 analysis findings:
  - **Contradictions** → fix in spec
  - **Missing transitions** → add stories or ACs
  - **Ungrounded preconditions** → flag dependency on other features
  - **Concept fragmentation** → consolidate naming in spec

**Loop:** If Layer 3 reveals gaps, go back to Steps 3-4 and fix the stories/ACs. Re-run journey-sync. Repeat until Layer 3 is clean or remaining issues are flagged as known dependencies.

### Step 7: Update Journey References

After journey-sync completes, update the spec's Journey References section:

```markdown
## Journey References

| Journey | Scenarios | ACs Covered |
|---------|-----------|-------------|
| J05: [Journey name] | Scenario 1, Scenario 3 | MATCH-01, MATCH-02, MATCH-05 |
| J02: [Journey name] | Scenario 4 | MATCH-03, MATCH-04 |
```

### Step 8: Handoff

The DRAFT spec is complete. Present a summary:

```
Feature spec saved: docs/specs/features/<feature-name>.md
Status: DRAFT
Stories: N user stories, M acceptance criteria
Journeys: [list of journey files created/updated]
Layer 3 issues: [resolved count] resolved, [open count] flagged as dependencies

Ready for technical design. Next step:
  "Run writing-technical-design against docs/specs/features/<feature-name>.md"
```

**The terminal state is invoking writing-technical-design.** This skill does not write code, choose technologies, or make architecture decisions.

## Anti-Patterns

| Don't | Why | Instead |
|-------|-----|---------|
| Write implementation details in stories | Couples requirements to a solution | Describe user intent, let writing-technical-design choose the how |
| Skip personas | Stories become generic, untestable | Reference P*.md personas or flag their absence |
| Write ACs as steps | Steps describe procedure, not criteria | Write assertions: "User sees X" not "User clicks Y then sees X" |
| Create one giant story | Untestable, no granularity | Split by user goal — one goal per story |
| Skip journey-sync | Miss hidden dependencies between features | Always run it — Layer 3 is where the real gaps surface |
| Add technical design | Not this skill's job | Leave Implementation Notes empty for writing-technical-design |

## Routing

| Situation | Route to |
|-----------|----------|
| Spec complete, ready for technical design | `writing-technical-design` |
| Layer 3 reveals missing persona | `persona-builder` (then return) |
| Layer 3 reveals concept fragmentation | Fix in spec, then re-run `journey-sync` |
| Layer 3 reveals dependency on unbuilt feature | `feature-discovery` for the dependency |
| User wants to validate the feature idea first | `feature-discovery` (then return here) |
| Spec exists but ACs are weak/missing | `spec-ac-sync` (can run standalone) |
