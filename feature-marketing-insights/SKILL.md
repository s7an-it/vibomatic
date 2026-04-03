---
name: feature-marketing-insights
description: >-
  Build and maintain the product marketing context through systematic feature mining.
  Use when the user says "mine features", "extract marketing value", "update marketing context",
  "what should we market?", "refresh marketing insights", "feature mining", "set up context",
  "marketing context", "positioning", "find our strongest marketing angles",
  "what features should we highlight", "marketing ammunition", "what's worth marketing",
  "feature value", "marketing potential", or wants to identify which features have the strongest
  marketing potential. Also use when the user asks to run quality evaluation on existing insights,
  find feature combinations, compact the marketing context document, or validate messaging
  against buyer personas. Also use when the user says "persona validation", "does our messaging
  work", "stress test the copy", "buyer perspective", or "who are we actually talking to".
  Replaces product-marketing-context skill.
inputs:
  required:
    - { path: "docs/specs/features/*.md", artifact: feature-specs }
  optional:
    - { path: ".agents/product-marketing-context.md", artifact: existing-context }
outputs:
  produces:
    - { path: ".agents/product-marketing-context.md", artifact: marketing-context }
chain:
  lanes: {}
  progressive: false
  self_verify: true
  human_checkpoint: false
---

# Feature Marketing Insights

## Purpose

Build the product marketing context from the ground up by systematically mining ExampleProduct feature specs. Produces weighted, validated, bloat-free marketing ammunition — not engineering descriptions.

This skill owns the entire marketing context document (`docs/marketing/product-marketing-context.md`):
- **Foundation** (sections 1-12): Product overview, audience, pain points, competitors, voice, proof points
- **Layer 1 (atomic insights)**: Individual feature traits with full metadata — one trait, one claim, one weight
- **Layer 2 (narratives)**: Cross-feature combinations that reference Layer 1 by ID

**Core principle:** Marketer brain, not engineer brain. "7-dimension matching algorithm" is engineering. "Find a co-builder who matches your AI tools, timezone, and shipping speed" is marketing.

## Repository Mode Gate

Detect mode from `REPO_MODES.md` before running mining modes.

- `bootstrap`: initialize marketing context/tracker files from available specs and baseline docs.
- `convert`: map existing marketing docs/context into tracker format first, then mine incrementally.

## External Transformer Interop (coreyhaines-compatible)

This skill is the first producer for `.agents/product-marketing-context.md` in vibomatic.

Contract:
- Keep `.agents/product-marketing-context.md` as canonical shared path.
- Run `feature-marketing-insights` first to produce tracker-backed insights and foundation sync.
- If coreyhaines `product-marketing-context` runs, it must start from the existing file and transform/adapt it rather than replacing vibomatic insight payload.
- Preserve compatibility mirror behavior for `.claude/product-marketing-context.md` only as optional bridge.

## Critical Design: Iterative Batches

**This skill processes 3-4 features per conversation, NOT all at once.**

The tracker (`docs/marketing/feature-mining-tracker.json`) is the persistent state between sessions. Each invocation:
1. Reads the tracker to see what's already mined
2. Picks the next 3-4 unmined or stale features
3. Mines them, writes results to tracker + context doc
4. Outputs a **follow-up prompt** the user can paste to continue in a new conversation

This prevents context window exhaustion and keeps each session focused.

---

## Operating Modes

### Mode 1: Full Scan (Iterative)

Mine all features across multiple conversations. Each session handles 3-4 features.

**First invocation:** Start with highest-value unmined features.
**Subsequent invocations:** User pastes the follow-up prompt -> skill picks up where it left off.

### Mode 2: Single Feature

Mine one named feature. Fits in a single conversation.

### Mode 3: Refresh

1. Read tracker -> check `last_mined` dates
2. Compare against spec file modification times (use `stat` or `ls -l`)
3. Only re-mine specs modified since `last_mined`
4. If nothing changed, report "All features current" and stop
5. **Weight-correction pass:** For each re-mined feature, scan existing insights for `"status": "pending_validation"` or `"weight_note"` containing "Planned feature". Check the spec's Implementation Notes using spec-code-sync status model:
   - `RESOLVED` / `FIXED`: treat as live. Remove planned-feature penalty, recalculate weight, update status, clear `weight_note`.
   - `UPDATED`: treat as live only if behavior is verified equivalent at the new reference; then remove penalty and refresh provenance.
   - `DRIFT` / `REVERTED`: do not treat as live. Keep penalty or mark affected insight `deprecated`/`pending_validation` and flag in output.
6. **Foundation consistency check:** After correcting any insight's key facts, scan the context doc's foundational sections for occurrences of the old value. Flag mismatches in "Suggested Foundation Updates" with exact location and old -> new value. Do NOT auto-edit foundational sections.
7. **Status alignment gate (required):** Before finishing Refresh, fail the run if either:
   - an insight still has planned penalties while source evidence is qualifying live status (`RESOLVED`/`FIXED`, or verified `UPDATED`)
   - an insight is still marketed as live while latest status is `DRIFT` or `REVERTED`
   Report exact insight IDs that need correction.

### Mode 4: Foundation

Initialize or update the foundational sections (1-12) of the context doc.

**Auto-draft from codebase** (new projects): Read README, landing pages, specs, package.json. Draft foundational sections. User reviews and corrects.

**Incremental update** (during mining): When mining reveals new evidence for a foundational section, add to "Suggested Foundation Updates" list. Present at end of session for user approval. Never auto-edit foundational sections.

**Foundational sections** (from marketing framework):

| # | Section | What to capture |
|---|---------|----------------|
| 1 | Product Overview | One-liner, what it does, category, type, business model |
| 2 | Target Audience | Who, primary use case, jobs to be done |
| 3 | Core Problem | What breaks, why alternatives fail, cost of inaction |
| 4 | Switching Dynamics | Push (frustrations), Pull (attraction), Habit (inertia), Anxiety (risk) |
| 5 | Competitive Landscape | Direct, secondary, indirect competitors + why they fall short |
| 6 | Differentiators | Capabilities alternatives lack, why better |
| 7 | Objections & Anti-Personas | Top objections + who is NOT a fit |
| 8 | Customer Language | Verbatim phrases, words to use/avoid, glossary |
| 9 | Brand Voice | Tone, style, personality |
| 10 | Proof Points | Stats, testimonials, value themes |
| 11 | Quick Stats Reference | Citable numbers for copy |
| 12 | Goals | Business goal, conversion action, current metrics |

### Mode 5: Compact

Remove low-weight insights from the context doc to bring it back under the 500-line threshold. The tracker is never modified — all insights remain there.

**When to run:** Context doc exceeds 500 lines, or user explicitly requests compaction.

**Steps:**
1. Read context doc, count total lines
2. Identify compaction candidates: insights with `weight < 55`, legacy pre-structured content that duplicates tracker data
3. Remove candidates from context doc (NOT from tracker — tracker is the source of truth)
4. Update section header date
5. Report: lines before, lines after, insights now tracker-only

**Never compact:** weight >= 55 insights, foundational sections (1-12), narratives, any content added in the last 7 days.

### Mode 6: Capability Combinations

Cross-feature combination reasoning. Read `references/capability-combinations.md` for the full process and ExampleProduct-specific combination patterns to test.

**When to run:** After a full scan completes, user asks for combination reasoning, or a new high-value feature is added.

### Mode 7: Quality Eval

Systematic evaluation pass across all mined content. Read `references/quality-eval.md` for the 10 eval criteria and output format.

**When to run:** After Mode 6 completes, when insights feel generic, or after major spec changes. Do NOT run during active mining.

### Mode 8: Persona Validation

Construct virtual buyer personas from mined data and have them interrogate the marketing context. Read `references/persona-validation.md` for the full process.

This is NOT a generic interview. Every persona is built from actual audience segments, pain points, and insights already extracted. The personas then "read" our marketing at three touchpoints (first encounter, evaluation, decision) and surface gaps, wrong-voice issues, and missing objection handling.

**When to run:** After 8+ features are mined AND Mode 4 (Foundation) has been run. Run when you want to validate that the marketing context actually speaks to real buyers, not just documents features.

**Output:** Per-persona coverage scorecards + unified gap list with prioritized actions (new mining needed, copy rewrites, foundation updates).

---

## Pre-Flight (Every Invocation)

```
1. Read tracker -> docs/marketing/feature-mining-tracker.json
   - If missing: create empty scaffold, proceed as first Full Scan
   - If exists: extract last_mined dates for all features

2. Schema validation pass:
   - For each feature in the upcoming batch, check every insight against
     references/output-schema.md required fields
   - Fix field name errors (e.g., "audience" -> "audience_segment",
     "status: live" -> "status: active")
   - Log fixes in mining_notes, apply before mining starts

3. Determine work queue:
   - Full Scan: features sorted by priority, filter to unmined or stale
   - Refresh: features where spec file mtime > last_mined
   - Single: just the named feature

4. Comprehensively-mined check (early exit):
   - A feature is "comprehensively mined" if ALL of:
     (a) 4+ active insights exist
     (b) Top insight weight >= 70
     (c) Spec file NOT modified since last_mined
     (d) No insights have status "pending_validation"
   - For comprehensively-mined features: report "Feature X: comprehensively
     mined, skipping" and move to next feature. Do NOT re-read the full spec,
     do NOT run web research, do NOT re-evaluate. Just validate schema (step 2)
     and move on.
   - Exception: user explicitly requests re-mine ("re-mine feature-matching")

5. Pick next 3-4 from work queue (NEVER more than 4)

6. Load existing insights for deduplication:
   - Read insights arrays for ALL features in the upcoming batch from the tracker
   - These are your semantic dedup reference

7. Read foundational sections (skim, not deep-read):
   - Target audience, voice, competitive landscape — these inform how you write insights
   - **Quick Stats Reference** — load into working memory now for stat amplification in Step 2
   - Note any gaps you spot for the "Suggested Foundation Updates" output
```

**Priority order** (process highest marketing value first):

| Priority | Features | Rationale |
|----------|----------|-----------|
| 1 (highest) | feature-matching, feature-conversation, feature-trust | Core differentiators |
| 2 | profiles, feature-collab, monetization | Strong user-facing value |
| 3 | discovery, referrals, feature-onboarding, teams | Growth and engagement |
| 4 (lowest) | gamification, feature-learning, feature-workspace, feature-experts, feature-privacy, feature-beta-program | Supporting/planned features |

---

## Per-Feature Mining Loop (7 Steps)

### Step 1: Extract Raw Material

Read the spec file at `docs/specs/features/<name>.md`.

**Read only the first 100 lines initially.** This covers Problem Statement, Solution Overview, and Success Criteria. Deep-read the full spec ONLY if preliminary analysis suggests weight >= 60.

Extract:
- **Problem statement** — What breaks without this feature?
- **Solution mechanism** — How does it work? (for understanding, not output)
- **Metrics / numbers** — Any quantified claims
- **Live vs Planned** — Check spec status field AND `docs/specs/INDEX.md`. For planned sub-features, scan Implementation Notes for spec-code-sync annotations (`RESOLVED`, `FIXED`, `UPDATED`, `DRIFT`, `REVERTED`) — these override raw spec status when newer.

### Step 2: Evaluate and Deepen

Use `references/evaluation-framework.md` as thinking scaffolding (internalize the 6 categories after first read). Identify the 1-5 strongest marketing angles with preliminary weight estimates.

Then apply these two deepening passes:

**Stat amplification:** Scan the Quick Stats Reference and Proof Points for numbers that directly amplify any mechanism you identified. "Direct amplification" means the stat is the quantitative backbone of the mechanism — making the claim statistically provable. When you find one: mark the angle `validated: true`, incorporate the stat directly into the insight copy (don't keep them separate), and skip web research for that angle. What is NOT stat amplification: a stat that is merely adjacent but doesn't prove the specific claim.

**Unlock reasoning:** Features don't just *do* things — they *unlock* things. For every mechanism, ask:
1. **What can the user NOW DO that they couldn't before?** (direct unlock)
2. **What behavior does this feature encourage over time?** (enabled behavior)
3. **What compounds with repeated use across sessions?** (compound outcome)

The unlock chain often produces the highest-weight insights because it reveals paradigm shifts. When unlock reasoning reveals a cross-feature benefit, flag it for Step 7 (Layer 2 narrative) instead of forcing it into a single-feature insight.

**Unlock patterns to watch for:**
- Feature that **rewards repeated use** -> compound growth narrative
- Feature that **removes a cost** -> freed capacity narrative
- Feature that **changes what's possible at scale** -> power user vs casual user split
- Feature that **combines with another** -> flag for Step 7, not a single-feature insight

### Step 3: Web Research Validation

**Required for insights with preliminary weight >= 70. Max 3 searches per feature.**

Use specific search templates:
- `"[competitor] co-founder matching [feature keyword] pricing"`
- `"YC co-founder matching [feature]"`
- `"[pain point] statistics [year]"`

**Skip web research** for insights weighted < 70.

### Step 4: Generate Insights (1-5 per feature, hard cap)

**Before drafting, enumerate user roles for this feature:** List every distinct user type that interacts with it (idea-owner, technical builder, new user, serial founder, team lead). For each role, write one sentence from THAT ROLE'S first-person perspective: "As [role], what I get from this is: ___". If any role-specific sentence is MORE concrete than the feature-level description, that sentence is the insight.

Each insight MUST pass these four checks — any FLAG means revise before proceeding:

| # | Check | Pass | Flag |
|---|-------|------|------|
| 1 | **User-centric language** | Every sentence from user POV; no "we built", no feature names as subjects | Contains "we", "the system", implementation nouns as subjects |
| 2 | **Specific claim** | Contains a concrete fact, number, mechanism, or testable outcome | Only vague praise ("better", "easier") with nothing to grab onto |
| 3 | **Differentiated** | A competitor could NOT copy this claim truthfully today | Any platform could say the same thing |
| 4 | **Unlock reasoning applied** | The "what does this enable next?" question was asked; answer is woven in or routed to Step 7 | Insight describes a static capability with no downstream thinking |

If 3+ checks FLAG: discard and generate a replacement. If 1-2 FLAG: revise inline.

**Deduplication:** Before writing each insight, compare semantically against existing insights from Pre-Flight step 4. "Credits on mutual accept" and "you only pay when both sides say yes" = same concept, skip.

| Bad (engineering) | Good (marketing) |
|-------------------|-----------------|
| "Cosine similarity across 7 vectors" | "Matched on the 7 things that predict co-builder success" |
| "Majority vote consensus CEIL(N/2)" | "Your team decides together — no single person can override" |
| "OCC conflict resolution" | "Two people editing at once? Changes merge automatically" |
| "Rate-limited Edge Function" | *(Don't market this at all)* |
| "Queue intent type matching" | "You're not 'a user' — you're an idea-owner looking for execution, or a builder looking for a worthy project" |

### Step 5: Assign Final Weights

Use `references/weight-calibration.md` anchors (internalize after first read).

1. Start with base score from evaluation
2. Apply modifiers: +10 unique, +5 stat backup, -10 competitors have
3. **Planned feature penalty** (tiered, not flat):
   - Homepage/social: -15
   - Blog/email: -5
   - Roadmap/pitch: 0
4. Compare against anchors, clamp 1-100

### Step 6: Record Results

**Write to tracker immediately** after each feature (not at end of batch). If the conversation ends mid-batch, progress is preserved.

Update `docs/marketing/feature-mining-tracker.json`:
- Merge new insights (never delete existing)
- Initialize `deployed_in: []` on every new insight
- Update `last_mined` timestamp
- Recompute summary stats by counting actual array lengths — do NOT increment stored counters

Append to `docs/marketing/product-marketing-context.md`:
- Only insights with weight >= 55 (aligns with Mode 5 compaction threshold)
- Use HTML comment format: `<!-- weight:85 source:feature-matching validated:true -->`
- Organize by **weight tier** (Category-Defining / Strong Differentiators / Meaningful Value)
- Mark planned features with "(Coming soon)"
- **Each insight is atomic** — one trait, one claim, one audience, one weight. Never merge.

### Step 7: Cross-Feature Synthesis (after batch completes)

After all features in the batch are mined, look across the batch for **narrative combinations** — marketing stories powered by multiple features together.

**Rules:**
- Generate 0-3 narratives per batch (don't force it)
- Each narrative MUST back-reference the atomic insight IDs it draws from
- Initialize `deployed_in: []` on every new narrative
- Narratives go in a separate `"narratives"` array in the tracker
- Narratives go in a separate "## Synthesized Narratives" section in the context doc
- **Narratives never replace their source insights.**
- **Overlap detection:** After creating a narrative, check if any source insight is fully subsumed (the narrative says everything the insight says, plus more). If so, mark the insight `"status": "elevated_to_narrative"` with `"elevated_to": "<narrative-id>"`. Elevated insights stay in the tracker but are removed from the context doc — the narrative carries their value now. This prevents the context doc from saying the same thing twice at different abstraction levels.

---

## End-of-Session Output

After processing the batch, do FOUR things:

### 1. Batch Summary Table

```markdown
## Mining Batch — [date]

| Feature | Insights | Top Insight (weight) | Validated |
|---------|----------|----------------------|-----------|
| feature-a | 3 | "Insight text" (85) | Yes |
| feature-b | 2 | "Insight text" (62) | No |

**Narratives generated:** N (list IDs if any)
**Progress:** X/16 features mined
**High-value insights this batch:** N (weight >= 70)
```

### 2. Suggested Foundation Updates

If mining revealed new evidence for foundational sections, list them. If nothing new was found, output "No foundation updates needed."

### 3. Sync Consumer Context File

Update `.agents/product-marketing-context.md` — this is feature-marketing-insights' own consumer file that downstream internal skills read automatically. It must stay in sync with the full context doc.

**Format:** The 12-section structure that downstream skills expect (Product Overview, Target Audience, Problems & Pain Points, Switching Dynamics, Competitive Landscape, Differentiation, Objections, Customer Language, Brand Voice, Proof Points, Goals). Plus a "Top Marketing Insights" appendix with weight >= 70 insights and top narratives.

**How to sync:** Read `docs/marketing/product-marketing-context.md` and extract/condense into the 12-section format. Include a header noting "Auto-synced by feature-marketing-insights skill" and the source path. The downstream skills don't need the full 352-line doc — they need the foundational positioning sections + the strongest insights as ammunition.

**If external transform runs after this skill:** External passes may adapt wording/structure, but they must start from this file and preserve/refresh vibomatic "Top Marketing Insights" from tracker-backed mining.

**When to sync:** After every mining session (Modes 1-3) and after Mode 4 (Foundation updates). Skip sync for Modes 5-7 (compaction, combinations, eval don't change the foundation).

**Compatibility bridge (optional, external add-ons only):**
- Canonical consumer file remains `.agents/product-marketing-context.md`.
- If an external skill explicitly requires `.claude/product-marketing-context.md`,
  mirror the canonical file after sync:
  `mkdir -p .claude && cp .agents/product-marketing-context.md .claude/product-marketing-context.md`
- Never treat `.claude/product-marketing-context.md` as canonical in vibomatic.

### 4. Follow-Up Prompt

Generate a compact prompt the user can paste to continue:

```
[Mode X] feature-marketing-insights — continue batch N.
Mode: [Full Scan | Refresh | Single Feature]
Remaining: [list of unmined/stale feature keys, or "none"].
Last processed: [feature-key] on [date].
Tracker: docs/marketing/feature-mining-tracker.json.
[Any special context]
```

If all features are mined:
```
All features mined and current. Run Mode 6 to check for new combination narratives, or Mode 7 to eval quality. Tracker: docs/marketing/feature-mining-tracker.json.
```

---

## Key Rules

### Iterative, Not Monolithic

- **3-4 features per conversation.** Never more than 4. Context quality degrades past that. **Exception:** If the user provides an explicit pre-planned batch sequence and requests the full session, execute the complete plan — but stop early if insights become generic.
- **Tracker is persistent state.** Write after every feature, not at end of batch.
- **Follow-up prompt enables continuation.** User shouldn't need to remember what was done.
- **Skip already-mined features** in Full Scan if mined within 7 days and spec unchanged.

### Marketer Brain, Not Engineer Brain

Translate mechanisms to outcomes. If you catch yourself writing implementation details, stop and rewrite from the user's perspective.

### Live vs Planned Guardrail

- **Live features**: Market freely, present tense
- **Planned features**: Tiered penalty (see Step 5). Always mark "(Coming soon)" in context doc.
- Check spec status in `docs/specs/INDEX.md`, then reconcile with Implementation Notes status annotations (`RESOLVED`/`FIXED`/verified `UPDATED` => live, `DRIFT`/`REVERTED` => not live)

### Atomic Insights Are Sacred

- **Layer 1 (atomic):** One trait, one claim, full metadata. NEVER merge, summarize, or consolidate.
- **Layer 2 (narratives):** Cross-feature combinations referencing Layer 1 by ID. Additive only.

When you "consolidate" atomic insights, you lose the specific evidence, audience, and weight that made each one useful. Synthesis is a view on top of the data, not a replacement.

### Incremental, Not Destructive

- Never rewrite the marketing context doc from scratch
- Never delete insights (mark `"status": "deprecated"` if outdated, or `"superseded"` if replaced)
- Never reorder existing content or merge atomic insights
- Never auto-edit foundational sections — suggest updates, let user approve
- **Copy refinement exception:** You MAY update an insight's `insight` text to weave in a stat or sharpen wording — this is NOT merging or deleting. Preserve the ID, weight, audience_segment, and all metadata. Set `"updated"` to the current timestamp. Use this when stat amplification (Step 2) finds a number that directly strengthens an existing insight.

### Bloat Prevention

- **Per-session cap: 5 new insights per feature per mining session.** This prevents flooding.
- Features CAN accumulate more than 5 total insights across multiple sessions — that's fine. Accumulated coverage reflects genuine depth.
- When a new insight covers the same ground as an existing one but is sharper, mark the old one `"status": "superseded"` with `"superseded_by": "<new-id>"` in the tracker. Superseded insights are excluded from summary stats and the context doc, but remain in the tracker for audit.
- "No strong marketing angle" is valid — record with weight < 30, don't force content
- Don't add to context doc if weight < 55 (tracker only)

### Context File Quality Check

After completing a Full Scan (all 16 features), evaluate the context doc:
- Flag if total lines exceed 500 (suggest compaction)
- Flag duplicated concepts appearing in 3+ sections
- Flag engineering language that slipped through
- Rate the doc 1-10 with specific improvement actions

---

## Integration with Other Skills

| Consumer | Filter |
|----------|--------|
| **Twitter/social skills** | `weight >= 70` + `use_in` includes `"social"` + check `deployed_in` to avoid repeats |
| **Blog/content skills** | `weight >= 70` + no existing blog coverage = content gap |
| **Launch strategy** | Sort by weight descending for pitch prioritization |
| **Downstream content skills** | Append to `deployed_in` when consuming an insight |

---

## Error Handling

- **Spec file missing:** Log `"spec_missing"` in tracker, skip, include in follow-up prompt
- **Web search fails:** Proceed without, mark `"competitor_validated": false`
- **Insight already exists:** Skip silently, do not duplicate
- **Tracker corrupted:** Backup to `.bak`, create fresh tracker, warn user
- **Context doc over 500 lines:** Warn user, suggest running compaction pass
- **Context doc missing:** Scaffold foundational sections (Mode 4), then proceed

---

## Quick Reference: Feature Spec Paths

All specs live at `docs/specs/features/`:

| # | Spec File | Feature |
|---|-----------|---------|
| 1 | `feature-matching.md` | 7D Matching System |
| 2 | `feature-conversation.md` | Conversation Modes |
| 3 | `feature-onboarding.md` | Onboarding & Auth |
| 4 | `profiles.md` | Profile System |
| 5 | `feature-collab.md` | Chat & Collaboration |
| 6 | `feature-trust.md` | Trust & Reputation |
| 7 | `teams.md` | Team Features |
| 8 | `feature-workspace.md` | Vision Canvas |
| 9 | `gamification.md` | Gamification |
| 10 | `referrals.md` | Referrals & Growth |
| 11 | `monetization.md` | Monetization |
| 12 | `discovery.md` | Discovery & Browse |
| 13 | `feature-learning.md` | Learning Hub |
| 14 | `feature-experts.md` | Expert & Investor |
| 15 | `feature-privacy.md` | Settings & Privacy |
| 16 | `feature-beta-program.md` | Beta Program |

## Pipeline Continuation

### Self-Verify

Before declaring done, verify:

| # | Check | How | PASS/FAIL |
|---|-------|-----|-----------|
| 1 | Marketing context file exists | `test -f .agents/product-marketing-context.md` | |
| 2 | Has weighted insights | grep for `weight:` HTML comments in context file | |
| 3 | Feature specs mined | Tracker JSON has entries with `last_mined` dates | |

If any check FAILs, fix before continuing. If a fix requires upstream changes, stop and report.

### Chaining

**If `--progressive` flag is absent:**
- Report results to user
- Suggest: "Next: consider running Mode 6 (Capability Combinations) or Mode 7 (Quality Eval)"

Not part of progressive chains (parallel track).
