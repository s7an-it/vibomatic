---
name: analyze-competitors
description: >
  Systematic product intelligence on top competitors in the project's domain.
  Finds top 5 companies, analyzes what they do well and poorly, identifies
  whitespace and differentiation opportunities. NOT marketing copy — product
  decisions. Produces docs/specs/analyze-competitors.md. Use when: "competitors",
  "what else exists", "market analysis", "who are we competing with", "differentiation",
  or automatically after analyze-domain in progressive greenfield mode.
inputs:
  required:
    - { path: "docs/specs/vision.md", artifact: vision }
  optional:
    - { path: "docs/specs/domain-profile.md", artifact: domain-profile }
    - { path: "docs/specs/analyze-competitors.md", artifact: existing-analysis }
outputs:
  produces:
    - { path: "docs/specs/analyze-competitors.md", artifact: analyze-competitors }
chain:
  lanes:
    greenfield: { position: 2, prev: write-vision, next: build-personas, parallel: analyze-domain }
  progressive: true
  self_verify: true
  human_checkpoint: false
---

# Competitor Analysis

Product intelligence — what exists in the market, what works, what's missing,
and where the whitespace is. This is NOT marketing positioning. This feeds product
decisions: feature scope, UX patterns, differentiation strategy.

**Announce at start:** "I'm using the analyze-competitors skill to map the competitive landscape."

## Process

### Step 1: Define the competitive space

Read `docs/specs/vision.md` and `docs/specs/domain-profile.md` (if exists).

Determine: what category does this product compete in? Be specific — not "productivity tool"
but "AI-assisted learning recommendation platform" or "real-time collaboration for distributed teams."

### Step 2: Find top 5 competitors

**If `/last30days` is available** (recommended — [mvanhorn/last30days-skill](https://github.com/mvanhorn/last30days-skill)):
Run `/last30days "[category] tools products competitors"` first. This gives
you what people are ACTUALLY talking about right now — not just what ranks on
Google. Cross-platform signals (Reddit + HN + X) reveal which competitors have
real momentum vs which are just SEO-optimized landing pages.

**Then supplement with WebSearch** for:
- "[category] top companies {current year}"
- "[category] best tools {current year}"
- "[category] alternatives comparison"
- "[specific problem from vision] solutions"

Select the 5 most relevant competitors. Criteria:
- Direct competitors (solve the same problem for the same users) > 3
- Adjacent competitors (solve a related problem or the same problem differently) ≤ 2
- Include at least 1 emerging/startup competitor if one exists

### Step 3: Analyze each competitor

For each of the 5, gather:

| Dimension | How to find | What matters |
|-----------|------------|-------------|
| **Core product** | Landing page, product tours, docs | What do they actually do? |
| **Key features** | Feature pages, pricing tiers | What's included/excluded at each tier? |
| **Tech approach** | Blog posts, docs, GitHub (if open source) | How do they build it? |
| **UX patterns** | Screenshots, demos, reviews mentioning UX | What feels good/bad to use? |
| **Business model** | Pricing page | Free tier? Subscription? Usage-based? |
| **User love** | G2/Product Hunt/Reddit/last30days — positive | What do users praise? |
| **User pain** | G2/Product Hunt/Reddit/last30days — negative | What do users complain about? |
| **Current buzz** | last30days (if available) | What are people saying RIGHT NOW? Trending or stale? |
| **Differentiator** | Positioning, "why us" page | What do they claim is unique? |

### Step 4: Synthesize whitespace

After analyzing all 5:

1. **What do they ALL do?** (table stakes — we must have these)
2. **What do SOME do well?** (competitive features — consider adopting)
3. **What do NONE do well?** (whitespace — potential differentiation)
4. **What do users consistently complain about?** (pain points — opportunity)
5. **What approach is nobody taking?** (the non-obvious angle)

### Step 5: Write analysis

Produce `docs/specs/analyze-competitors.md`:

```markdown
# Competitor Analysis

**Generated:** YYYY-MM-DD
**Category:** [specific competitive category]
**Source:** WebSearch + public reviews

## Top 5 Competitors

### 1. [Company Name]
- **What they do:** [1-2 sentences]
- **Key features:** [bulleted list]
- **Business model:** [pricing approach]
- **Users love:** [from reviews]
- **Users hate:** [from reviews]
- **Differentiator:** [what they claim]

### 2-5. [Same structure]

## Landscape Summary

### Table Stakes (everyone has, we must too)
- [feature 1]
- [feature 2]

### Competitive Features (some have, worth considering)
- [feature] — [who has it, why it matters]

### Whitespace (nobody does well)
- [gap 1] — [why it's an opportunity]
- [gap 2] — [why it's an opportunity]

### Common User Complaints (across all competitors)
- [complaint] — [N mentions across reviews]

## Differentiation Opportunity

Based on the whitespace and user pain:
- **Our angle:** [how vision.md's approach differs]
- **What we can do that they can't/won't:** [specific capabilities]
- **What we should steal:** [best practices from competitors]
- **What we should avoid:** [mistakes competitors make]

## Impact on Feature Decisions

- **Feature discovery Q4 (the bet):** [informed by whitespace]
- **Spec ACs:** [informed by table stakes + competitive features]
- **UX design:** [informed by what users love/hate about competitors]
- **Marketing positioning:** [informed by differentiation opportunity]
```

## Auto Mode vs Guided Mode

**Auto mode:** Research silently, produce analysis, chain forward.

**Guided mode:** Present each competitor with key findings. Ask:
"These are the top 5 I found. Any I'm missing, or any you know about that aren't showing up in search?"

For the whitespace synthesis: "Here's where I see the opportunity. Does this match your intuition?"

## Brownfield Behavior

For existing products: read the codebase to understand what features already exist, then compare against competitors. The analysis focuses on gaps: "Competitors A and B have [X] and you don't. Competitors C and D have [Y] which you do better."

## Self-Verify

| # | Check | How | PASS/FAIL |
|---|-------|-----|-----------|
| 1 | `docs/specs/analyze-competitors.md` exists | `test -f` | |
| 2 | At least 3 competitors analyzed | count ### headers | |
| 3 | Whitespace section identifies ≥1 opportunity | grep for Whitespace | |
| 4 | Differentiation section connects to vision | references vision.md concepts | |

## Audit Mode

When invoked with `--audit` to refresh competitive intelligence:

1. Read `docs/specs/analyze-competitors.md`
2. Check age: more than 30 days old? Market moves fast.
3. WebSearch for recent changes: new competitors? Pivots? Shutdowns?
4. Check our product against the table stakes list: any we still don't have?
5. Check whitespace: has any competitor filled a gap we identified?
6. Report: competitor-by-competitor CURRENT/CHANGED/NEW with specific findings

## Pipeline Continuation

**If `--progressive` and self-verify passed:**
- This skill runs in parallel with `analyze-domain` (dispatched by route-workflow).
- Do NOT chain to build-personas — the orchestrator handles sequencing.
- When both complete, orchestrator chains to `build-personas`.

**If standalone:**
- Report competitive landscape summary
- Suggest: "Next: run `build-personas` or `validate-feature`"
