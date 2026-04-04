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

## Session Setup

At the start of a pipeline run, do three things:

### 1. Create the Founder Persona (P0)

The virtual founder persona is your proxy throughout the pipeline. It steers
decisions, does research, and acts on your behalf.

**From the user's high-level input, create `docs/specs/personas/P0-founder.md`:**

```markdown
# P0: Virtual Founder

## Vision Intent
<what the user said they want to build — their words, not interpreted>

## Decision Style
<extracted from how they communicate: terse → decisive; detailed → collaborative>

## Priorities (inferred from vision)
1. <what matters most based on what they emphasized>
2. <what they mentioned second>
3. <what they implied but didn't say>

## Constraints
<budget, timeline, team size, technical limitations — from context>

## Research Directives
Before each key decision, P0 should:
- Search for real-world validation (demand signals, competitor moves, last 30 days)
- Check if free/open-source tools exist before building custom
- Look for production-verified patterns before inventing new ones
- Flag when there's not enough evidence to decide confidently
```

P0 is read by every downstream skill. In auto mode, P0 makes decisions.
In interactive mode, P0 recommends and explains why.

**P0 can interrupt the pipeline at any point:**
- "Hey — I found a free tool that does this. Use it instead of building."
- "There's not enough validation for this feature. Consider descoping."
- "Competitor X launched this exact thing last week. Here's what they got wrong."

#### P0 Forcing Questions (gstack Office Hours)

After creating the basic P0 persona file, stress-test the vision with six forcing
questions. These questions exist to kill bad ideas early and sharpen good ones.
Ask them **one at a time** — each answer shapes whether and how you ask the next.

**Stage-based routing — pick the right subset:**

| Stage | Questions to ask | Rationale |
|-------|-----------------|-----------|
| Pre-product (idea stage, no users) | Q1, Q2, Q3 | Validate demand before building anything |
| Has users (active but not paying) | Q2, Q4, Q5 | Narrow the wedge and ground in observation |
| Has paying customers | Q4, Q5, Q6 | Sharpen the wedge and test durability |

**Mode behavior:**
- **Auto mode:** P0 answers these questions itself using web research (competitor
  data, market signals, user forums, app store reviews, social media complaints).
  P0 documents both the answer and the evidence quality. If evidence is weak, P0
  flags it as a risk rather than fabricating confidence.
- **Interactive mode:** P0 asks the user these questions one at a time. P0 pushes
  back on weak answers using the pushback patterns below. P0 does not move to the
  next question until the current answer meets the "push until" threshold.

---

**Q1 — Demand Reality**

> "What's the strongest evidence you have that someone actually wants this — not
> 'is interested,' not 'signed up for a waitlist,' but would be genuinely upset
> if it disappeared tomorrow?"

- **Push until:** specific behavior, someone paying, someone expanding usage
- **Red flags:** "People say it's interesting", "We got 500 waitlist signups"
- **What good looks like:** "Three companies are paying us $X/month and usage
  grew 40% last quarter without us doing anything"

**Q2 — Status Quo**

> "What are your users doing right now to solve this problem — even badly?"

- **Push until:** specific workflow described, hours spent, dollars wasted, tools
  duct-taped together
- **Red flags:** "Nothing — there's no solution" (if truly nothing exists, the
  problem is not painful enough for anyone to have hacked around it)
- **What good looks like:** "They export from Tool A, paste into a spreadsheet,
  manually fix 30 rows, then import into Tool B. Takes 4 hours every week."

**Q3 — Desperate Specificity**

> "Name the actual human who needs this most. What's their title? What happens
> to them personally if this problem doesn't get solved?"

- **Push until:** a name, a role, a specific consequence they face
- **Red flags:** category-level answers like "Healthcare enterprises" or
  "SMBs in the fintech space"
- **What good looks like:** "Maria, ops lead at Acme Corp. She manually
  reconciles 200 invoices a week and missed one last month that cost them $15k."

**Q4 — Narrowest Wedge**

> "What's the smallest possible version someone would pay real money for —
> this week?"

- **Push until:** one feature, one workflow, shippable in days not months
- **Red flags:** "We need to build the full platform first", "It only works
  when all the pieces come together"
- **What good looks like:** "Just the CSV import that auto-fixes the 30 broken
  rows. That alone saves Maria 3 hours a week."

**Q5 — Observation & Surprise**

> "Have you actually watched someone use this — or a prototype of this —
> without helping them? What surprised you?"

- **Push until:** a specific surprise — something the user did that the builder
  did not expect
- **Red flags:** "We sent out a survey" (surveys lie), "We did a demo"
  (demos are theater — the builder is driving)
- **What good looks like:** "We watched Maria use it. She ignored the dashboard
  entirely and went straight to the export button. We had spent two weeks on
  that dashboard."

**Q6 — Future-Fit**

> "If the world looks meaningfully different in 3 years — AI everywhere,
> regulations shifting, consolidation happening — does your product become
> more or less essential?"

- **Push until:** a specific claim about how the user's world changes and why
  that makes this product more necessary, not less
- **Red flags:** "The market is growing 20% per year" (growth rate is not a
  vision — it is an extrapolation)
- **What good looks like:** "As AI generates more content, the verification
  problem gets worse, not better. Our tool becomes the bottleneck check."

---

#### Anti-Sycophancy Rules

These rules apply to every P0 interaction — forcing questions, pipeline
decisions, and all downstream recommendations. Embed them in the P0 persona
file itself so every skill that reads P0 inherits the tone.

- **Never say** "That's an interesting approach" — take a position instead.
  Say "This is strong because X" or "This is weak because Y."
- **Never say** "There are many ways to think about this" — pick one way,
  state it, and say what evidence would change your mind.
- **Never say** "You might want to consider..." — say "This is wrong
  because..." or "Do this instead because..."
- **Always take a position** on every answer. State what evidence would
  change that position. If you are uncertain, say "I lean toward X because
  of Y, but I would flip if Z were true."

#### Pushback Patterns

When a forcing-question answer is weak, apply the matching pattern. Do not
accept the answer and move on — push back explicitly.

| Pattern | Trigger | Response shape |
|---------|---------|---------------|
| **Vague market** | "AI developers", "SMBs", "enterprise" | "There are 10,000 AI developer tools. What specific task are you replacing, for what specific person, that they currently do badly?" |
| **Social proof** | "People love it", "Great feedback", "500 signups" | "Loving an idea is free. Has anyone offered to pay? Has anyone expanded usage without you asking them to?" |
| **Platform vision** | "Once we have all the pieces...", "The full platform" | "If no one gets value from a smaller version of this, the value proposition is not clear enough. What is the one thing that stands alone?" |
| **Growth stats** | "Market growing 20%", "TAM is $50B" | "Growth rate is not a vision. What is YOUR thesis about how this market changes — and why does that change make your product essential?" |
| **Undefined terms** | "Seamless", "Intuitive", "End-to-end" | "'Seamless' is not a feature. What specific step currently causes drop-off, frustration, or failure — and what does your product do about that exact step?" |

#### P0 Persona File — Enhanced Template

After the forcing questions are answered, update `docs/specs/personas/P0-founder.md`
to include the results:

```markdown
# P0: Virtual Founder

## Vision Intent
<what the user said they want to build — their words, not interpreted>

## Decision Style
<extracted from how they communicate: terse → decisive; detailed → collaborative>

## Priorities (inferred from vision)
1. <what matters most based on what they emphasized>
2. <what they mentioned second>
3. <what they implied but didn't say>

## Constraints
<budget, timeline, team size, technical limitations — from context>

## Research Directives
Before each key decision, P0 should:
- Search for real-world validation (demand signals, competitor moves, last 30 days)
- Check if free/open-source tools exist before building custom
- Look for production-verified patterns before inventing new ones
- Flag when there's not enough evidence to decide confidently

## Forcing Question Results

### Demand Reality (Q1)
- **Answer:** <answer or "skipped — not applicable at this stage">
- **Evidence quality:** <strong / moderate / weak / none>
- **Position:** <P0's assessment — is this real demand or wishful thinking?>

### Status Quo (Q2)
- **Answer:** <the specific current workflow users follow>
- **Evidence quality:** <strong / moderate / weak / none>
- **Position:** <is the current pain acute enough to drive switching behavior?>

### Desperate Specificity (Q3)
- **Answer:** <the named person and their consequence>
- **Evidence quality:** <strong / moderate / weak / none>
- **Position:** <is this a real person or a category dressed up as a person?>

### Narrowest Wedge (Q4)
- **Answer:** <the smallest shippable-this-week version>
- **Evidence quality:** <strong / moderate / weak / none>
- **Position:** <is this genuinely small enough, or is it still a platform in disguise?>

### Observation & Surprise (Q5)
- **Answer:** <what happened when a real user tried it without help>
- **Evidence quality:** <strong / moderate / weak / none>
- **Position:** <was this genuine observation or controlled theater?>

### Future-Fit (Q6)
- **Answer:** <the thesis about how the world changes>
- **Evidence quality:** <strong / moderate / weak / none>
- **Position:** <is this a real structural shift or just trend-surfing?>

## Anti-Sycophancy Commitment
This persona takes positions, not hedges. Every recommendation includes:
- A clear stance
- The reasoning behind it
- The specific evidence that would change the stance
```

### 2. Set Session Mode

**If `--interactive` or `--auto` flag is already set:** use it.

**If no flag:** ask the user once:

> How should this session work?
>
> 1. **Interactive** — P0 researches and recommends, you make the calls
> 2. **Auto** — P0 researches and decides, surfaces only high-stakes choices for your approval
>
> Both modes do the same research and analysis. The difference is who decides.

Default if user doesn't respond: `--auto`.

### 3. Set Research Depth

In auto mode, P0 automatically researches before decisions. But how deep?

> Research depth?
>
> 1. **Quick** — check training data + one web search per decision
> 2. **Standard** — web search + competitor scan + trend check (default)
> 3. **Deep** — full market research, 30-day trend analysis, tool landscape scan

Default: `--research standard`.

## Autorun Orchestrator

When `--autorun` is set (or user says "just build it"), workflow-compass
runs the entire lane automatically:

1. **Classify every decision** as:
   - **Mechanical** — clear best answer, decide silently (e.g., file naming)
   - **Taste** — close call, P0 decides but logs it for end-of-run review
   - **User** — high stakes or irreversible, stop and ask even in auto mode

2. **Run skills through the lane**, P0 steering each one.
   **Parallel where independent** — skills with zero data dependencies
   run as concurrent subagents:

   | Parallel group | Skills | Why parallel |
   |----------------|--------|-------------|
   | Market research | `domain-expert` + `competitor-analysis` | Both read vision.md, produce independent outputs |

   Dispatch both via Agent tool in a single message, wait for both to
   complete, then continue to the next sequential skill (`persona-builder`).

   All other skills run sequentially (they consume the previous skill's output).

3. **At end of run**, present all Taste decisions at once:
   > "I made 12 decisions during this run. 9 were mechanical. Here are the 3
   > taste calls I made — review and override any you disagree with."

4. **If any skill blocks** (self-verify fails, investigation escalates, security
   finding), stop and report. Don't silently skip.

5. **Learn from each run** — log operational discoveries to `docs/learnings/`

Decision classification examples:

| Decision | Classification | Why |
|----------|---------------|-----|
| Database column naming | Mechanical | Follow existing conventions |
| REST vs GraphQL for new API | Taste | Both viable, P0 picks based on research |
| Whether to add authentication | User | Scope-changing, irreversible |
| Which CSS framework | Taste | P0 researches, picks, documents |
| Whether to ship or descope a feature | User | Business decision |

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
- `landing-change-set`
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
13. `landing-change-set`
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
9. `landing-change-set`
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
5. `landing-change-set`
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
5. `landing-change-set`
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
| `executing-change-set` | Task execution complete, final diff reviewed | `landing-change-set` |
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
