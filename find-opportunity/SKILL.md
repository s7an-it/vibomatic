---
name: find-opportunity
description: >
  Find the fastest path to revenue for this builder. Reverse-engineers what's
  making money NOW, matches to builder skills/distribution, scores and ranks
  opportunities. Use when: "what should I build", "find me a project", "fastest
  path to revenue", "I need money", "first project", "help me pick", or when
  validate-feature returns NO-SHIP and the builder needs alternatives. Also use
  when the builder has a big idea but no capital — this finds a Stage 1 revenue
  project that funds the real thing.
inputs:
  required:
    - { path: "~/.claude/builder-profile.md", artifact: builder-profile }
  optional:
    - { path: "docs/specs/vision.md", artifact: vision }
outputs:
  produces:
    - { path: "docs/specs/opportunities/top-3-opportunities.md", artifact: top-3-opportunities }
chain:
  lanes: {}
  progressive: false
  self_verify: true
  human_checkpoint: true
---

# Find Opportunity

Find what to build. Not what COULD work — what IS working, and whether this
specific builder can ship a competitive version in 1-2 weeks.

This skill replaces guesswork with evidence. It scans real markets, finds real
products making real money, identifies their weaknesses, and matches opportunities
to the builder's specific skills, distribution channels, and constraints.

**Announce at start:** "I'm using the find-opportunity skill to scan the market
and find revenue opportunities matched to your builder profile."

## The Bar

The target is not "$500/mo someday." The target is:

> **Almost guaranteed $1K/mo within 1 month of launch, with 1-2 weeks of build time.**

99% of builders with the right guidance can hit this. The system finds
opportunities where current market conditions make this realistic — not
speculative, not "if everything goes right." Products where similar things are
ALREADY making money and the builder can ship a competitive version with their
specific skills in 1-2 weeks.

If an opportunity cannot clear this bar with evidence, it does not make the
top 3.

---

## Prerequisites

### Builder Profile (Required)

Read `~/.claude/builder-profile.md`. If it does not exist, stop and tell the
user: "I need your builder profile to find opportunities matched to you.
Run /route-workflow to create one, or describe your situation: skills, time,
budget, distribution channels."

The builder profile IS the input. Without knowing who the builder is, every
recommendation is generic and useless. The profile tells you:
- What they can build (skills)
- Who they can reach (distribution)
- How fast they can ship (hours/week)
- What they can spend ($0 or otherwise)
- What has worked/failed before (project history)
- Whether they have a business entity (payment constraints)

### Vision (Optional)

If `docs/specs/vision.md` exists, read it. The builder has a big idea. In this
case, the skill looks for Stage 1 revenue projects that FEED the big idea:
same audience, same domain, smaller scope, immediate revenue. The best Stage 1
project earns money AND builds an audience for the real thing.

If no vision exists, the skill runs in pure discovery mode — find the best
opportunity for this builder regardless of any larger direction.

---

## Process

```
Builder Profile → Extract Advantages → Market Scan → Reverse-Engineer Winners →
Match to Builder → Score & Rank → Present Top 3 → User Picks → Hand Off
```

---

## Step 1: Extract Builder Advantages

From the builder profile, extract what this specific person can do BETTER or
CHEAPER than the average builder. This is not a skills inventory — it is a
competitive advantage map.

```markdown
## Builder Advantages

### Can Build (Technical Edge)
- <languages, frameworks, infra — what they ship fast in>
- <specific technical strengths that narrow the field>

### Can Reach (Distribution Edge)
- <social platforms with follower counts AND engagement quality>
- <communities they participate in — subreddit names, Discord servers>
- <email list, newsletter, existing audience>
- <marketplace presence — existing apps, extensions, plugins>

### Has (Infrastructure Edge)
- <existing subscriptions, free tiers in use, domains>
- <existing codebases, templates, boilerplate they can reuse>
- <business entity status, payment processor access>

### Time Budget
- <hours/week available, realistic ship timeline at their pace>
- <1-2 week build at their pace = X total hours>

### Unique Angle
- <domain expertise from their job, hobby, or past projects>
- <perspective that most builders in this space lack>

### Hard Constraints
- <skills they lack or have failed at — hard vetoes>
- <budget ceiling — $0 means free-tier only>
- <entity status — affects payment processor options>
- <employment contract limitations>

### History Signal
- <patterns from past projects: what worked, what killed projects>
- <reusable assets from abandoned/shipped projects>
- <motivation patterns — how long before they lose steam?>
```

**Critical:** If the builder profile shows a repeated failure mode (2+ projects
died the same way), that failure mode becomes a hard veto. If 2/3 past projects
died because the builder couldn't do marketing, do NOT recommend
marketing-heavy strategies. Pick products with built-in distribution
(marketplace apps, SEO-driven tools, integrations).

---

## Step 2: Product Category Matrix

Scan across ALL categories. The best opportunity might not be in the builder's
obvious niche. Rate each category for fit BEFORE doing deep research — this
focuses the market scan on categories worth investigating.

| Category | Examples | Revenue Model | Build Time | Distribution |
|---|---|---|---|---|
| **Chrome extensions** | Productivity, AI wrappers, page enhancers | Freemium ($5-15/mo) or one-time ($10-30) | 3-7 days | Chrome Web Store SEO + communities |
| **Web apps (SaaS)** | Dashboards, tools, calculators, converters | Subscription ($9-49/mo) | 1-4 weeks | SEO + content + communities |
| **Mobile apps** | Utilities, lifestyle, productivity | In-app purchase or subscription | 2-6 weeks | App Store SEO + social |
| **API services** | Data APIs, AI wrappers, conversion tools | Pay-per-use or subscription | 3-10 days | Dev communities + docs + marketplaces |
| **CLI tools** | Dev tools, automation, scripts | One-time ($20-50) or subscription | 1-2 weeks | GitHub + dev communities |
| **Templates/boilerplates** | Starter kits, themes, component packs | One-time ($29-99) | 1-2 weeks | Twitter/X + ProductHunt + Gumroad |
| **AI wrappers** | ChatGPT/Claude front-ends for specific niches | Pay-per-use (user-funded) | 3-7 days | SEO + niche communities |
| **Browser automation** | Scrapers, auto-fillers, monitoring bots | Subscription ($15-30/mo) | 1-2 weeks | Niche forums + Reddit |
| **Marketplace apps** | Shopify apps, VS Code extensions, Raycast, Figma plugins | Marketplace cut or subscription | 1-3 weeks | Built-in marketplace distribution |
| **Info products** | Guides, courses, cheat sheets from domain expertise | One-time ($20-100) | 3-5 days | Existing audience + SEO |
| **Notification/alert services** | Monitoring, price alerts, stock alerts, keyword alerts | Subscription ($5-20/mo) | 1-2 weeks | Communities + SEO |

For each category, quick-score builder fit:

| Fit Dimension | Question |
|---|---|
| **Technical** | Can the builder ship this in 1-2 weeks with their current skills? |
| **Distribution** | Can the builder reach buyers through existing channels? |
| **Entity** | Does this category require a business entity the builder doesn't have? |
| **Budget** | Does this require upfront capital the builder doesn't have? |

Eliminate categories that fail on Technical or Distribution. Flag categories
that fail on Entity or Budget (may be solvable with LemonSqueezy/Gumroad).
Focus the market scan on the top 3-5 categories that pass.

---

## Step 3: Market Scan Protocol

This is the core of the skill. Do not guess what might work. Find what IS
working and reverse-engineer it.

### 3a: Invoke Research Tools

Use the `research` skill for web searches. Search systematically across
multiple sources. This is not a single Google search — it is a structured
sweep of real market data.

**If `last30days` is available** ([mvanhorn/last30days-skill](https://github.com/mvanhorn/last30days-skill)):
Run it FIRST for each promising category. This gives you what people are
ACTUALLY talking about right now — engagement signals, cross-platform
convergence, and trend velocity that web search alone cannot provide.

```
/last30days "<category> tool app alternative revenue indie maker"
```

Extract from last30days output:
- **Trending niches** — high engagement (100+ upvotes, 50+ comments) = real demand
- **Specific products mentioned** — names to reverse-engineer
- **Complaints about existing tools** — weaknesses to exploit
- **Cross-platform signals** — same topic on Reddit AND HN AND X = genuine demand

**If `last30days` is not available:** Fall back to `research` skill (WebSearch)
exclusively. Less grounded — no engagement metrics — but still evidence-based.

### 3b: Source-by-Source Search Protocol

For each promising category, search these sources in order:

| Source | Search Queries | What You Learn |
|---|---|---|
| **IndieHackers revenue pages** | Filter by $1K-$10K MRR, solo founder, builder's niche | What solo builders actually earn, what categories work, what they say about distribution |
| **ProductHunt recent launches** | Last 90 days, 100+ upvotes, in builder's category | What is getting traction NOW, not 2 years ago. Read comments for feature requests. |
| **Chrome Web Store** | Builder's niche keywords + "recently updated" | Existing extensions, user counts, review star ratings, specific complaints in reviews |
| **App Store / Play Store** | Top free/paid in utility/productivity categories | Mobile gaps, pricing patterns, review complaints |
| **GitHub trending** | Past month, builder's primary languages | What developers want, star velocity, issues (= unmet needs) |
| **Gumroad / LemonSqueezy discover** | Top sellers in builder's niche | Actual price points people pay, sales volume indicators |
| **Reddit** | Builder's active subs + "I built", "I made", "alternative to", "is there a", "I wish there was" | What people built AND what people wish existed. The "I wish" threads are gold. |
| **X/Twitter** | "launched", "just shipped", "MRR", "$X/mo" in builder's niche | Real-time launch signals, who is making money, what they share publicly |
| **Hacker News** | "Show HN" + builder's niche in past 90 days | What the technical community values, comment quality = demand signal |

### 3c: Use analyze-competitors for Deep Dives

When a promising niche emerges from the scan (3+ signals pointing at the same
opportunity), invoke the `analyze-competitors` skill on that specific niche.
This gives you:
- The top 5 products in that micro-niche
- What they do well (table stakes you must match)
- What they do poorly (weakness to exploit)
- Whitespace (what nobody does)

Do NOT run analyze-competitors on every category. Only on niches where the
market scan found strong signal. Typically 1-2 deep dives per opportunity
search.

### 3d: Reverse-Engineering Process

For each product found making $1K+/mo in a category the builder can execute:

```markdown
### Product: <name>
**URL:** <link>
**Revenue signal:** <how you know it's making money — MRR reported, app store ranking, review volume>
**Category:** <from matrix>
**What it does:** <one sentence>
**What it does WELL:** <the thing users praise>
**What it does POORLY:** <specific weakness — from reviews, complaints, missing features>
**Can this builder exploit the weakness?**
  - Technical: <yes/no — can they build the fix?>
  - Distribution: <yes/no — can they reach the same audience?>
  - Timeline: <yes/no — can they ship in 1-2 weeks?>
**Opportunity:** <the angle — what to build and why it wins>
```

Repeat for 10-20 products across the promising categories. Then filter to
the strongest opportunities.

---

## Step 4: Self-Sustaining Infrastructure

**Mandatory:** every recommendation must use infrastructure that costs $0
until revenue exceeds the cost. The project must self-sustain from day 1.

| Layer | Free Tier Pick | Scales To | When to Pay |
|---|---|---|---|
| **Database** | Supabase (500MB, 50K rows) | Supabase Pro ($25/mo at ~$500 revenue) | Revenue covers it |
| **Hosting** | Vercel (100GB bandwidth) | Vercel Pro ($20/mo) | Revenue covers it |
| **Auth** | Supabase Auth (50K MAU) or Clerk (10K MAU) | Same platform Pro tier | Revenue covers it |
| **Storage** | Supabase Storage (1GB) or Cloudflare R2 (10GB) | Pay as you grow | Revenue covers it |
| **Email** | Resend (3K/mo) or Loops (1K contacts) | Resend $20/mo | Revenue covers it |
| **Payments** | LemonSqueezy (5% + 50c) or Gumroad (10%) — no entity needed | Stripe when entity exists | From first sale |
| **Analytics** | Plausible (free trial) or Umami (self-hosted free) | Plausible $9/mo | Revenue covers it |
| **AI (if wrapper)** | OpenAI / Anthropic API (user-funded per request) | Scales linearly with users | Users pay per use |
| **Mobile** | Expo + EAS (30 builds/mo free) | EAS $99/mo | Revenue covers it |

**The rule:** $0 out of pocket until revenue exceeds infra cost. Every cost is
covered by revenue before it is incurred. If an opportunity requires paid infra
from day 1 and the builder has $0 budget, the opportunity is disqualified.

---

## Step 5: AI Wrapper Special Path

AI wrappers deserve special attention because they are the fastest path to
revenue for many builders right now.

**The model:** User pays $X per use. You take margin. API cost is covered by
the user. The builder never pays out of pocket for API costs.

**When to recommend wrappers:**
- Builder can code an API integration (most can)
- There is a specific use case where a general chatbot is 10x worse than a
  purpose-built interface (e.g., "AI that writes Shopify product descriptions"
  vs "ask ChatGPT to write product descriptions")
- The niche is specific enough that SEO or community distribution works
- The builder has domain expertise to make the wrapper actually good

**Multi-wrapper strategy:** If the builder's skills allow it and each wrapper
takes 3-5 days, launching 2-3 wrappers simultaneously is a valid strategy.
Different niches, same tech stack, shared infra. If one hits, double down.
If none hit in 30 days, pivot.

**Wrapper economics template:**

```markdown
**API cost per request:** ~$0.01-0.05 (depending on model + prompt size)
**User price per request:** $0.10-0.50 (or $9-29/mo subscription for N requests)
**Margin:** 5-50x on API cost
**Break-even users:** <calculate based on infra cost (usually $0 on free tier)>
**Path to $1K/mo:** <N users at $X/mo or N requests at $X/request>
```

---

## Step 6: Scoring

For each opportunity that survived the market scan and reverse-engineering
process, score on 6 dimensions:

| Dimension | Weight | What It Measures | Scoring Guide |
|---|---|---|---|
| **Guaranteed revenue** | 30% | Is there PROOF similar products make $1K+/mo? Not "could" — "does." | 10 = multiple products with public revenue data. 7 = one product with evidence. 4 = app store rankings suggest it. 1 = "people might pay for this." |
| **Builder fit** | 25% | Can THIS builder ship this in 1-2 weeks with their current skills? | 10 = core skills match perfectly, has done similar work. 7 = skills match, minor learning curve. 4 = needs one new skill. 1 = requires skills they lack. |
| **Distribution fit** | 20% | Can THIS builder reach paying users through existing channels? | 10 = active engaged audience in exact niche. 7 = relevant community presence. 4 = marketplace with built-in discovery. 1 = cold start required. |
| **Speed to first $** | 15% | Days from "start building" to first payment received. | 10 = can charge before building (pre-sales). 7 = under 14 days. 4 = under 30 days. 1 = 60+ days. |
| **Self-sustaining** | 5% | Does free-tier infra cover it until revenue scales? | 10 = all free tier, zero cost. 7 = one small paid tool. 4 = needs modest infra spend. 1 = significant upfront cost. |
| **Ecosystem value** | 5% | Does this contribute to the builder's larger goal? | 10 = directly feeds the big idea (same audience + domain). 7 = same audience, different product. 4 = builds general skills. 1 = pure money, no strategic value. |

**Total score = weighted sum, normalized to 0-100.**

Show the math. Do not hide scores behind vague language. Each dimension gets
a number and a one-sentence justification.

---

## Step 7: Disqualifiers

Hard vetoes that reject an opportunity regardless of score:

| Disqualifier | Why It Kills |
|---|---|
| **Requires skills the builder failed at before** | Pattern from project history. If 2+ projects died because of X, an opportunity requiring X is not "this time will be different" — it is a known failure mode. |
| **Takes > 2 weeks to build at builder's pace** | Calculate real hours: builder's hours/week x 2 weeks = available hours. If the MVP exceeds this, it is too big. |
| **No evidence of anyone paying for similar products** | "People should pay for this" is not evidence. Show a product, show revenue, show app store rankings, show paying customers. |
| **Requires business entity the builder doesn't have** | Stripe requires an entity. If the builder has no entity, the opportunity must work with LemonSqueezy, Gumroad, or Dodo. |
| **Requires upfront capital the builder doesn't have** | $0 budget means $0 spend. No exceptions. Not even "just $20/mo." |
| **Requires cold-start marketing the builder has no channel for** | If the only distribution plan is "post on Twitter" and the builder has 12 followers with zero engagement, that is not a plan. |
| **Builder has tried this exact thing before and it failed for the same reasons** | Check project history. Same concept repackaged with no new advantage (skills, tools, market shift) = same outcome. |

When a disqualifier fires, log it and move on. Do not present disqualified
opportunities in the top 3. Do mention them in a "Considered and Rejected"
section so the user sees the work.

---

## Step 8: Present Top 3

Save to `docs/specs/opportunities/top-3-opportunities.md` and present to the
user. Each opportunity uses this card format:

```markdown
# Top 3 Opportunities for <Builder Name>

Generated: <YYYY-MM-DD>
Builder profile: <one-line summary — role, hours/week, key skill, key channel>

---

## Opportunity 1: <Name>

**Category:** <Chrome extension / web app / API / CLI / mobile / template / etc>
**What:** <one sentence — what the product does>
**Reverse-engineered from:** <specific successful product + its specific weakness>
**Evidence:** <who is paying for similar things — revenue data, rankings, user counts>
**Why you:** <specific builder advantages from Step 1 that make this winnable>

### MVP (Week 1)
<exactly what to build — features, not architecture. User-facing behavior only.>
- <feature 1>
- <feature 2>
- <feature 3>
- Explicitly NOT: <what to leave out>

### Revenue Model
- **Price:** <specific price, benchmarked against competitors>
- **Model:** <one-time / subscription / pay-per-use>
- **Payment:** <LemonSqueezy / Gumroad / Stripe — based on entity status>
- **Path to $1K/mo:** <N users at $X = $1K. Based on competitor user counts, realistic.>

### Infrastructure (All Free Tier)
- <stack item 1> — free tier covers <what>
- <stack item 2> — free tier covers <what>
- Total cost: $0 until <revenue milestone>

### Distribution Plan
<How to get the first 20 paying users. Specific channels, specific actions.>
1. <action 1 — e.g., "Post in r/selfhosted (where you have 4yr account + karma)">
2. <action 2 — e.g., "Submit to Chrome Web Store (built-in SEO)">
3. <action 3 — e.g., "Cross-post on IndieHackers with build log">

### Build Time
- At <N> hrs/week: <X> days to MVP
- Total hours: ~<N>

### Revenue Projections
- **Month 1:** $<conservative estimate> (based on <evidence>)
- **Revenue ceiling:** $<where this tops out>/mo
- **Ecosystem value:** <does this feed the builder's bigger idea? how?>

### Risk
- <what could go wrong — honest, not hand-wavy>
- <mitigation if one exists>

### Score: <total>/100
| Dimension | Score | Why |
|---|---|---|
| Guaranteed revenue (30%) | <N>/10 | <one sentence> |
| Builder fit (25%) | <N>/10 | <one sentence> |
| Distribution fit (20%) | <N>/10 | <one sentence> |
| Speed to first $ (15%) | <N>/10 | <one sentence> |
| Self-sustaining (5%) | <N>/10 | <one sentence> |
| Ecosystem value (5%) | <N>/10 | <one sentence> |

---

## Opportunity 2: <Name>
<same structure>

---

## Opportunity 3: <Name>
<same structure>

---

## Considered and Rejected

### <Rejected Opportunity 1>
- **Why rejected:** <which disqualifier fired, or why it scored too low>
- **What would change this:** <what the builder would need to make it viable>

### <Rejected Opportunity 2>
<same structure>

---

## Recommendation

My pick is **Opportunity <N>** because <1-2 sentences explaining why, referencing
the builder's specific advantages>.

But this is your call. Pick the one that excites you — motivation is the #1
predictor of whether you'll ship.

**Pick 1, 2, 3, or "none of these."**
```

---

## Step 9: User Picks and Pipeline Handoff

### User picks an opportunity

1. Use the opportunity as the input to `write-vision`
2. The vision incorporates:
   - The opportunity's specific product definition
   - The builder profile constraints (budget, time, skills)
   - The infra choices from the opportunity card
   - The distribution plan as a first-class concern
   - The revenue model and pricing
3. `validate-feature` runs with the opportunity's evidence pre-loaded
   (revenue proof, competitor data, distribution plan)
4. The full pipeline runs from there

### User says "none of these"

Ask what is wrong. Three paths:
- **Wrong category:** "What categories feel right? I'll rescan focused there."
- **Right category, wrong angle:** "What's off about these? I'll dig deeper
  in the same space."
- **User has their own idea now:** Respect it. The scan may have sparked
  something. Run the pipeline on their idea.

Rescan with adjusted criteria. Present 3 new opportunities.

### User says "just pick the best one"

P0 picks Opportunity #1 (highest score), logs it as a taste decision in the
research log, and runs the pipeline. The user can always change direction
later.

### User says "build my idea anyway"

Respect it. Always. No gatekeeping. Run the pipeline on their idea.

But if their idea is a 2-month build with no revenue until launch and their
builder profile shows no capital, present the staging strategy:

**Staging Strategy:**

> "Your idea is solid but it's a [N]-week build with no revenue until launch.
> Here's a staging plan:"
>
> **Stage 1 (weeks 1-2):** Build [Opportunity N] — earns money AND [builds
> audience for / teaches domain of / is related to] your big idea.
>
> **Stage 2 (month 2-3):** Revenue from Stage 1 funds entity registration,
> Stripe, better tools, maybe a contractor for your weak skills.
>
> **Stage 3 (month 3+):** Build your big idea with revenue, audience, and
> tools from Stages 1-2.
>
> Or: "build my idea anyway" — always available.

If the vision exists and the staging strategy applies, prefer Stage 1 projects
that are RELATED to the big idea: same audience, same domain, smaller scope.
The best Stage 1 project earns money AND builds an audience for Stage 3.

---

## First Project Rules

When the builder profile shows first project, no capital, or no past revenue:

1. **Must ship in 1-2 weeks** at builder's hours/week. Not 6 weeks. 1-2.
2. **Must not require skills the builder has failed at.** Hard veto.
3. **Must have built-in distribution** through existing channels. No cold start.
4. **Must work without a business entity.** LemonSqueezy/Gumroad/Dodo.
5. **Revenue model must be dead simple.** One price, one product.
6. **Must be boring.** Proven demand. Reverse-engineered from existing winners.
7. **Must self-sustain on free tiers.** $0 until revenue exceeds cost.
8. **Must have evidence of $1K+/mo** from similar products. Not "could" — "does."
9. **Must be something the builder would use themselves.** Dogfooding = motivation.

The builder's journey:
```
$0 -> ship in 1-2 weeks -> first paying user -> $1K/mo month 1 ->
register entity -> Stripe -> reinvest -> build the real thing
```

The pipeline optimizes for wherever the builder IS in this chain.

---

## Self-Verify

Before declaring done, verify every check passes:

| # | Check | How | PASS/FAIL |
|---|-------|-----|-----------|
| 1 | At least 3 opportunities presented | Count opportunity cards in output | |
| 2 | Each opportunity has revenue evidence | Each card has "Evidence" with specific products/revenue, not speculation | |
| 3 | Each opportunity is buildable in 1-2 weeks at builder's pace | Build time calculated from builder's hours/week, not generic estimate | |
| 4 | Each opportunity uses free-tier infra | Infrastructure section shows $0 cost, no paid tools required | |
| 5 | Scoring is complete for all 6 dimensions | Every opportunity has a filled score table with justifications | |
| 6 | Distribution plan is specific to builder's channels | Plan references builder's actual platforms, follower counts, communities — not generic "post on social media" | |
| 7 | No disqualified opportunities in the top 3 | Cross-check each opportunity against all 7 disqualifiers | |
| 8 | Builder advantages are extracted and used | Step 1 output exists and each opportunity's "Why you" references it | |
| 9 | `docs/specs/opportunities/top-3-opportunities.md` exists | File written to disk | |
| 10 | If vision exists, ecosystem value is scored | Opportunities reference how they feed the big idea | |

If any check FAILs, fix before presenting to the user. If a fix requires
more research, run additional searches. Do not present incomplete opportunities.

---

## Pipeline Continuation

This skill does not participate in progressive chains. It is invoked by
`route-workflow` before `write-vision` (when the builder needs help finding
what to build), or after `validate-feature` returns NO-SHIP (when the
builder's idea was rejected and they need alternatives).

**After user picks an opportunity:**
- Invoke `write-vision` with the opportunity context
- The opportunity card becomes the seed for the vision document
- The full greenfield pipeline runs from there:
  `write-vision -> analyze-competitors + analyze-domain -> build-personas -> validate-feature -> write-spec -> ...`

**After user says "none" and provides their own idea:**
- Invoke `write-vision` with the user's idea
- Standard pipeline from there

**After user says "build my idea anyway" with staging:**
- Invoke `write-vision` for the Stage 1 project first
- Tag the vision with `stage: 1` and reference the big idea
- After Stage 1 ships and revenue flows, the user can invoke
  `find-opportunity` again or go straight to `write-vision` for Stage 3

---

## What This Produces

`docs/specs/opportunities/top-3-opportunities.md` containing:
- 3 scored, evidence-backed opportunity cards
- Builder advantages extraction
- Considered-and-rejected section
- Recommendation with reasoning

This is a decision document. It does NOT contain:
- Architecture or technical design (comes from write-spec)
- Implementation plan (comes from plan-changeset)
- Full competitive analysis (comes from analyze-competitors, invoked during scan)
- Product vision (comes from write-vision, invoked after user picks)

---

## Baseline Failure This Skill Fixes

Without this skill, builders either (a) build the first idea that comes to
mind without market validation, or (b) spend weeks "researching" without
a structured framework and never start building. Both fail.

This skill forces evidence-based opportunity selection: real products, real
revenue, real builder-specific advantages. It compresses what would take a
builder 2 weeks of unstructured research into a single structured session
that produces actionable, scored, comparable options.

The key insight: most builders don't fail at building. They fail at picking
what to build. This skill fixes the picking.
