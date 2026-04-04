# Proposal: Blend gstack Best Practices into vibomatic

## The Vision

You give a high-level vision. A virtual founder persona takes over — it researches
real-world signals, makes research-backed decisions, steers the entire pipeline,
and hands control back to you when it matters. In auto mode it drives; in
interactive mode it asks you the same questions but informed by research it
already did.

Every decision is auditable. The system learns from each run and gets smarter.

## What We're Blending (14 gstack capabilities → vibomatic)

### Layer 1: The Virtual Founder Persona (new)

**What:** A persistent persona created from your vision input that acts as
decision-maker throughout the pipeline. It:
- Researches demand signals, competitors, trends (last 30 days)
- Makes decisions on your behalf (auto) or asks you informed questions (interactive)
- Can stop the pipeline: "hey, use this free tool for better results"
- Can recommend: "I found validation for this approach in [real data]"
- Learns across sessions

**Where:** Created at pipeline start (before vision-sync), consumed everywhere.

**Blends:** `/office-hours` (forcing questions) + `/learn` (compound memory) +
`persona-builder` (we already model personas) + the design-alternatives protocol
(we already have 5-option decisions).

**Implementation:**
1. Enhance `workflow-compass` to create the founder persona at session start
2. The persona document lives at `docs/specs/personas/P0-founder.md`
3. Every skill reads P0 and uses it to steer decisions
4. In auto mode: P0 decides. In interactive: P0 recommends, you pick.

---

### Layer 2: Adversarial Review Pipeline (3 gstack skills → embedded in gates)

| gstack skill | Blends into | What it adds |
|---|---|---|
| `/plan-ceo-review` | New: G0 gate after `writing-spec` | Scope challenge: expand/hold/reduce. "Should we build this at all? This much? This little?" |
| `/plan-eng-review` | Enhanced G4 gate in `writing-technical-design` | Adversarial architecture review. ASCII diagrams. Layer 1/2/3 tech search. |
| `/plan-design-review` | Enhanced G2/G3 gates in `writing-ux/ui-design` | 0-10 scoring per design dimension. AI-slop detection. |

**Implementation:**
1. Add adversarial review sections to the 3 design skills (not separate skills)
2. After each design skill produces its artifact, it runs its own adversarial pass
3. In auto mode: self-challenges, documents the argument
4. In interactive: presents the challenge to you

---

### Layer 3: Design Foundation (1 gstack skill → new section in existing skill)

| gstack skill | Blends into | What it adds |
|---|---|---|
| `/design-consultation` | `writing-ui-design` Step 0 | Creates DESIGN.md (brand, typography, colors, motion) before component specs |

**Note:** `writing-ui-design` already has a Step 0a "Ensure DESIGN.md Exists"
from the skill review findings (F4). This just needs to be enhanced with the
full design-consultation process (research landscape, propose creative system,
conversation not form-fill).

---

### Layer 4: Investigation + Safety (2 gstack skills → enhanced bugfix lane)

| gstack skill | Blends into | What it adds |
|---|---|---|
| `/investigate` | Enhanced `bugfix-brief` | Iron Law: no fixes without root cause. Scope lock. 3-attempt limit. Pattern library. |
| `/freeze` | `scripts/worktree.sh` | Edit scope lock command. Used automatically by investigate. |

**Implementation:**
1. Enhance `bugfix-brief` with the investigation protocol
2. Add `scripts/worktree.sh freeze <directory>` command
3. Bugfix lane: investigate → scope-lock → fix → verify → unlock

---

### Layer 5: Release Engineering (3 gstack skills → enhanced landing flow)

| gstack skill | Blends into | What it adds |
|---|---|---|
| `/ship` | Enhanced `landing-change-set` Step 1 | Version bump, CHANGELOG, test audit before PR |
| `/canary` | New: post-landing monitoring step | Time-windowed live-site watch with baselines |
| `/document-release` | New: post-verification doc sync | Reconcile docs to shipped code |

**Implementation:**
1. `landing-change-set` gets a "prepare for ship" step before PR creation
2. `verifying-promotion` gets a canary monitoring step after tests
3. New standalone skill `doc-sync` runs after verification

---

### Layer 6: Security (1 gstack skill → new pre-implementation gate)

| gstack skill | Blends into | What it adds |
|---|---|---|
| `/cso` | New: security review between G4 and writing-change-set | OWASP Top 10, STRIDE, supply chain audit on the architecture |

**Implementation:**
1. New skill `security-review` in the pipeline
2. Models security as an Enabler spec (vibomatic's existing taxonomy)
3. Runs after `writing-technical-design`, before `writing-change-set`
4. Can also run post-deploy on a cadence

---

### Layer 7: Live Visual QA (1 gstack skill → enhanced journey-qa)

| gstack skill | Blends into | What it adds |
|---|---|---|
| `/design-review` | Enhanced `journey-qa-ac-testing` or new mode | Visual quality audit with atomic fix commits |

**Already partially done:** `journey-qa-ac-testing` now has browser integration
and exploratory patterns (PR #14). Add a `visual-quality` mode that specifically
checks design system compliance, spacing, hierarchy.

---

### Layer 8: Learning System (1 gstack skill → new infrastructure)

| gstack skill | Blends into | What it adds |
|---|---|---|
| `/learn` | New: automatic per-skill learning capture | JSONL store. Every skill logs discoveries. Compound across sessions. |

**Implementation:**
1. `docs/learnings/learnings.jsonl` — append-only log
2. Every skill's Pipeline Continuation section gets a "log learning" step
3. New standalone skill `review-learnings` to search, prune, export
4. `workflow-compass` reads learnings to improve routing recommendations

---

### Layer 9: Pipeline Orchestrator (1 gstack skill → enhanced workflow-compass)

| gstack skill | Blends into | What it adds |
|---|---|---|
| `/autoplan` | Enhanced `workflow-compass` | Auto-decision framework. Mechanical/Taste/UserChallenge classification. Sequential execution with single approval gate. |

**Implementation:**
1. `workflow-compass` gains an `--autorun` mode
2. Classifies each pipeline decision as Mechanical (auto), Taste (surface at end), or User (stop and ask)
3. Runs skills sequentially, collects taste decisions, presents them at a single approval gate
4. This is the skill chaining gap fix identified in memory

---

## Pipeline After Blending (Greenfield Lane)

```
[P0 Founder Persona created]
  → vision-sync (P0 steers scope)
  → domain-expert + competitor-analysis (P0 uses this for market research)
  → persona-builder (P0 + real user personas)
  → feature-discovery (P0 validates against real demand signals)
  → writing-spec + G0 scope review (expand/hold/reduce)
  → spec-ac-sync
  → journey-sync
  → DESIGN.md consultation (if greenfield)
  → writing-ux-design + adversarial design review
  → writing-ui-design + adversarial design review
  → writing-technical-design + adversarial eng review
  → solution-explorer
  → security-review
  → spec-style-sync
  → writing-change-set
  → [WORKTREE]
  → executing-change-set (local-first, mock deps)
  → review-protocol
  → systems-analysis
  → cross-model-review (optional)
  → journey-qa-ac-testing (browser + exploratory + visual quality)
  → visual-tracker diff
  → [LEAVE WORKTREE]
  → landing-change-set (version + changelog + PR)
  → verifying-promotion
  → canary monitoring
  → doc-sync
  → [LOG LEARNINGS]
```

## Implementation Order

| Phase | What | Effort |
|-------|------|--------|
| 0 | gstack browse daemon (infrastructure for all browser skills) | Low (use directly, MIT) |
| 1 | P0 Founder Persona + enhanced workflow-compass | Medium |
| 2 | Adversarial review in 3 design skills + G0 scope review | Medium |
| 3 | Investigation protocol in bugfix-brief + freeze | Low |
| 4 | Release engineering (ship prep + canary + doc-sync) | Medium |
| 5 | Security review skill | Medium |
| 6 | Learning system (JSONL + per-skill logging) | Medium |
| 7 | Autorun orchestrator in workflow-compass | High |

## What We're Taking Directly from gstack

| gstack skill | How we use it |
|---|---|
| `/browse` daemon | **Use directly as infrastructure.** gstack's browse is MIT — persistent Chromium, ~100ms, cookies/tabs/localStorage persist, ARIA refs. All browser-dependent skills (QA, canary, design-review, visual-tracker, benchmark) use it. Not Playwright MCP — the real browser. |

## What We're NOT Taking

| gstack skill | Why skip |
|---|---|
| `/design-shotgun` | Depends on gstack designer binary (proprietary) |
| `/design-html` | Depends on Pretext (gstack-specific) |
| `/benchmark` | Nice-to-have, not blocking. Add later. |
| `/retro` | Nice-to-have, not blocking. Add later. |
| `/careful` + `/guard` | Nice-to-have safety. Add with investigate. |
| `/codex` | Already have cross-model-review. |
