---
name: explore-solutions
description: >
  Use after design-tech to challenge the chosen approach with
  alternative paradigms and evidence-based comparison. Triggers on "explore
  alternatives", "is this the best approach", "compare options", "solution
  exploration", "challenge the design", or when technical design has
  high-stakes decisions (new data model, new external dependency, hard-to-reverse
  architecture). Runs automatically in progressive mode after tech design.
  Can be skipped when a bootstrap template covers the paradigm.
inputs:
  required:
    - { path: "docs/specs/features/<name>.md", artifact: feature-spec }
  optional:
    - { path: "docs/specs/vision.md", artifact: vision }
    - { path: "docs/specs/personas/P*.md", artifact: personas }
    - { path: "docs/specs/journeys/J*.feature.md", artifact: journeys }
    - { path: "docs/specs/ux/<name>.md", artifact: ux-design }
    - { path: "docs/specs/ui/<name>.md", artifact: ui-design }
    - { path: "docs/specs/domain-profile.md", artifact: domain-profile }
    - { path: "references/bootstraps/*/manifest.md", artifact: bootstrap-template }
outputs:
  produces:
    - { path: "docs/specs/explorations/<name>/DECISION.md", artifact: solution-decision }
chain:
  lanes:
    greenfield: { position: 10, prev: design-tech, next: define-code-style }
    brownfield-feature: { position: 6, prev: design-tech, next: define-code-style }
  progressive: true
  self_verify: true
  human_checkpoint: true
---

# Solution Explorer

Challenge the technical design with alternative paradigms before committing
to implementation. The LLM already picked its best approach in
`design-tech`. This skill contests that choice with research,
alternatives, and evidence — so you commit with confidence, not default.

Derived from petekp/claude-code-setup (MIT, Copyright 2024 Pete Petrash).
Adapted for svc's spec-first pipeline with full upstream context.

**Announce at start:** "I'm using the explore-solutions skill to challenge the technical design with alternatives."

## Why This Exists

LLMs satisfice. When `design-tech` picks an architecture, it
pattern-matches to the most common approach for the stated problem. That's
a local maximum — the most obvious solution is rarely the best across all
dimensions that matter for THIS project, THIS team, THESE constraints.

This skill forces the discipline a senior engineer applies: survey the
landscape before committing. The initial tech design becomes Approach A —
the baseline to beat. Exploration either confirms it (with evidence) or
finds something better.

## When to Skip

**Skip** (auto or manual) when:
- A bootstrap template in `references/bootstraps/` covers the paradigm —
  the paradigm choice is already production-verified
- The feature is a straightforward CRUD extension of existing patterns
- All tech decisions follow established project conventions (no new
  dependencies, no new data model patterns, no new architectural layers)

**Bootstrap template check (automatic):**

Before starting exploration, scan `references/bootstraps/*/manifest.md`:
1. Read each template's Stack section
2. Compare against the tech design's stack choices
3. If a template matches (same runtime + framework + database + API pattern):
   - Load its `decisions.md`
   - Report: "Bootstrap template '<name>' matches. Paradigm decisions are
     production-verified. Skipping exploration."
   - Chain directly to `define-code-style`
4. If no template matches → proceed with exploration

To create templates from real repos: `extract-bootstrap`

**Run** (full or abbreviated) when:
- The tech design introduces a new external dependency
- The data model is new or significantly changed
- The architecture is hard to reverse (new service, new protocol, new storage engine)
- Multiple viable paradigms exist and the right one isn't obvious
- The domain-profile flags domain-specific patterns the LLM may not know

## Calibration

Not every decision deserves the same depth:

| Mode | When | Phases | Output |
|------|------|--------|--------|
| **Full** | Hard-to-reverse, novel, high-stakes | All 5 phases | All artifacts |
| **Abbreviated** | 2-3 viable approaches, analysis alone can decide | Phases 1-3 | PROBLEM_BRIEF + SOLUTION_MAP + ANALYSIS |
| **Quick** | Small feature, sanity-check the obvious choice | Phases 1-2 | PROBLEM_BRIEF + SOLUTION_MAP only |

When in doubt, start full. You can abbreviate once you see the landscape.

## Process

All artifacts go in `docs/specs/explorations/<feature-name>/`.

### Phase 1: Frame the Problem Against Upstream Context

Unlike a standalone exploration, svc has accumulated context. Use it.

**1a. Load everything available:**
- Vision — what product principles constrain this decision?
- Personas — whose needs does this serve? What are their technical constraints (device, connectivity, expertise)?
- Feature spec — what ACs define "done"? What's the consumer type (human/service/external)?
- Journeys — what user flows exercise this feature? What error states matter?
- UX/UI design — what interaction patterns were chosen? What performance expectations?
- Domain profile — what domain conventions exist? What do competitors use?
- The existing tech design (BASELINED) — this is Approach A, the baseline

**1b. Extract success criteria from ACs:**

Every AC becomes a MUST criterion. Don't invent abstract criteria — derive them
from what the spec already defines:

| Source | Becomes |
|--------|---------|
| AC with response time requirement | MUST: performance criterion |
| AC referencing offline/zero-state | MUST: offline/resilience criterion |
| Journey with concurrent users | MUST: scale criterion |
| UI design with animation | SHOULD: interaction smoothness |
| Persona pain point | SHOULD: addresses specific pain |
| Vision principle | NICE: aligns with product direction |

**1c. Surface assumptions from the tech design:**

Read the BASELINED tech design and list every implicit assumption:
- Why this database and not another?
- Why this API pattern and not another?
- Why this component structure?
- What scale is assumed?
- What deployment target is assumed?

Each assumption is a dimension the exploration can challenge.

### Output: PROBLEM_BRIEF.md

```markdown
# Problem Brief: <feature name>

## Problem statement
<restate from spec — what capability is needed, for whom, under what constraints>

## Upstream context
- Vision principles: <relevant ones>
- Persona constraints: <devices, expertise, connectivity>
- Key ACs: <the ones that most constrain the technical approach>
- Journey complexity: <number of flows, error states, concurrent paths>

## Success criteria (derived from ACs)
### Must
<each AC that constrains the approach>
### Should
<quality attributes from design/persona/vision>
### Nice
<differentiators, nice-to-haves>

## Baseline approach (from tech design)
<summary of what design-tech chose and why>

## Assumptions to challenge
1. <assumption from tech design> — why was this chosen?
2. ...

## Constraints
<hard limits: existing stack, team, timeline, budget>
```

---

### Phase 2: Explore Alternative Paradigms

The existing tech design is Approach A. Find at least 2 more paradigms that
make fundamentally different bets.

**What's a paradigm?** Not a different library for the same strategy — a different
strategy entirely. Different bet about what matters most.

**Steps:**

1. **Name the paradigm of the current tech design.** What bet does it make?
   e.g., "Server-rendered with progressive enhancement — bets that simplicity
   and SEO matter more than interactivity."

2. **Find alternative paradigms.** Aim for 3+ total (including the baseline).
   Frame-shifts if stuck:
   - What if the constraint was opposite? (high scale → low scale, real-time → batch)
   - How do competitors in the domain-profile solve this?
   - What existed before the currently popular approach?
   - What would make the hardest AC trivially easy?
   - What's the laziest solution that still meets every MUST?

3. **Research each paradigm.** Use web search, documentation, codebase exploration.
   For each: libraries, patterns, failure modes, who has done this before.

4. **Generate concrete approaches.** 1-3 per paradigm. Each needs:
   - How it works (concrete, not hand-waving)
   - What you gain (specific to this feature's ACs)
   - What you give up
   - Complexity relative to the existing codebase
   - Known risks

**Self-improvement signal:** If the exploration discovers a paradigm that is strictly better than the baseline AND the baseline was chosen by the LLM's default pattern-matching, log this as an EUREKA learning:

```json
{"skill": "solution-explorer", "type": "pattern", "key": "eureka-<topic>", "insight": "LLM default was <X> but <Y> is better because <evidence>. The default pattern-match failed because <why>.", "confidence": 8, "source": "observed", "saves_minutes": 60}
```

These EUREKA learnings are the highest-value entries in the learning system — they represent cases where the LLM's training data was wrong for this specific context.

5. **Hunt for the non-obvious.** After initial exploration:
   - Can the problem be reframed to make it trivial?
   - Is there a hybrid combining strengths of multiple paradigms?
   - Is there a managed service that eliminates the problem?
   - What would someone from a different domain do?

### Output: SOLUTION_MAP.md

```markdown
# Solution Map: <feature name>

## Paradigm A: <name> (BASELINE — from tech design)
**Core bet:** <what this paradigm assumes matters most>
### Approach A1: <current tech design>
- **How it works:** <from the BASELINED tech design>
- **Gains:** <why design-tech chose this>
- **Gives up:** <what was traded away>
- **Complexity:** <relative to codebase>

## Paradigm B: <name>
**Core bet:** <different bet>
### Approach B1: <name>
...

## Paradigm C: <name>
**Core bet:** <different bet>
### Approach C1: <name>
...

## Non-obvious options
<creative, unconventional, or hybrid approaches>

## Eliminated early
<approaches considered but dismissed, with reasoning>
```

### Minimum Exploration Gate

Do not proceed to Phase 3 until:
- At least 3 distinct paradigms (including baseline) with substantive analysis
- At least 5 total approaches across paradigms
- Research conducted (not just training-data brainstorming)
- Non-obvious section genuinely attempted

If the baseline seems "obviously best" — that's the satisficing instinct this
skill exists to counter. Document why it seems obvious, then keep exploring.

---

### Phase 3: Analyze Against ACs

Evaluate all approaches against the success criteria from Phase 1.

**Steps:**

1. **Tradeoff matrix.** Compare ALL approaches against each criterion.
   Use concrete assessments ("~200ms p95" not "good performance").

2. **Eliminate on MUST failures.** Which approaches fail an AC-derived MUST?
   Remove with documented reasoning.

3. **Rank survivors.** For SHOULD and NICE criteria, compare performance.

4. **Select 2-3 finalists.** Must be from different paradigms.

5. **Name the key differentiator.** What single question, if answered, would
   make the choice clear? This is what Phase 4 prototyping targets.

### Output: ANALYSIS.md

```markdown
# Analysis: <feature name>

## Tradeoff Matrix

| Criterion (source) | Approach A1 | Approach B1 | Approach C1 |
|---------------------|------------|------------|------------|
| MUST: AC-01 ... | ✅ detail | ✅ detail | ❌ why |
| MUST: AC-02 ... | ✅ | ⚠️ risk | ✅ |
| SHOULD: ... | detail | detail | detail |

## Eliminated
- <Approach X>: fails MUST AC-<N> because <evidence>

## Finalists
1. **A1** (baseline) — from Paradigm A. Because...
2. **B1** — from Paradigm B. Because...

## Key differentiator
<what prototyping needs to answer>

## Runner-up value
If only 2 strong finalists exist, the runner-up is still documented
with full reasoning. A confirmed baseline with a documented "why not
the alternative" is a valid and valuable outcome.
```

---

### Phase 4: Prototype Finalists (Full mode only)

Build minimal prototypes to answer the key differentiator. Skip if
abbreviated/quick mode or if Phase 3 analysis is decisive.

Each prototype: 50-200 lines testing the key differentiator only.
Put in `docs/specs/explorations/<feature-name>/prototypes/`.

Define comparison criteria BEFORE writing code. Run comparison.
Record concrete numbers, not vibes.

### Output: COMPARISON.md

---

### Phase 5: Decide

**If the baseline wins:** The exploration confirms the tech design with evidence.
Document why alternatives were rejected with specific AC-traced reasoning.
The tech design stands — no changes needed.

**If an alternative wins:** Revise the tech design. Update the BASELINED feature
spec's Implementation Notes section with the new approach. The feasibility
matrix and component table change.

**Either way:** Produce DECISION.md.

### Output: DECISION.md

```markdown
# Decision: <feature name>

## Selected approach
**<name>** — <one-line description>

## Confidence
<high (prototyped + researched) / medium (researched + analyzed) / low (analyzed only)>

## Evidence chain
- Problem framing: PROBLEM_BRIEF.md
- Alternatives explored: SOLUTION_MAP.md (N paradigms, M approaches)
- Analysis: ANALYSIS.md (tradeoff matrix against ACs)
- Prototyping: COMPARISON.md (if done)

## Why this approach
<reference specific ACs it satisfies better than alternatives>

## Why not the alternatives
- **<Alt B>**: <specific AC or criterion it fails/underperforms, with evidence>
- **<Alt C>**: <specific reason>

## Runner-up
**<name>** — would be the choice if <condition changes>.
Preserved as a documented fallback.

## Impact on tech design
- [ ] No changes needed (baseline confirmed)
- [ ] Tech design revised — see updated Implementation Notes in feature spec
```

---

## Session Protocol

Exploration may span multiple sessions.

**Starting:** Check `docs/specs/explorations/<name>/` for existing artifacts. Resume from last phase.

**Pausing:** Write HANDOFF.md with current phase, completed work, next steps, open questions.

## Audit Mode

When invoked with `--audit` on an existing exploration:

1. Read DECISION.md
2. Check: has the codebase evolved to invalidate the decision?
3. Check: are the MUST criteria still the same (ACs may have changed)?
4. Check: have new paradigms/tools emerged that weren't available?
5. Report: VALID / STALE / REVISIT-RECOMMENDED

## Pipeline Continuation

### Self-Verify

| # | Check | How | PASS/FAIL |
|---|-------|-----|-----------|
| 1 | DECISION.md exists | `test -f docs/specs/explorations/<name>/DECISION.md` | |
| 2 | At least 3 paradigms explored | grep paradigm count in SOLUTION_MAP.md | |
| 3 | Tradeoff matrix references ACs | ANALYSIS.md contains AC identifiers from spec | |
| 4 | Runner-up documented | DECISION.md has "Why not" section | |

### Chaining

**If `--progressive` flag is present AND self-verify passed:**
- If tech design was revised: update the feature spec status (stays BASELINED)
- Invoke next skill: `define-code-style --progressive --lane <lane>`

**If `--progressive` flag is absent:**
- Report decision summary
- Suggest: "Next: run `define-code-style`"
