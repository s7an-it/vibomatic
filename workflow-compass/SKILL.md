---
name: workflow-compass
description: >
  Know which product development skill to use next based on what exists in the project
  and what was just done. Maps the 9 core skills (vision-sync, persona-builder, journey-sync,
  journey-qa-ac-testing, feature-discovery, spec-ac-sync, spec-code-sync,
  agentic-e2e-playwright, feature-marketing-insights),
  their relationships, inputs, outputs, and handoff points. Use when: "what should I do next",
  "which skill do I run", "what's the right order", "product workflow", "skill map",
  "where do I start", "what comes after journey-sync", "I just ran spec-ac-sync now what",
  or when the user seems unsure which product skill to invoke. Also use when a skill
  just finished and produced findings that need routing to another skill.
---

# Workflow Compass

You have 9 core product development skills. Each one produces artifacts that other
skills consume. Running them in the wrong order wastes work — running them in the
right order compounds value. This skill knows the graph.

---

## Repository Mode Gate

Before recommending any next skill, detect repository mode using `REPO_MODES.md`:

- `bootstrap`: initialize missing spec workflow structure first, then route.
- `convert`: adapt to existing repo structure/process first, then route.

If mode is ambiguous, default to `convert` (preserve existing patterns).

---

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
- `agentic-e2e-playwright`
- `feature-marketing-insights`

### External Add-On Packs (optional)

Only route to external skills when explicitly installed/confirmed.

- **coreyhaines-marketing-pack (optional):**
  `product-marketing-context`, `customer-research`, `market-competitors`, `competitor-alternatives`,
  `copywriting`, `page-cro`, `launch-strategy`, `market-social`,
  `market-ads`, `market-emails`, `signup-flow-cro`, `onboarding-cro`

- **planning add-on (optional):**
  `writing-plans` (or repo-equivalent implementation planning skill)

If an external skill is not confirmed, provide a core-pack fallback route.
External pack definitions live in `EXTERNAL_ADDONS.md`.

---

## The 9 Skills

### 1. vision-sync
**What it does:** Creates, refines, or converts product vision docs using proposal-first, evidence-backed workflow aligned with Vibomatic mode gates.

**Produces:** `docs/specs/vision.md` proposals (or applied canonical updates), evidence table, open questions, approval gate.

**Consumes:** Runtime/code reality, status docs (`README.md`, `IMPLEMENTATION_STATUS.md`), specs/legacy vision files.

**2 modes:** Grounded (evidence-backed) and Scratch (assumption-tagged).

**Key detail:** Vision-only scope. Uses canonical target `docs/specs/vision.md`, defaults to proposal-first, and prefers convert over delete to preserve meaning.

---

### 2. persona-builder
**What it does:** Defines WHO the users are — archetypes, patience budgets, trust triggers, lifecycle progression.

**Produces:** `docs/specs/personas/P*.md`, `PERSONA_INDEX.md`, optionally `TIER2_BACKLOG.md`, `SKILL_AUDIT.md`

**Consumes:** Vision doc, feature specs, challenge library (`docs/personas/`)

**7 modes:** Build all, Skill audit, Add one, Expand one, Interview, Discover gaps, Tiered auto-discovery

**Key detail:** Each persona file has a `Skill Implications` section with specific guidance for journey-sync and downstream messaging/CRO skills (often external add-ons like copywriting/page-cro/onboarding-cro). The `Lifecycle Progression` section (Instance 1/2/3) is essentially a proto-journey map.

---

### 3. journey-sync
**What it does:** Defines HOW users move through the product — multi-feature BDD flows with Gherkin scenarios, AC traceability, and three-layer analysis.

**Produces:** `docs/specs/journeys/J*.feature.md`, `JOURNEY_INDEX.md`

**Consumes:** Feature specs, persona files (reads `Skill Implications > journey-sync`), existing E2E tests, existing journeys

**6 modes:** Bootstrap, Expand, Refresh, Migrate legacy, Auto (full sync), Tiered auto-discovery

**Key detail:** Layer 3 analysis finds problems invisible to individual specs — contradictions, dead ends, persona mismatches, ungrounded preconditions (supply-side gaps), concept fragmentation. Layer 3 findings route to other skills (feature-discovery, implementation planning, persona-builder, spec-ac-sync).

**Cross-journey dependency graph:** Phase 4 traces every Background precondition back to its producing role, checks if a producer journey exists, if the UI exists, and if validation is intact.

---

### 4. journey-qa-ac-testing
**What it does:** Runs journey-first manual/agentic QA against any target runtime URL (local, preview, staging, prod), validates mapped ACs, captures evidence, and writes QA status back to feature specs.

**Produces:** Updated QA columns in AC tables, evidence screenshots under `docs/specs/features/test-evidence/`, run summary.

**Consumes:** Journey docs, feature AC tables, target environment URL.

**4 modes:** Smoke, Regression, Feature-AC, Exploratory.

**Key detail:** Complements (not replaces) E2E automation. This is runtime verification before/alongside automated test authoring.

---

### 5. feature-discovery
**What it does:** Validates feature ideas BEFORE design — cross-references against personas, journeys, specs, and code. Produces a Feature Ship Brief or diagnoses an existing problem (concept fragmentation, pipeline break).

**Produces:** `docs/specs/features/YYYY-MM-DD-<name>-brief.md`

**Consumes:** Journeys (Tier 1 — checked first), personas (Tier 1), feature specs (Tier 2 — only when pointed there), codebase (Tier 3 — verify reality)

**Key detail:** Identifies industry patterns (flash deals, referrals, bookings, loyalty, etc.) and checks all three sides: producer, consumer, system. Catches concept fragmentation — two components with different names creating the same entity. Routes to the right downstream skill based on findings.

---

### 6. spec-ac-sync
**What it does:** Ensures every User Story in a feature spec has complete, testable acceptance criteria. Rewrites vague ACs, writes missing ones.

**Produces:** Updated AC tables in `docs/specs/features/*.md` (in-place edits)

**Consumes:** Feature spec files

**Key detail:** The AC table format (`| AC | Description | QA | E2E | Test |`) is the shared contract across 4 skills. spec-ac-sync owns the Description column. journey-qa-ac-testing owns QA. agentic-e2e-playwright owns E2E + Test. spec-code-sync reads the table for drift checking.

---

### 7. spec-code-sync
**What it does:** Audits specs against actual code — finds where PLANNED items are now implemented, where RESOLVED references are stale, where code contradicts the spec.

**Produces:** Updated Implementation Notes in `docs/specs/features/*.md` (in-place annotations: PLANNED, RESOLVED, DRIFT, UPDATED, REVERTED)

**Consumes:** Feature spec files, actual source code (searches all tiers: schema, backend, frontend, tests)

**Key detail:** Does NOT touch ACs — that's spec-ac-sync's job. Flags drift but doesn't resolve it. Checks cross-feature dependencies (Feature B RESOLVED but depends on Feature A still PLANNED).

---

### 8. agentic-e2e-playwright
**What it does:** Writes E2E tests that behave like real users — accessibility-first selectors, page objects, API waits, shared account cleanup.

**Produces:** `e2e/specs/**/*.spec.ts`, page objects, test helpers

**Consumes:** Journey docs (primary test source — reads scenarios as test scripts), persona files (from journey headers), AC tables (maps tests to AC IDs), actual component source code (reads before writing selectors)

**Key detail:** Reads the actual frontend code before writing any selector — never guesses. Fixes production bugs rather than writing test workarounds. Uses Base44 SDK as DB helper for test setup/teardown.

---

### 9. feature-marketing-insights
**What it does:** Mines feature specs for marketing ammunition — translates engineering descriptions into user-facing value claims with weights, audience segments, and competitive validation. The bridge between what the product IS and how you TALK about it.

**Produces:** `docs/marketing/product-marketing-context.md` (weighted insights + foundation), `docs/marketing/feature-mining-tracker.json` (persistent state), `.agents/product-marketing-context.md` (consumer file for downstream marketing skills)

**Consumes:** Feature specs (`docs/specs/features/*.md`), spec Implementation Notes (live vs planned status), foundational context (vision, audience, competitors)

**8 modes:** Full Scan (iterative 3-4 features/session), Single Feature, Refresh (re-mine changed specs), Foundation (sections 1-12), Compact (trim low-weight), Capability Combinations (cross-feature narratives), Quality Eval, Persona Validation (virtual buyers interrogate the marketing)

**Key detail:** Processes 3-4 features per conversation to avoid context degradation. Tracker persists state across sessions. Mode 3 (Refresh) checks spec-code-sync's Implementation Notes — when a PLANNED item becomes qualifying live status (`RESOLVED`/`FIXED`/verified `UPDATED`), planned-feature penalty is removed and the insight is upgraded; `DRIFT`/`REVERTED` prevents live marketing until corrected. Mode 8 (Persona Validation) constructs virtual buyer personas that could inform persona-builder.

**Where it fits:** feature-marketing-insights sits on a parallel track — the marketing extraction layer. The product pipeline (personas → journeys → specs → code → e2e) builds the product. feature-marketing-insights reads the same specs and translates them for the market. It doesn't feed back into the product pipeline directly, but its persona validation (Mode 8) can surface gaps that persona-builder should address, and its live-vs-planned checking depends on spec-code-sync status annotations (`RESOLVED`/`FIXED`/`UPDATED`/`DRIFT`/`REVERTED`).

---

## The Dependency Graph

```
                      vision-sync
                 (WHAT product is and why)
                          │
                          ▼
                    persona-builder
                    (WHO are users)
                         │
                    reads personas
                         ▼
feature-discovery ◄────► journey-sync ──────► journey-qa-ac-testing ──────► agentic-e2e-playwright
(VALIDATE ideas)    routes   (HOW they move)   (VERIFY real runtime)         (PROVE it works)
      │             back          │                    ▲                               │
      │                           │                    │                               │
      ▼                           ▼                    │                               │
  spec-ac-sync ◄──────── spec-code-sync ───────────────┘                               │
  (ARE specs complete)    (SYNC spec↔code↔journey reality)                              │
      │                                                                                 │
      └──────────────────────── AC table contract ───────────────────────────────────────┘

                    feature-marketing-insights ◄───────────────────────────────────────────────────┘
                    (MARKET what's built)
                    reads specs + status annotations
                         │
                         ▼
                    downstream marketing skills
                    (core pack + optional external add-ons)
```

### Data flow (what feeds what)

| Producer skill | Artifact | Consumer skills |
|---------------|----------|-----------------|
| vision-sync | Canonical vision + evidence-backed change proposals | persona-builder (user framing), feature-discovery (idea alignment), journey-sync (north-star boundaries) |
| persona-builder | `P*.md` persona files | journey-sync (Phase 2), agentic-e2e (persona from journey header), feature-discovery (Step 0 Tier 1) |
| journey-sync | `J*.feature.md` journey docs | agentic-e2e (primary test source), feature-discovery (Step 0 Tier 1) |
| journey-sync | Layer 3 findings | feature-discovery (ungrounded preconditions), persona-builder (missing persona), spec-ac-sync (missing transitions) |
| spec-ac-sync | AC tables in feature specs | journey-qa-ac-testing (manual QA status), agentic-e2e (maps tests to AC IDs), spec-code-sync (reads for drift) |
| spec-code-sync | Status annotations (`RESOLVED`/`FIXED`/`UPDATED`/`DRIFT`/`REVERTED`) | spec-ac-sync (stale ACs need rewriting) |
| journey-qa-ac-testing | Journey runtime verification + evidence + QA status updates | spec-ac-sync (missing/weak AC fixes), journey-sync (flow gap fixes), agentic-e2e (automation follow-up) |
| feature-discovery | Feature Ship Brief | journey-sync (input for new journeys), implementation planning (repo-specific; optional `writing-plans` add-on) |
| agentic-e2e | E2E test results | spec-ac-sync (E2E column gets filled) |
| feature-marketing-insights | Marketing context doc + tracker | Downstream marketing skills (core-pack outputs + optional external add-ons) |
| feature-marketing-insights | Mode 8 persona validation gaps | persona-builder (buyer personas may reveal missing product personas) |

### Cross-skill routing (when skill A finishes, what's next)

| Skill just finished | Finding | Route to |
|--------------------|---------|----------|
| vision-sync | Vision missing or first-pass canonicalized | persona-builder (persona set from canonical user/problem framing) |
| vision-sync | Evidence conflict or unresolved scope drift | spec-code-sync for drift check, then rerun vision-sync grounded |
| journey-sync | Journey set finalized for release validation | journey-qa-ac-testing (smoke/regression) |
| journey-sync | Ungrounded precondition — no producer journey, no UI | feature-discovery |
| journey-sync | Ungrounded precondition — UI exists but bypasses validation | implementation planning (repo-specific; `writing-plans` if add-on installed) |
| journey-sync | Missing persona for a role | persona-builder |
| journey-sync | Missing transition needs ACs | spec-ac-sync |
| journey-sync | Concept fragmentation (two names, one entity) | feature-discovery |
| feature-discovery | Consumer journey exists, producer missing | journey-sync (Mode 2: Expand) |
| feature-discovery | Not a new feature — pipeline fix | implementation planning (repo-specific; `writing-plans` if add-on installed) |
| feature-discovery | Feature crosses role boundaries | journey-sync first, then back |
| feature-discovery | Persona doesn't exist for this user type | persona-builder |
| spec-code-sync | DRIFT found — spec says X, code does Y | Developer decides: fix code or update spec |
| spec-code-sync | PLANNED → live-status annotation (`RESOLVED`/`FIXED`/verified `UPDATED`) | spec-ac-sync (ACs may need updating) |
| spec-ac-sync | ACs written/rewritten | journey-qa-ac-testing (manual verification), then agentic-e2e (new tests to write) |
| journey-qa-ac-testing | AC failures found in runtime | fix code/spec -> rerun journey-qa-ac-testing |
| agentic-e2e | Tests passing, E2E column filled | Done — or spec-ac-sync if gaps found during testing |
| persona-builder | New persona created | journey-sync (new persona needs journeys) |
| persona-builder | Skill audit findings | Update the flagged skills |
| feature-marketing-insights | Specs mined, marketing context built | Downstream content layer (core pack first, optional external add-ons) |
| feature-marketing-insights | Mode 3 Refresh — spec changed, PLANNED→live status (`RESOLVED`/`FIXED`/verified `UPDATED`) | Upgrade insight weight, remove planned penalty |
| feature-marketing-insights | Mode 8 Persona Validation gaps | persona-builder (buyer persona gap may = product persona gap) |
| spec-code-sync | Live-status annotation (`RESOLVED`/`FIXED`/verified `UPDATED`) | feature-marketing-insights Mode 3 (Refresh — re-mine to upgrade planned→live weight) |
| spec-code-sync | `DRIFT` / `REVERTED` on previously marketed feature | feature-marketing-insights Mode 3 (downgrade/deprecate stale live claims) |

---

## When to Use Each Skill

### "I need to create, convert, or realign product vision"
1. **vision-sync** — create/refine/convert canonical vision with evidence table
2. **persona-builder** — derive or refresh personas from canonical vision
3. **journey-sync** — regenerate journeys if north-star/problem framing changed

### "I'm starting a new product / major feature area"
1. **vision-sync** (intent=create, mode=grounded) — establish canonical product direction first
2. **persona-builder** (Mode 7: Tiered Auto-Discovery) — who are the users?
3. **journey-sync** (Mode 6: Tiered Auto-Discovery) — how do they move through it?
4. **spec-ac-sync** — are the feature specs testable?
5. **journey-qa-ac-testing** (smoke/feature-ac) — validate runtime behavior against journeys + ACs
6. **agentic-e2e-playwright** — automate validated flows

### "Someone asked about a feature idea"
1. **feature-discovery** — validate against existing personas, journeys, code

### "Run manual QA by journeys against local/staging/prod"
1. **journey-qa-ac-testing** — execute flow-based runtime verification at target URL
2. **spec-ac-sync** — tighten any vague/missing ACs discovered during QA
3. **agentic-e2e-playwright** — automate stable, validated paths

### "I just shipped code and want to verify everything"
1. **spec-code-sync** — does the code match the specs?
2. **journey-qa-ac-testing** (smoke/regression) — verify runtime behavior at target URL
3. **spec-ac-sync** — are new behaviors covered by ACs?
4. **agentic-e2e-playwright** — write tests for uncovered ACs

### "Tests are failing / specs feel stale"
1. **spec-code-sync** — find where specs drifted from code
2. **spec-ac-sync** — fix vague or missing ACs
3. **journey-sync** (Mode 3: Refresh) — update journeys with current state
4. **journey-qa-ac-testing** — re-verify runtime flows after fixes
5. **vision-sync** (mode=grounded) — update canonical vision if drift changes product reality

### "I think we're missing something but can't articulate what"
1. **persona-builder** (Mode 6: Discover Gaps) — scan product for uncovered user types
2. **journey-sync** — run Layer 3 analysis + cross-journey dependency graph
3. **feature-discovery** — for any gaps found

### "A stakeholder suggested a feature and I need to evaluate it"
1. **feature-discovery** — reads journeys and personas first, code second, asks questions only for what it can't answer from the codebase

### "What should we build next? What are users asking for?"
1. **feature-discovery** — mine existing journeys/specs/personas and recent code changes first to identify candidate gaps from your own product signals.
2. **[External Add-On: coreyhaines] customer-research** — optional enrichment from Reddit/G2/forums/competitor reviews. Use only if installed.
3. **feature-discovery** — for each finding, validate against internal personas,
   journeys, and specs. Is this already built? Is it concept fragmentation?
   Does a journey already cover it? Or is it genuinely new?
4. Route each validated idea to the right next step (journey-sync for new
   journeys, implementation planning for quick fixes, persona-builder if it reveals
   a new user type)

### "Time to start marketing / prepare for launch"
The marketing phase runs on a parallel track. It reads from the product pipeline
but doesn't block it. Run these in order:

1. **feature-marketing-insights** (Mode 1: Full Scan) — mine specs for marketing ammunition.
   Produces weighted insights, competitive landscape foundation, audience definition.
   Writes/syncs `.agents/product-marketing-context.md` as canonical consumer output.
2. **[External Add-On: coreyhaines] Optional transform:** `product-marketing-context`
   can rewrite/adapt the file, but must start from existing `.agents/product-marketing-context.md`
   and keep vibomatic insight sections intact.
3. **Core output use** — consume `.agents/product-marketing-context.md` directly in your repo workflows.
4. **[External Add-On: coreyhaines] Optional expansion**
   - `market-competitors`
   - `competitor-alternatives`
   - `copywriting`
   - `page-cro`
   - `launch-strategy`
   - `market-social`
   - `market-ads`
   - `market-emails`
   - `signup-flow-cro` / `onboarding-cro`
5. If external add-ons are used, pass `.agents/product-marketing-context.md` as the grounding input.
   If a specific add-on still expects `.claude/product-marketing-context.md`, create a compatibility mirror from `.agents` but keep `.agents` as canonical.

### "Product changed, marketing needs to catch up"
1. **spec-code-sync** — finds status changes (PLANNED→live, plus DRIFT/REVERTED where behavior changed)
2. **feature-marketing-insights** (Mode 3: Refresh) — re-mines changed specs, upgrades
   planned→live weight, re-syncs consumer context
3. **[External Add-On: coreyhaines]** refresh `market-competitors` if installed and competitive landscape changed
4. Re-run any downstream content skill (core or external) that referenced the changed features

---

## How to Check Project State

Before recommending a skill, check what exists:

```bash
# Personas
ls docs/specs/personas/P*.md 2>/dev/null | wc -l

# Journeys
ls docs/specs/journeys/J*.feature.md 2>/dev/null | wc -l

# Feature specs
ls docs/specs/features/*.md 2>/dev/null | wc -l

# E2E tests
find e2e -name "*.spec.ts" 2>/dev/null | wc -l

# Last activity
git log --oneline -5 -- docs/specs/
```

| State | What's missing | Start with |
|-------|---------------|------------|
| No canonical vision | Product direction undefined | vision-sync (intent=create) |
| Legacy/multiple vision files | Canonical source unclear | vision-sync (intent=convert) |
| No personas, no journeys | Everything | persona-builder (Mode 7) |
| Personas exist, no journeys | User flows undefined | journey-sync (Mode 6) |
| Journeys + ACs exist, runtime not manually verified | QA confidence gap | journey-qa-ac-testing |
| Personas + journeys exist, specs vague | ACs not testable | spec-ac-sync |
| Everything exists, code changed since | Possible drift | spec-code-sync |
| Everything exists and synced | Proof it works | agentic-e2e-playwright |
| Product ready, no marketing context | Marketing not started | feature-marketing-insights (Mode 4: Foundation, then Mode 1: Full Scan) |
| Marketing context exists, no competitor report | Competition unknown | [External Add-On: coreyhaines] market-competitors |
| Context + competitors exist, no vs pages | SEO gap | [External Add-On: coreyhaines] competitor-alternatives |
| Context exists, stale (specs changed) | Marketing out of date | feature-marketing-insights (Mode 3: Refresh) |
