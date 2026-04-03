---
name: workflow-compass
description: >
  Know which vibomatic skill to run next based on repo state, change type, and current
  project artifacts. Routes greenfield repos directly into the core pipeline and routes
  existing repos through repo-conversion first. Use when: "what should I do next",
  "which skill do I run", "what's the right order", "product workflow", "skill map",
  "where do I start", "what lane is this", "is this a feature or a bugfix", or when
  a skill finishes and its findings need a concrete next step.
inputs:
  required: []
  optional: []
outputs:
  produces: []
chain:
  lanes: {}
  progressive: false
  self_verify: false
  human_checkpoint: false
---

# Workflow Compass

Vibomatic now routes on two axes:

1. **Repo state**
   - `bootstrap` = greenfield / clean repo
   - `convert` = brownfield / existing repo
2. **Change type**
   - `conversion`
   - `feature`
   - `bugfix`
   - `regression`
   - `refactor`
   - `drift`
   - `chore`

This skill decides the lane before it recommends the next skill.

## Repository Mode Gate

Before recommending any next skill, detect repository mode using `REPO_MODES.md`:

- `bootstrap`: initialize missing vibomatic structure and run the greenfield lane
- `convert`: preserve current truth first, then route to the right brownfield lane

If mode is ambiguous, default to `convert`.

## Routing Rule

**Clean repo:** run vibomatic directly.

**Existing repo:** run `repo-conversion` first unless the repo has already been mapped into vibomatic working mode.

Signals that conversion has already happened:

- `docs/specs/project-state.md` exists
- `docs/specs/work-items/INDEX.md` exists
- the repo already uses lane-based work items and canonical vibomatic status files

If these are missing in a real brownfield repo, route to `repo-conversion`.

## Skill Availability Contract

`workflow-compass` must always route to available skills first.
Skill-name contract is machine-checked in `skills-manifest.json` via `node scripts/lint-skills-manifest.mjs`.

### Core Pack (always available in vibomatic)

- `vision-sync`
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
- `research`
- `executing-change-set`

### External Add-On Packs (optional)

Only route to external skills when explicitly installed or confirmed.

- **coreyhaines-marketing-pack (optional):**
  `product-marketing-context`, `customer-research`, `market-competitors`, `competitor-alternatives`,
  `copywriting`, `page-cro`, `launch-strategy`, `market-social`,
  `market-ads`, `market-emails`, `signup-flow-cro`, `onboarding-cro`

- **planning add-on (optional):**
  `writing-plans` (external add-on; for vibomatic repos, use core `writing-change-set` unless the repo explicitly prefers an external planning flow)

If an external skill is not confirmed, provide a core-pack fallback route.
External pack definitions live in `EXTERNAL_ADDONS.md`.

## The Routing Skills

### `repo-conversion`
Maps a brownfield repo into vibomatic working mode. Produces `project-state.md`,
repo-canonical work items, and compatibility notes. Logs findings, then stops.

### `bugfix-brief`
Root-cause-first bug and regression planning. Produces an implementation-ready
correction brief without forcing a full feature-spec rewrite.

### `work-item-sync`
Projects repo-canonical work items to GitHub Issues. GitHub is a projection, not
the source of truth.

## The Product Pipeline Skills

- `vision-sync`
- `persona-builder`
- `feature-discovery`
- `writing-spec`
- `writing-ux-design`
- `writing-ui-design`
- `writing-technical-design`
- `writing-change-set`
- `executing-change-set`
- `review-protocol`
- `promoting-change-set`
- `verifying-promotion`
- `journey-sync`
- `spec-ac-sync`
- `spec-code-sync`
- `journey-qa-ac-testing`
- `agentic-e2e-playwright`
- `feature-marketing-insights`

## Lane Model

### Lane 1: Greenfield Feature

Use when:
- mode = `bootstrap`
- the repo is clean or effectively clean
- behavior is still being discovered

Route:
1. `vision-sync`
2. `persona-builder`
3. `feature-discovery`
4. `writing-spec`
5. `spec-ac-sync`
6. `journey-sync`
7. `writing-ux-design`
8. `writing-ui-design`
9. `writing-technical-design`
10. `writing-change-set`
11. `executing-change-set`
12. `review-protocol`
13. `promoting-change-set`
14. `verifying-promotion`

### Lane 1b: Auto Greenfield ("build me an app")

Use when:
- mode = `bootstrap`
- the prompt is effectively "build me an app"
- there is no meaningful existing repo state to preserve

Behavior:
- run the greenfield lane end-to-end automatically
- stop only for real blockers, contradictions, or missing product intent that cannot be safely assumed

### Lane 2: Brownfield Conversion

Use when:
- mode = `convert`
- the repo has not yet been mapped into vibomatic working mode

Route:
1. `repo-conversion`
2. `work-item-sync` if the team wants GitHub visibility
3. route each resulting item by type

### Lane 3: Brownfield Feature Extension

Use when:
- mode = `convert`
- the repo is already mapped
- the item type is `feature`

Route:
1. `spec-code-sync`
2. `feature-discovery`
3. `writing-spec` in delta mode
4. `journey-sync` in expand mode
5. `writing-technical-design` if architecture changes
6. `writing-change-set`
7. `executing-change-set`
8. `review-protocol`
9. `promoting-change-set`
10. `verifying-promotion`

### Lane 4: Bugfix / Regression

Use when:
- item type is `bugfix` or `regression`
- behavior is wrong, broken, or changed unexpectedly

Route:
1. `bugfix-brief`
2. `writing-change-set` if a formal implementation plan is needed
3. `executing-change-set`
4. `review-protocol`
5. `promoting-change-set`
6. `verifying-promotion`
7. `journey-qa-ac-testing` or `agentic-e2e-playwright` as targeted support when the verification path needs direct runtime evidence

### Lane 5: Drift / Maintenance

Use when:
- item type is `drift`
- specs, journeys, and code disagree

Route:
1. `spec-code-sync`
2. selective spec or code remediation
3. `journey-sync` refresh if user flows changed
4. `work-item-sync` if tracker visibility matters

### Lane 6: Refactor / Chore

Use when:
- item type is `refactor` or `chore`
- behavior should stay materially the same, or the work is primarily structural/state-management

Route:
1. `spec-code-sync` if behavior invariants or current truth are unclear
2. `writing-change-set`
3. `executing-change-set`
4. `review-protocol`
5. `promoting-change-set`
6. `verifying-promotion` when the change touches shipped behavior, tests, or user journeys
7. `work-item-sync` if tracker visibility matters

## Change-Type Detection

Use these signals:

| Signal | Change Type | First Skill |
|--------|-------------|-------------|
| Existing repo needs vibomatic adoption | `conversion` | `repo-conversion` |
| Net-new capability or extension with user value | `feature` | `feature-discovery` |
| Broken behavior | `bugfix` | `bugfix-brief` |
| Previously working behavior stopped working | `regression` | `bugfix-brief` |
| Spec/code mismatch | `drift` | `spec-code-sync` |
| Structural cleanup with no intended behavior change | `refactor` | `writing-change-set` (or `spec-code-sync` first if invariants are unclear) |
| Tracker, docs, or housekeeping item | `chore` | `work-item-sync` or `writing-change-set`, depending on whether it changes code or project state |

## Cross-Skill Routing

| Skill just finished | Finding | Route to |
|--------------------|---------|----------|
| `repo-conversion` | Brownfield map completed | route by work-item type |
| `repo-conversion` | Bugs/regressions logged | `bugfix-brief` |
| `repo-conversion` | Feature opportunities logged | `feature-discovery` |
| `repo-conversion` | Drift logged | `spec-code-sync` |
| `repo-conversion` | Refactors or chores logged | `writing-change-set` or `work-item-sync`, depending on scope |
| `repo-conversion` | Tracker visibility needed | `work-item-sync` |
| `bugfix-brief` | Root cause and fix scope defined | `writing-change-set` or `executing-change-set`, depending on plan depth needed |
| `writing-change-set` | Implementation manifest complete | `executing-change-set` |
| `executing-change-set` | Task execution complete, final diff reviewed | `promoting-change-set` |
| `executing-change-set` | Task reveals spec/UX/UI/tech contradiction | loop back to the relevant upstream skill |
| `bugfix-brief` | Issue is actually missing capability | `feature-discovery` |
| `bugfix-brief` | Issue is actually spec drift | `spec-code-sync` |
| `spec-code-sync` | Drift confirmed | remediation path or work-item update |
| `spec-code-sync` | Structural cleanup with behavior preserved | `writing-change-set` |
| `feature-discovery` | Not a new feature, but a broken existing flow | `bugfix-brief` |
| `feature-discovery` | Existing repo not yet mapped | `repo-conversion` |
| `journey-sync` | Missing producer, missing persona, or fragmented concept | `feature-discovery` or `persona-builder` |
| `journey-qa-ac-testing` | Runtime failure in known behavior | `bugfix-brief` |
| `journey-qa-ac-testing` | Vague or missing ACs | `spec-ac-sync` |
| `feature-marketing-insights` | Product context stale after spec changes | `spec-code-sync` then refresh marketing |

## Project State Checks

Before recommending a lane, inspect:

```bash
# Foundational vibomatic state
ls docs/specs/project-state.md 2>/dev/null
ls docs/specs/work-items/INDEX.md 2>/dev/null

# Canonical product artifacts
ls docs/specs/vision.md 2>/dev/null
ls docs/specs/personas/P*.md 2>/dev/null | wc -l
ls docs/specs/features/*.md 2>/dev/null | wc -l
ls docs/specs/journeys/J*.feature.md 2>/dev/null | wc -l

# Existing test and code reality
find . -path "*/test*" -o -path "*/e2e*" 2>/dev/null | head
git log --oneline -5 -- docs/specs/ 2>/dev/null
```

Interpretation:

| State | Meaning | Start with |
|------|---------|------------|
| Clean repo, little established structure | Greenfield | `vision-sync` or `workflow-compass` lane recommendation |
| Existing repo, no vibomatic state files | Brownfield unmapped | `repo-conversion` |
| Existing repo, mapped, feature request | Brownfield feature lane | `spec-code-sync` then `feature-discovery` |
| Existing repo, mapped, bug or regression | Correction lane | `bugfix-brief` |
| Existing repo, mapped, doc/code mismatch | Drift lane | `spec-code-sync` |
| Work items exist, no external visibility | Tracker projection gap | `work-item-sync` |

## Recommendation Style

When answering "what should I do next?", give:

1. detected repo mode
2. detected change type
3. selected lane
4. immediate next skill
5. why that route is correct

Example:

> Repo mode: convert. Change type: regression. This repo is already mapped, so do not rerun conversion. Use the bugfix lane. Next skill: `bugfix-brief`, because the immediate problem is correcting broken behavior, not authoring a new feature.
