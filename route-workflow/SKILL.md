---
name: route-workflow
description: >
  Know which svc skill to run next based on repo state, change type, and current
  project artifacts. Routes greenfield repos directly into the core pipeline and routes
  existing repos through onboard-repo first. Use when: "what should I do next",
  "which skill do I run", "what's the right order", "product workflow", "skill map",
  "where do I start", "what lane is this", "is this a feature or a bugfix", or when
  a skill finishes and its findings need a concrete next step.
inputs:
  required: []
  optional:
    - { path: "~/.claude/builder-profile.md", artifact: builder-profile }
outputs:
  produces: []
chain:
  lanes: {}
  progressive: false
  self_verify: false
  human_checkpoint: false
---

# Workflow Compass

Serious Vibe Coding now routes on two axes:

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

At the start of a pipeline run, do four things:

### 0. Mine the Builder Profile

Before deciding WHAT to build or HOW, understand WHO is building. The builder
profile captures the user's real-world context — financial situation, time,
skills, team, tools, business entity, and goals. This is project-agnostic
and reusable across everything they build.

**The interview happens ONCE.** After that, it's just a quick change-check.

**Check for existing profile:** `~/.claude/builder-profile.md` (global, persists
across projects). If it exists, read it and present a one-line summary:
"Builder profile: [role], [budget], [time], [key skill], [distribution].
Anything changed?" If the user says no → move on. If they mention changes →
update the specific sections.

**If no profile exists:** mine it as part of the first prompt flow.
- **In autorun mode:** interview is woven into the single prompt. The user's
  initial message often contains most of the signal ("I'm a devops guy with
  a 9-5, want to make side money"). Extract what you can, ask 2-3 critical
  unknowns, create the profile, and continue the pipeline — all in one flow.
- **In interactive mode:** ask one cluster at a time. Don't interrogate.
  Infer what you can from context.

**Subsequent sessions:** profile pops up only if something might have changed:
- New project started → "Anything changed since last time? New skills, tools, revenue?"
- 30+ days since last update → "Quick check: your profile says [X]. Still accurate?"
- User mentions something contradicting profile → update silently or confirm

**Create `~/.claude/builder-profile.md`:**

```markdown
# Builder Profile

Last updated: <date>

## Financial Context
- **Budget for this project:** <what they can invest: $0 / $100/mo / $5K seed / etc>
- **Income source:** <employed full-time / freelance / funded / savings>
- **Revenue pressure:** <need income ASAP / can wait 6 months / no pressure>
- **Payment infrastructure:** <no company yet / sole proprietor / LLC / can accept payments via X>
- **First revenue target:** <$100/mo to cover tools / $2K/mo to quit job / $10K MRR / etc>

## Time Context
- **Hours per week available:** <5 evenings / 20 part-time / 40+ full-time>
- **Employment status:** <9-5 employed / freelance flexible / full-time on this>
- **Deadline pressure:** <ship in 2 weeks / 3 months / no deadline>
- **Timezone/availability:** <when they work on this>

## Skills & Strengths
- **Technical:** <languages, frameworks, infra — what they can build themselves>
- **Non-technical:** <marketing, sales, design, copywriting, domain expertise>
- **Gaps:** <what they can't do — critical for team/tool recommendations>

## Team & Network
- **Solo or team:** <solo / co-founder (their skills) / contractor budget>
- **Network leverage:** <"I know a marketer" / "my friend does DevOps" / "I have 5K Twitter followers">
- **Advisor access:** <domain experts, mentors, potential customers they can reach>

## Distribution & Social Presence

**Capture EVERYTHING — even if it seems irrelevant to the current project.**
The builder profile is about the person, not the project. A 4-year-old Reddit
account with karma history is a trust asset even if the builder never plans
to post about this product there. An X Pro subscription is a paid tool that
enables long-form posts and analytics. 300 Twitter followers with zero replies
is a dormant channel — but the account exists and has history, which beats
creating one from scratch.

The pipeline decides what's useful per project. The builder just reports
what they have.

For each platform, capture these dimensions:

| Dimension | What to ask | Why it matters |
|---|---|---|
| **Account age** | "How old is your account?" | Older accounts have trust signals (Reddit karma aging, Twitter history). Platforms penalize new accounts. |
| **Follower/connection count** | Raw number | Reach ceiling. But meaningless without engagement. |
| **Engagement quality** | "Do people reply? DM you? Share your stuff?" | 300 followers with 0 replies = dead channel. 300 with 10 replies per post = warm niche audience. |
| **Niche/audience type** | "Who follows you? What do they care about?" | Tech devs vs marketers vs designers = different products you can sell to them. |
| **Posting frequency** | "How often do you post?" | Active = warm channel. Dormant = needs reactivation time before launch. |
| **Paid features** | "Any paid subscriptions? Pro, Premium, etc?" | X Pro = long posts + analytics. LinkedIn Premium = InMail. Reddit Premium = no ads, access to r/lounge. These are tools. |
| **Content history** | "What do you usually post about?" | Existing content = established authority in a topic. Pivoting topics costs trust. |
| **Conversion history** | "Have you ever sold anything to this audience?" | Proven conversion > theoretical reach. Even one sale proves the channel works. |

### Per-Platform Capture

- **Twitter/X:** handle, followers, engagement (replies per post), niche, account age, Pro/Premium?, content type, ever sold anything?
- **LinkedIn:** connections, industry, posting frequency, engagement (comments per post), Premium?
- **YouTube:** subscribers, avg views/mo, content type, monetized?
- **TikTok/Instagram:** followers, engagement rate, content type, Reels performance
- **Reddit:** account age, karma (post + comment separately), active subreddits, moderator of any?, posting history in niche subs
- **Newsletter/Blog:** subscriber count, open rate, click rate, platform (Substack/Beehiiv/Ghost/etc), paid tier?
- **Discord/Slack communities:** own a server (member count)? active member of relevant ones (which)?
- **GitHub:** followers, popular repos (stars), contribution history, profile README?
- **ProductHunt/IndieHackers:** past launches (rankings), karma, community engagement
- **Podcast:** own one (listener count)? guest appearances? reach?
- **Other:** forums, Hacker News karma, Stack Overflow rep, Dribbble, Behance, niche communities

### What the Pipeline Does With This

Distribution is the #1 predictor of whether a product succeeds. The pipeline
needs to know what channels already exist so it can:
- **Pre-validate** by posting to existing audience before building
- **Choose what to build** — pick products that match where the audience already is
- **Plan launch strategy** — organic distribution via existing channels vs cold start
- **Estimate time to first revenue** — existing audience = days; no audience = months
- **Identify dormant assets to reactivate** — a 4-year Reddit account in the right
  sub is a warm intro away from being a distribution channel

**Engagement > follower count.** 500 engaged niche followers who reply and DM
beats 50K passive followers. When mining, ask about replies, DMs, and
conversion (have they ever sold anything to this audience?).

**Account age and history matter independently of follower count.** Platforms
trust aged accounts. A 4-year Reddit account can post in subreddits that ban
new accounts. An 8-year Twitter account has algorithmic trust that a new
account takes months to build. Even if the account is dormant, the age is
an asset — note it.

**Paid subscriptions are tools.** X Pro, LinkedIn Premium, Reddit Premium,
YouTube channel membership — these unlock features (analytics, reach,
posting formats) that the pipeline should leverage rather than ignore.

## Existing Infrastructure
- **Subscriptions:** <list what they already pay for: Vercel, AWS free tier, Supabase, etc>
- **Free tiers available:** <what they haven't used yet but could>
- **Domains:** <owned domains>
- **Tools:** <IDE, design tools, analytics, etc>
- **Existing codebases:** <repos, templates, boilerplate they can reuse>

## Business Situation
- **Entity status:** <no company / sole proprietor / LLC / registered business>
- **Can accept payments:** <yes via Stripe / no, need Gumroad/Dodo/LemonSqueezy / not yet>
- **Tax/legal:** <any constraints — VAT threshold, jurisdiction, employment contract limitations>
- **Existing customers/audience:** <email list, users, community, nothing yet>

## Strategic Goal
- **Why building this:** <side income / replace job / startup / scale existing / learning>
- **Risk tolerance:** <conservative-first-project / moderate / aggressive-experienced-founder>
- **Success definition:** <$500/mo passive / 1000 users / raise seed round / prove concept>
- **Exit horizon:** <keep forever / flip in 2 years / build to raise>

## Project History

Past projects — shipped, abandoned, or failed. Each one is signal.

### <Project Name> — <outcome: shipped / abandoned / failed / ongoing>
- **What:** <one sentence — what was it?>
- **When:** <date range>
- **Stack:** <what was built with>
- **Reached:** <furthest milestone: idea / prototype / launched / revenue / scaled>
- **Revenue:** <peak revenue, if any>
- **Why it ended:** <honest reason — ran out of time? no users? couldn't do marketing? lost motivation? co-founder left?>
- **Reusable assets:** <code, infra, domain, learnings, customer list, anything salvageable>
- **What you'd do differently:** <the insight that only comes from having done it>

(Repeat for each past project. Even side projects and hackathon entries count.)

### How project history changes the pipeline

The pipeline reads ALL past projects and extracts patterns:

- **Repeated failure mode** → pipeline actively guards against it. If 2/3 past
  projects died because the builder couldn't do marketing, the pipeline will
  not recommend marketing-heavy strategies. It will pick products with built-in
  distribution (marketplace apps, integrations, SEO-driven tools).
- **Successful patterns** → pipeline leans into them. If the builder shipped a
  CLI tool successfully but failed at a SaaS, the pipeline biases toward CLI
  tools, VS Code extensions, or developer utilities.
- **Reusable assets** → pipeline checks if any past code, infra, domains, or
  customer relationships can be leveraged for the current project.
- **Time estimation** → if the builder consistently underestimates by 2x, the
  pipeline adds a multiplier to task estimates silently.
- **Motivation patterns** → if the builder abandons projects at month 3, the
  pipeline scopes MVPs to ship in 4-6 weeks, not 3 months.

## Builder Patterns (learned over time)

This section is EMPTY on first run. It gets populated by the pipeline as
projects are executed. After each project (shipped or abandoned), the
pipeline appends patterns here.

### Pattern format:
- **[pattern-id] <description>** — confidence: <1-10>, observed: <N> times
  Source: <which projects demonstrated this>
  Pipeline action: <what the pipeline does differently because of this>

### Example patterns (populated after real projects):
- **[timeline-2x] Estimates are 2x optimistic** — confidence: 8, observed: 3 times
  Source: Project A (est 2wk, took 5wk), Project B (est 1mo, took 2.5mo)
  Pipeline action: multiply all task estimates by 2x in plan-changeset
- **[frontend-stall] Stalls on frontend work** — confidence: 7, observed: 2 times
  Source: Project A (backend done in 3 days, frontend took 3 weeks), Project C (abandoned at UI phase)
  Pipeline action: recommend Tailwind + shadcn/ui, pre-built templates, or co-founder/contractor for frontend
- **[marketing-gap] Products get built but never launched** — confidence: 9, observed: 3 times
  Source: Project A (shipped, 0 users), Project B (shipped, told no one), Project C (shipped, "will market later")
  Pipeline action: require distribution plan BEFORE build starts, bake launch into the pipeline, not after
- **[solo-strength] Ships fast when scope is small + solo** — confidence: 8, observed: 2 times
  Source: Project D (CLI tool, shipped in 1 week, 500 users), Project E (API wrapper, shipped in 3 days)
  Pipeline action: bias toward small-scope solo projects, avoid team-dependent plans

## Tool & Capability Gap Analysis

Based on the builder's skills, tools, and project history, identify what's
MISSING that would unlock the next level. This isn't a shopping list — it's
a strategic assessment of where the ceiling is.

### Current capabilities (auto-derived from profile)
<filled in by the pipeline — maps skills + tools + subscriptions to capabilities>

### Gaps blocking next milestone
<filled in by the pipeline — what the builder can't do that the project needs>

### Recommendations
<filled in by the pipeline — specific tools, skills to learn, or people to find>

### Example gap analysis:
```
Current capabilities:
  ✓ Backend development (Node.js, Python)
  ✓ Infrastructure (AWS free tier, Vercel)
  ✓ Version control (GitHub)
  ✗ Frontend (no framework experience, stalls on UI)
  ✗ Marketing (no distribution, no copywriting)
  ✗ Design (no Figma, no design system)
  ✗ Payments (no entity, no Stripe)

Gaps blocking "$500/mo revenue" milestone:
  1. No payment processing → can't collect money
     FIX: LemonSqueezy (no entity needed, handles VAT) — $0 until first sale
  2. No frontend skills → can't build user-facing product
     FIX (pick one):
       a) Use v0.dev + shadcn/ui (AI-generated UI, minimal frontend skill needed)
       b) Build CLI/API tools instead (plays to backend strength)
       c) Find frontend co-founder (check network section)
  3. No distribution → product will ship to 0 users
     FIX (pick one):
       a) Build for a marketplace (VS Code, Shopify, Raycast — built-in distribution)
       b) Build SEO-driven tool (people Google for it)
       c) Reactivate dormant Reddit account (4yr old, has trust) — 3 week warmup
       d) Spend $50/mo on one ad channel to validate before scaling

Proactive tool recommendations:
  - LemonSqueezy ($0/mo until revenue) → unblocks payments without entity
  - v0.dev (free tier) → generates React components from prompts → unblocks frontend
  - Plausible Analytics ($9/mo) or Umami (free, self-hosted) → know if anyone visits
  - Resend (free tier, 3K emails/mo) → transactional + basic marketing email
```
```

**How to mine it:** Don't ask all sections as a form. Read what the user already
said — their prompt often reveals budget, skills, and urgency implicitly. Fill
in what you can infer, then ask about the 2-3 most impactful unknowns:

- If they mention a 9-5 job → time-constrained, income exists, probably needs side revenue
- If they mention "first project" → conservative strategy, no entity, free tiers
- If they mention a co-founder → capture their skills, affects what to build
- If they mention subscriptions → log them, affects tech choices
- If they say "I can invest $X" → budget ceiling, affects build-vs-buy
- If they mention any social handle → ask follower count + engagement + niche
- If they post content anywhere → that's a distribution channel, capture it
- If they have no social presence → flag it, plan for cold-start distribution

**The builder profile changes what the pipeline recommends:**

| Builder situation | Pipeline impact |
|---|---|
| No capital, first project, 9-5 job | Find validated business to undercut cheaply. Free tiers only. Dodo/Gumroad payments. Ship in weekends. Target: first $100/mo. |
| Some capital ($500/mo), has marketer friend | Leverage the marketer. Pick a niche where marketing > engineering. Modest paid tools OK. |
| Funded / has company / Stripe ready | Build the vision. Use best tools. Move fast. Paid infra OK from day 1. |
| Technical + non-technical co-founder | Split by strength. Technical builds, co-founder validates with customers. Affects persona creation. |
| Has existing audience (5K followers, email list) | Pre-validation via audience. Can ship smaller MVP because distribution exists. |
| Has company, can get new clients | Can build internal tools that become products. Can validate with existing clients. |
| Strong Twitter/X in dev niche (1K+ engaged) | Build dev tools, open-source with paid tier, or info products. Launch via threads + ProductHunt. Audience IS the validation — poll before building. |
| Twitter/X with followers but zero engagement | Dormant channel. Don't plan launch around it. But: account age + history = algorithmic trust. Reactivation plan: 2-3 weeks of posting before launch, not day-of. Factor reactivation time into timeline. |
| X Pro / Premium subscription | Long-form posts, analytics, creator tools. Use analytics to understand existing audience before building. Long posts = mini-blog without needing a blog. |
| Active newsletter (500+ subs, 40%+ open rate) | Newsletter audience is a pre-sold customer base. Build what they ask for. Waitlist = validation. |
| YouTube channel (1K+ subs) | Video-friendly products: tutorials→SaaS, course platforms, tools you can demo. Launch content is free. |
| Reddit with aged account (2+ years) + karma | Trust asset. Can post in gated subreddits. Build tools that solve problems repeated in those subs. Don't self-promote — solve the problem, mention the tool in context. Account age bypasses new-account restrictions that kill cold-start distribution. |
| Reddit with aged account but low/no karma | Account exists and is trusted by age. Needs karma building: 2-4 weeks of genuine participation in target subs before any product mention. Factor this into launch timeline. |
| GitHub presence (popular repos) | Open-source core → paid cloud/pro. Existing stargazers are early adopters. README is your landing page. |
| LinkedIn with industry connections | B2B distribution channel. If building for professionals in their industry, LinkedIn posts + DMs are the channel. Premium unlocks InMail for cold outreach. |
| No social presence at all | Cold start. Build for SEO (tools people Google for), marketplaces (Shopify apps, VS Code extensions), or communities where you can earn trust first. Budget 30-50% of time for distribution, not just building. |

**Revenue jump-in points (advise based on profile):**

| Revenue target | Approach | Timeline | Typical tools |
|---|---|---|---|
| $0 → $1K/mo | Reverse-engineer a winner. Ship in 1-2 weeks. Free-tier stack. Proven distribution channel. | Month 1 | LemonSqueezy, Supabase free, Vercel free |
| $1K → $3K/mo | Double down on what's working OR launch 2-3 variants. Register entity. | Month 2-3 | Sole proprietorship, Stripe, reinvest in tools |
| $3K → $10K/mo | Build the real thing (Stage 3). Use audience + revenue from Stage 1. Hire for weak skills. | Month 3-6 | Full infra, contractor budget, paid tools |
| $10K+ /mo | Product-market fit exists. Scale channels. Systematize. | Month 6+ | Full business infrastructure |

### Builder Profile Learning Loop

The profile isn't static. It gets smarter after every project. This happens
at two points:

**1. After verify-promotion (project shipped):**
Update the builder profile:
- Add project to Project History with outcome `shipped`
- Update skills (did they learn a new framework? use a new tool?)
- Update financial context (did revenue start? did they register an entity?)
- Update social presence (did they grow followers? launch on ProductHunt?)
- Run pattern detection: compare this project's timeline, decisions, and
  outcome against past projects. If a new pattern emerges (or an existing
  one is reinforced), append to Builder Patterns.
- Run gap analysis: what blocked them this time? What tool would have saved
  the most time? Append recommendation.

**2. After project abandonment:**
This is the MOST valuable update. Triggers:
- User explicitly says "I'm stopping this" / "abandoning" / "moving on"
- User starts a NEW project via `route-workflow` while a previous project has
  an unmerged feature branch (route-workflow detects this at Session Setup by
  checking `git worktree list` and `git branch --no-merged main`)
- User hasn't touched the project in 30+ days and starts a new session
  (route-workflow checks `git log -1 --format=%ci` at session start)

When triggered, ask:
- "What was the real reason you stopped?"
- Add project to history with outcome `abandoned` and honest reason
- Check: does this match a pattern? If 2+ projects died the same way, create
  or strengthen a Builder Pattern with high confidence.
- Check: was there a tool, skill, or person that could have prevented this?
  Update gap analysis.

**3. Proactively during pipeline (any skill):**
If the pipeline notices something that contradicts or updates the builder
profile, flag it:
- "Your profile says you can't do frontend, but you just wrote a React
  component. Should I update your skills?"
- "You said budget is $0 but you just signed up for a $20/mo service.
  Updated budget context."
- "Your X engagement jumped — you got 50 replies on your last post.
  Updating social presence from 'dormant' to 'warming up'."

```bash
# After any profile update, append a changelog entry:
echo "## Changelog" >> ~/.claude/builder-profile.md
echo "- $(date +%Y-%m-%d): <what changed and why>" >> ~/.claude/builder-profile.md
```

### 1. Create the Founder Persona (P0)

The virtual founder persona is your proxy throughout the pipeline. It steers
decisions, does research, and acts on your behalf.

**P0 now reads the builder profile.** Every decision P0 makes is informed by
the user's financial situation, time constraints, skills, and strategic goal.
P0 doesn't just decide WHAT — it decides what's REALISTIC given who is building.

**From the user's high-level input + builder profile, create `docs/specs/personas/P0-founder.md`:**

```markdown
# P0: Virtual Founder

## Vision Intent
<what the user said they want to build — their words, not interpreted>

## Builder Context
<summary of builder profile — what constrains/enables this project>
- Budget: <from profile>
- Time: <from profile>
- Skills: <from profile>
- Team: <from profile>
- Infrastructure: <key subscriptions/tools they already have>
- Business entity: <status>
- Strategic goal: <from profile>

## Decision Style
<extracted from how they communicate: terse → decisive; detailed → collaborative>

## Priorities (inferred from vision + builder context)
1. <what matters most based on what they emphasized AND what their situation demands>
2. <what they mentioned second>
3. <what they implied but didn't say>

## Constraints
<budget, timeline, team size, technical limitations — from builder profile + context>

## Strategy
<based on builder profile, what's the recommended approach?>
- Revenue model: <what makes sense given their entity status and revenue target>
- Payment processor: <what they can use given their situation>
- Tech stack bias: <free tiers vs paid tools, based on budget>
- Timeline: <realistic given their hours/week>
- First milestone: <what "shipped" means for this person>

## Research Directives
Before each key decision, P0 should:
- Search for real-world validation (demand signals, competitor moves, last 30 days)
- Check if free/open-source tools exist before building custom
- Look for production-verified patterns before inventing new ones
- Flag when there's not enough evidence to decide confidently
- Cross-reference against builder profile constraints before recommending
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

### Ambiguity Gate

After the forcing questions, score clarity across dimensions before proceeding.

**Scoring dimensions** (0.0-1.0 each):

| Dimension | What it measures | Weight |
|-----------|-----------------|--------|
| Goal Clarity | Can you state the primary objective in one sentence without qualifiers? | 0.3 |
| Constraint Clarity | Are boundaries, limitations, and non-goals clear? | 0.2 |
| Success Criteria | Could you write a test that verifies success? Are acceptance criteria concrete? | 0.3 |
| User Clarity | Do we know the specific human this serves and what they need? | 0.2 |

**Ambiguity score** = 1 - weighted average of dimension scores (as percentage).

**Threshold: 20% max ambiguity** (i.e., weighted clarity must be >= 0.8).

After each forcing question round, compute the score:

```
Ambiguity Dashboard:
| Dimension          | Score | Gap |
|--------------------|-------|-----|
| Goal Clarity       | 0.9   | — |
| Constraint Clarity | 0.6   | Timeline unclear |
| Success Criteria   | 0.8   | — |
| User Clarity       | 0.7   | Persona not validated |

Ambiguity: 26% (threshold: 20%)
Weakest: Constraint Clarity — targeting next question here
```

**Decision logic:**

- **Above threshold:** ask one more targeted question on the weakest dimension.
- **Below threshold:** proceed to session mode selection.

**Mode behavior:**

- **Auto mode:** P0 self-scores and researches to fill gaps (web search for validation).
- **Interactive mode:** present the dashboard and ask the user to clarify the weakest dimension.

**Max 8 rounds total** (forcing questions + ambiguity rounds combined). If still above threshold after 8 rounds: proceed with a warning noting which dimensions remain unclear.

#### Ontology Tracking

After each round, list the key entities (nouns) discussed. Track entity stability — when the entity list stops changing, the spec is converging.

```
Ontology: 7 entities | Stability: 5 stable, 1 new, 1 changed
Entities: User, Bookmark, Tag, Collection, Search, Import, Browser Extension
```

Entity states:
- **stable** — appeared in the previous round and has not changed meaning
- **new** — first appeared this round
- **changed** — appeared before but its scope or definition shifted this round

When all entities are stable for two consecutive rounds, the spec has converged and you can be confident the ambiguity score is reliable. If entities keep changing, the ambiguity score underestimates real confusion — keep asking.

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

## Find What to Build

When the user doesn't have a specific idea but has a goal — "I need money"
or "fastest path to revenue" or "what should I build?" — the pipeline
switches from evaluating ideas to GENERATING them.

When the user HAS an idea: "build my idea anyway" always works. The pipeline
does its best with whatever the user gives it. But it may ALSO suggest a
faster-money project alongside the main idea (see Staging Strategy below).

**Trigger phrases:** "what should I build", "find me a project", "fastest path
to revenue", "I want to make money", "first project", "help me pick", or any
variant where the user has a goal but not an idea.

**Requires:** builder profile (`~/.claude/builder-profile.md`). If it doesn't
exist, mine it first (Step 0). The profile IS the input — without knowing
who the builder is, the recommendations are generic and useless.

### The Bar

The target is NOT "$500/mo someday." The target is:

> **Almost guaranteed $1K/mo within 1 month of launch, with 1-2 weeks of
> build time.**

99% of builders with the right guidance can hit this. The system finds
opportunities where current market conditions make this realistic — not
speculative, not "if everything goes right." Products where similar things
are ALREADY making money and the builder can ship a competitive version
with their specific skills in 1-2 weeks.

### How It Works

```
Builder Profile → Market Scan → Reverse Engineer Winners → Match to Builder →
Score & Rank → Present Top 3 → User Picks → Pipeline Runs
```

### Step 1: Extract Builder Advantages

From the builder profile, list what this person can do BETTER or CHEAPER
than others:

```markdown
## Builder Advantages
- Can build: CLI tools, APIs, infrastructure, monitoring (devops strength)
- Can reach: r/selfhosted (28K members, 4yr account), r/sysadmin (500K members)
- Has: AWS free tier, Vercel, Supabase free tier, X Pro analytics
- Time: 10-15 hrs/week evenings → can ship in 1-2 weeks
- Unique angle: real sysadmin experience → knows real pain points
- Constraint: no frontend, no entity, $0 budget
```

### Step 2: Market Scan — What's Making Money RIGHT NOW

Don't guess what might work. Find what IS working and reverse-engineer it.

#### Product Categories to Scan

Scan across ALL categories — the best opportunity might not be in the
builder's obvious niche:

| Category | Examples | Typical revenue model | Time to build |
|---|---|---|---|
| **Chrome extensions** | Productivity, AI wrappers, page enhancers | Freemium ($5-15/mo) or one-time ($10-30) | 3-7 days |
| **Web apps (SaaS)** | Dashboards, tools, calculators, converters | Subscription ($9-49/mo) | 1-4 weeks |
| **Mobile apps** | Utilities, lifestyle, productivity | In-app purchase or subscription | 2-6 weeks |
| **API services** | Data APIs, AI wrappers, conversion tools | Pay-per-use or subscription | 3-10 days |
| **CLI tools** | Dev tools, automation, scripts | One-time ($20-50) or subscription | 1-2 weeks |
| **Templates/boilerplates** | Starter kits, themes, component packs | One-time ($29-99) | 1-2 weeks |
| **AI wrappers** | ChatGPT/Claude front-ends for specific use cases | Pay-per-use (user pays, covers API cost + margin) | 3-7 days |
| **Browser automation** | Scrapers, auto-fillers, monitoring bots | Subscription ($15-30/mo) | 1-2 weeks |
| **Marketplace apps** | Shopify apps, VS Code extensions, Raycast, Figma plugins | Marketplace cut or subscription | 1-3 weeks |
| **Info products** | Guides, courses, cheat sheets from domain expertise | One-time ($20-100) | 3-5 days |
| **Notification/alert services** | Monitoring, price alerts, stock alerts, keyword alerts | Subscription ($5-20/mo) | 1-2 weeks |

#### Reverse Engineering Successful Products

Search for products that are CURRENTLY making money in each relevant category:

| Source | What to search | What you learn |
|---|---|---|
| **IndieHackers revenue pages** | Filter by revenue range ($1K-$10K MRR), solo founder | What solo builders actually earn, what categories work |
| **ProductHunt recent launches** | Last 90 days, 100+ upvotes, in builder's niche | What's getting traction now, not 2 years ago |
| **Chrome Web Store** | "Recently updated" + builder's niche keywords | What extensions exist, user counts, review complaints |
| **App Store / Play Store** | Top free/paid in utility/productivity categories | Mobile gaps, pricing patterns |
| **GitHub trending** | Past month, builder's languages | What developers want, star velocity |
| **Gumroad/LemonSqueezy discover** | Top sellers in builder's niche | Price points, sales volumes |
| **Reddit builder's subs** | "I built", "I made", "alternative to", "is there a" | What people built AND what people wish existed |
| **X/Twitter** | "launched", "just shipped", "MRR" in builder's niche | Real-time launch signals |
| **last30days (if installed)** | Builder's niche + "tool", "app", "alternative" | 30-day trend signals |

**The process:**
1. Find 10-20 products making $1K+/mo in categories the builder can execute
2. For each: what's their weakness? Bad UX? Missing feature? Overpriced? Narrow niche they're ignoring?
3. Can the builder build a version that's better on ONE dimension in 1-2 weeks?
4. Does the builder have distribution to reach the same audience?

#### Self-Sustaining Infrastructure

**Mandatory:** every recommendation must use infrastructure that starts free
and scales with revenue. The project must self-sustain from day 1.

| Layer | Free tier pick | Scales to | When to pay |
|---|---|---|---|
| **Database** | Supabase (500MB, 50K rows) | Supabase Pro ($25/mo at ~$500 revenue) | Revenue covers it |
| **Hosting** | Vercel (100GB bandwidth) | Vercel Pro ($20/mo) | Revenue covers it |
| **Auth** | Supabase Auth (50K MAU) or Clerk (10K MAU) | Same platform Pro tier | Revenue covers it |
| **Storage** | Supabase Storage (1GB) or Cloudflare R2 (10GB) | Pay as you grow | Revenue covers it |
| **Email** | Resend (3K/mo) or Loops (1K contacts) | Resend $20/mo | Revenue covers it |
| **Payments** | LemonSqueezy (5% + 50¢) or Gumroad (10%) | LemonSqueezy or Stripe when entity exists | From first sale |
| **Analytics** | Plausible (free trial) or Umami (self-hosted free) | Plausible $9/mo | Revenue covers it |
| **AI (if wrapper)** | OpenAI / Anthropic API (user-funded) | Scales linearly with users | Users pay per use |
| **Mobile** | Expo + EAS (30 builds/mo free) | EAS $99/mo | Revenue covers it |

**The rule:** $0 out of pocket until revenue exceeds infra cost. Every cost
is covered by revenue before it's incurred.

### Step 3: Score & Rank

For each opportunity found, score on 6 dimensions:

| Dimension | Weight | What it measures |
|---|---|---|
| **Guaranteed revenue** | 30% | Is there PROOF similar products make $1K+/mo? Not "could" — "does." |
| **Builder fit** | 25% | Can THIS builder ship this in 1-2 weeks with their skills? |
| **Distribution fit** | 20% | Can THIS builder reach paying users through existing channels? |
| **Speed to first $** | 15% | Days from "start building" to first payment received |
| **Self-sustaining** | 5% | Does free-tier infra cover it until revenue scales? |
| **Ecosystem value** | 5% | Does this contribute to the builder's larger goal? |

**Disqualifiers (auto-reject regardless of score):**
- Requires skills the builder failed at before (hard veto)
- Takes > 2 weeks to build at builder's pace
- No evidence of anyone paying for similar products
- Requires business entity the builder doesn't have
- Requires upfront capital the builder doesn't have

### Step 4: Present Top 3

Present the top 3 opportunities, each with:

```markdown
## Opportunity 1: <name>
**Category:** <Chrome extension / web app / API / CLI / mobile / template / etc>
**What:** <one sentence>
**Reverse-engineered from:** <specific successful product + its weakness you exploit>
**Evidence:** <who's paying for similar things — specific revenue data, app store rankings, etc>
**Why you:** <specific builder advantages that make this winnable>
**MVP:** <exactly what to build in week 1 — no more>
**Revenue model:** <how money flows>
**Price point:** <specific price, based on what competitors charge>
**Payment method:** <what works given builder's entity status>
**Infra stack:** <all free tier — Supabase + Vercel + LemonSqueezy etc>
**Build time:** <days, not weeks — at builder's hours/week>
**Distribution plan:** <how to get first 20 paying users — specific channels>
**Month 1 revenue estimate:** <conservative based on evidence>
**Revenue ceiling:** <where this tops out>
**Ecosystem value:** <does this feed the builder's bigger idea? how?>
**Risk:** <what could go wrong>
**Score:** <total / 100>
```

### Step 5: User Picks → Pipeline Runs

When the user picks an opportunity:
1. Use the opportunity as the input to `write-vision`
2. The vision incorporates the builder profile constraints + infra choices
3. `validate-feature` runs with the opportunity's evidence pre-loaded
4. The full pipeline runs from there

**If user says "none of these":** ask what's wrong. Rescan with adjusted criteria.
**If user says "just pick the best one":** P0 picks #1, logs as taste decision, runs the pipeline.
**If user says "build my idea anyway":** respect it. Run the pipeline on their
idea. But see Staging Strategy below.

### AI Wrapper / Pay-Per-Use Model

Special attention to AI wrappers — they're the fastest path to revenue for
many builders right now:

**The model:** user pays $X per use → you take margin → API cost is covered
by the user. You never pay out of pocket for API costs.

**When to recommend wrappers:**
- Builder can code an API integration (most can)
- There's a specific use case where a general chatbot is 10x worse than a
  purpose-built interface (e.g., "AI that writes Shopify product descriptions"
  vs "ask ChatGPT to write product descriptions")
- The niche is specific enough that SEO or community distribution works

**Launch multiple?** If the builder's skills allow it and each wrapper takes
3-5 days, launching 3 wrappers simultaneously is a valid strategy. Different
niches, same tech stack, shared infra. If one hits, double down. If none
hit in 30 days, pivot.

### Staging Strategy

When the user has a BIG idea (their real vision) but needs money first:

**Stage 1: Revenue project (1-2 weeks)**
Build something that generates $1K/mo fast. This can be:
- **Related to the big idea** (best case) — a small tool in the same space
  that earns money AND builds audience AND teaches the domain. Example: big
  idea is "full monitoring platform" → Stage 1 is "uptime checker Chrome
  extension" that builds an audience of the exact users who'll want the
  platform later.
- **Tangentially related** — same target audience, different product. Builds
  distribution for the big idea. Example: big idea is "AI code review tool"
  → Stage 1 is "VS Code extension that formats error messages" — same
  audience (developers), earns money, builds install base.
- **Totally unrelated** (last resort) — pure revenue play. Doesn't feed the
  big idea but funds it. Example: AI wrapper for real estate listings while
  the big idea is a developer tool.

**Stage 2: Reinvest (month 2-3)**
Revenue from Stage 1 funds:
- Better tools (Claude Max, paid infra, design tools)
- Business entity registration
- Stripe setup
- Maybe a contractor for weak skills (frontend, design)

**Stage 3: The real thing (month 3+)**
Now build the big idea with:
- Revenue covering costs
- Audience from Stage 1 (if related)
- Better tools from Stage 2
- Proven builder confidence from shipping Stage 1

**Pipeline behavior when staging:**

When the user provides an idea AND the builder profile shows no capital:
1. Evaluate the idea normally (validate-feature with kill signals)
2. If the idea is NOT a fast-money play (takes > 2 weeks, no proven revenue model):
   - Present: "Your idea is solid but it's a 2-month build with no revenue
     until launch. Here's a staging plan:"
   - Propose a Stage 1 project that feeds into the big idea
   - User chooses: Stage 1 first → big idea later, or "build my idea anyway"
3. If the idea IS a fast-money play: just build it
4. "Build my idea anyway" is ALWAYS available — no gatekeeping

### First Project Rules

When the builder profile shows first project or no capital:

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
$0 → ship in 1-2 weeks → first paying user → $1K/mo month 1 →
register entity → Stripe → reinvest → build the real thing
```

The pipeline optimizes for wherever the builder IS in this chain.

## Autorun Orchestrator

When `--autorun` is set (or user says "just build it"), route-workflow
runs the entire lane from a single prompt to a verified product.

### One Prompt to Product

The goal: a single high-level intent ("build me X") produces a verified,
merged, working product — or a structured rejection explaining why not.

The pipeline runs end-to-end. Human checkpoints become P0-decided unless
the user explicitly opts into interactive mode. The only hard stops are:

- **NO-SHIP decision** in validate-feature (killing a feature is always surfaced)
- **Test failure** that P0 cannot resolve after 3 attempts
- **Security finding** at critical/high severity
- **Merge conflict** on promotion to main
- **Team mode PR** — branch protection or required reviewers means land-changeset
  opens a PR and stops. The chain resumes in a future session after merge.

Everything else — spec approval, plan review, solution selection, landing
strategy — P0 decides and logs for end-of-run review.

### Human Checkpoint Behavior in Autorun

Skills with `human_checkpoint: true` behave differently based on mode:

| Skill | Interactive mode | Autorun mode |
|-------|-----------------|-------------|
| `validate-feature` | Stop, ask user | P0 decides. **Exception:** NO-SHIP always stops. |
| `write-spec` | Stop, ask user to review spec | P0 reviews, logs concerns as Taste decisions |
| `explore-solutions` | Stop, present alternatives | P0 selects based on research, logs reasoning |
| `plan-changeset` | Stop, ask user to approve plan | P0 approves if plan covers all ACs; logs plan summary |
| `execute-changeset` | Stop at each task checkpoint | P0 reviews diffs, approves if tests pass |
| `land-changeset` | Stop, ask user to merge | P0 merges (solo mode) or opens PR and stops (team mode) |

**Team mode exception:** if the repo has branch protection or required
reviewers, `land-changeset` opens a PR and stops. The chain resumes when
the PR is merged (in a future session or via webhook).

### Pipeline Decision Log

Every decision, interaction, and question/answer is logged to
`docs/logs/pipeline-decisions.jsonl` (append-only) in ALL modes — standalone,
progressive, and autorun. This is the audit trail — it records what was
decided, why, who decided (P0 vs user), and what alternatives were considered.

**Every skill MUST append to this file** when it makes or receives a decision.
The log captures the full conversation between the model, P0, the user, and
review gates.

#### JSONL Schema

Each line is one decision event:

```json
{
  "timestamp": "2026-04-05T14:32:01Z",
  "run_id": "<git-short-hash-of-first-commit-in-run>",
  "skill": "validate-feature",
  "phase": 4,
  "type": "taste",
  "decision": "MVP includes delete and open commands, not just add/search/list/export",
  "reasoning": "Delete and open are table-stakes for any bookmark manager. Excluding them would feel incomplete.",
  "alternatives": ["Defer delete/open to v2", "Include only delete, not open"],
  "decided_by": "P0",
  "evidence": "buku and nb both ship delete on day 1",
  "overrideable": true
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `timestamp` | yes | ISO 8601 timestamp |
| `run_id` | yes | Short hash of the run's first commit (ties decisions to a pipeline run) |
| `skill` | yes | Which skill produced this decision |
| `phase` | yes | Pipeline phase number |
| `type` | yes | `mechanical` / `taste` / `user` / `question` / `answer` / `no-ship` / `gate-result` |
| `decision` | yes | What was decided or asked |
| `reasoning` | yes | Why — the specific logic |
| `alternatives` | no | Other options that were considered |
| `decided_by` | yes | `P0` / `user` / `review-gate` / `cross-model` |
| `evidence` | no | Data or research that informed this |
| `overrideable` | yes | Can the user override this at end-of-run? |

#### Event Types

| Type | When to log |
|------|-------------|
| `mechanical` | Clear-answer decision (logged silently, still recorded) |
| `taste` | Close-call decision — P0 picked one of N viable options |
| `user` | Decision that stopped the pipeline for user input |
| `question` | P0 or skill asked the user something (interactive mode) |
| `answer` | User responded to a question |
| `no-ship` | validate-feature killed a feature |
| `gate-result` | review-gate returned PASS/FAIL/ESCALATE |

#### When to Write

- **Start of each skill:** log a `mechanical` entry with `"decision": "Starting <skill>"` 
- **At every decision point:** log the decision before acting on it
- **At every user interaction:** log the question, then the answer as separate entries
- **At gate results:** log PASS/FAIL/ESCALATE with the findings summary
- **At NO-SHIP:** log with the kill signal count and top evidence

#### How to Write

Append one JSON line per decision:

```bash
echo '{"timestamp":"...","run_id":"...","skill":"...","phase":N,"type":"...","decision":"...","reasoning":"...","decided_by":"...","overrideable":true}' >> docs/logs/pipeline-decisions.jsonl
```

Create `docs/logs/` if it doesn't exist. Never overwrite — append only.

#### End-of-Run Summary

At pipeline completion (or when the user asks "what happened?"), read the log
and present decisions grouped by type:

```
Pipeline Run: <run_id>
Skills executed: 8 | Decisions logged: 24

Mechanical (14): [silently decided — available in log]
Taste (10):
  1. [skill] decision — reasoning (override? yes)
  2. ...
User (0): [none — all checkpoints were P0-decided]
```

The user can override any `taste` decision by saying "override decision N"
and providing their preference. The skill that produced the decision is
re-invoked with the override.

### Decision Classification

1. **Classify every decision** as:
   - **Mechanical** — clear best answer, decide silently (e.g., file naming)
   - **Taste** — close call, P0 decides but logs it for end-of-run review
   - **User** — high stakes or irreversible, stop and ask even in auto mode

2. **Run skills through the lane**, P0 steering each one.
   **Parallel where independent** — skills with zero data dependencies
   run as concurrent subagents:

   | Parallel group | Skills | Why parallel |
   |----------------|--------|-------------|
   | Market research | `analyze-domain` + `analyze-competitors` | Both read vision.md, produce independent outputs |

   Dispatch both via Agent tool in a single message, wait for both to
   complete, then continue to the next sequential skill (`build-personas`).

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
| NO-SHIP kill decision | User | Always surfaced, never silent |

## Repository Mode Gate

Before recommending any next skill, detect repository mode using `REPO_MODES.md`:

- `bootstrap`: initialize missing svc structure and run the greenfield lane
- `convert`: preserve current truth first, then route to the right brownfield lane

If mode is ambiguous, default to `convert`.

## Routing Rule

**Clean repo:** run svc directly.

**Existing repo:** run `onboard-repo` first unless the repo has already been mapped into svc working mode.

Signals that conversion has already happened:

- `docs/specs/project-state.md` exists
- `docs/specs/work-items/INDEX.md` exists
- the repo already uses lane-based work items and canonical svc status files

If these are missing in a real brownfield repo, route to `onboard-repo`.

## Skill Availability Contract

`route-workflow` must always route to available skills first.
Skill-name contract is machine-checked in `skills-manifest.json` via `node scripts/lint-skills-manifest.mjs`.

### Core Pack (always available in svc)

- `write-vision`
- `analyze-domain`
- `analyze-competitors`
- `build-personas`
- `write-journeys`
- `test-journeys`
- `validate-feature`
- `audit-ac`
- `sync-spec-code`
- `define-code-style`
- `write-e2e`
- `analyze-marketing`
- `route-workflow`
- `onboard-repo`
- `diagnose-bug`
- `sync-work-items`
- `discover-skills`
- `research`
- `execute-changeset`
- `mine-builder`
- `find-opportunity`
- `stage-revenue`

### External Add-On Packs (optional)

Only route to external skills when explicitly installed or confirmed.

- **coreyhaines-marketing-pack (optional):**
  `product-marketing-context`, `customer-research`, `market-competitors`, `competitor-alternatives`,
  `copywriting`, `page-cro`, `launch-strategy`, `market-social`,
  `market-ads`, `market-emails`, `signup-flow-cro`, `onboarding-cro`

- **planning add-on (optional):**
  `writing-plans` (external add-on; for svc repos, use core `plan-changeset` unless the repo explicitly prefers an external planning flow)

If an external skill is not confirmed, provide a core-pack fallback route.
External pack definitions live in `EXTERNAL_ADDONS.md`.

## The Routing Skills

### `onboard-repo`
Maps a brownfield repo into svc working mode. Produces `project-state.md`,
repo-canonical work items, and compatibility notes. Logs findings, then stops.

### `diagnose-bug`
Root-cause-first bug and regression planning. Produces an implementation-ready
correction brief without forcing a full feature-spec rewrite.

### `sync-work-items`
Projects repo-canonical work items to GitHub Issues. GitHub is a projection, not
the source of truth.

## The Product Pipeline Skills

- `write-vision`
- `build-personas`
- `validate-feature`
- `write-spec`
- `design-ux`
- `design-ui`
- `design-tech`
- `plan-changeset`
- `execute-changeset`
- `review-gate`
- `land-changeset`
- `verify-promotion`
- `write-journeys`
- `audit-ac`
- `sync-spec-code`
- `test-journeys`
- `write-e2e`
- `analyze-marketing`

## Lane Model

### Lane 1: Greenfield Feature

Use when:
- mode = `bootstrap`
- the repo is clean or effectively clean
- behavior is still being discovered

Route:
1. `write-vision`
2. `build-personas`
3. `validate-feature`
4. `write-spec`
5. `audit-ac`
6. `write-journeys`
7. `design-ux`
8. `design-ui`
9. `design-tech`
10. `plan-changeset`
11. `execute-changeset`
12. `review-gate`
13. `land-changeset`
14. `verify-promotion`

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
- the repo has not yet been mapped into svc working mode

Route:
1. `onboard-repo`
2. `sync-work-items` if the team wants GitHub visibility
3. route each resulting item by type

### Lane 3: Brownfield Feature Extension

Use when:
- mode = `convert`
- the repo is already mapped
- the item type is `feature`

Route:
1. `sync-spec-code`
2. `validate-feature`
3. `write-spec` in delta mode
4. `write-journeys` in expand mode
5. `design-tech` if architecture changes
6. `plan-changeset`
7. `execute-changeset`
8. `review-gate`
9. `land-changeset`
10. `verify-promotion`

### Lane 4: Bugfix / Regression

Use when:
- item type is `bugfix` or `regression`
- behavior is wrong, broken, or changed unexpectedly

Route:
1. `diagnose-bug`
2. `plan-changeset` if a formal implementation plan is needed
3. `execute-changeset`
4. `review-gate`
5. `land-changeset`
6. `verify-promotion`
7. `test-journeys` or `write-e2e` as targeted support when the verification path needs direct runtime evidence

### Lane 5: Drift / Maintenance

Use when:
- item type is `drift`
- specs, journeys, and code disagree

Route:
1. `sync-spec-code`
2. selective spec or code remediation
3. `write-journeys` refresh if user flows changed
4. `sync-work-items` if tracker visibility matters

### Lane 6: Refactor / Chore

Use when:
- item type is `refactor` or `chore`
- behavior should stay materially the same, or the work is primarily structural/state-management

Route:
1. `sync-spec-code` if behavior invariants or current truth are unclear
2. `plan-changeset`
3. `execute-changeset`
4. `review-gate`
5. `land-changeset`
6. `verify-promotion` when the change touches shipped behavior, tests, or user journeys
7. `sync-work-items` if tracker visibility matters

## Change-Type Detection

Use these signals:

| Signal | Change Type | First Skill |
|--------|-------------|-------------|
| Existing repo needs svc adoption | `conversion` | `onboard-repo` |
| Net-new capability or extension with user value | `feature` | `validate-feature` |
| Broken behavior | `bugfix` | `diagnose-bug` |
| Previously working behavior stopped working | `regression` | `diagnose-bug` |
| Spec/code mismatch | `drift` | `sync-spec-code` |
| Structural cleanup with no intended behavior change | `refactor` | `plan-changeset` (or `sync-spec-code` first if invariants are unclear) |
| Tracker, docs, or housekeeping item | `chore` | `sync-work-items` or `plan-changeset`, depending on whether it changes code or project state |

## Cross-Skill Routing

| Skill just finished | Finding | Route to |
|--------------------|---------|----------|
| `onboard-repo` | Brownfield map completed | route by work-item type |
| `onboard-repo` | Bugs/regressions logged | `diagnose-bug` |
| `onboard-repo` | Feature opportunities logged | `validate-feature` |
| `onboard-repo` | Drift logged | `sync-spec-code` |
| `onboard-repo` | Refactors or chores logged | `plan-changeset` or `sync-work-items`, depending on scope |
| `onboard-repo` | Tracker visibility needed | `sync-work-items` |
| `diagnose-bug` | Root cause and fix scope defined | `plan-changeset` or `execute-changeset`, depending on plan depth needed |
| `plan-changeset` | Implementation manifest complete | `execute-changeset` |
| `execute-changeset` | Task execution complete, final diff reviewed | `land-changeset` |
| `execute-changeset` | Task reveals spec/UX/UI/tech contradiction | loop back to the relevant upstream skill |
| `diagnose-bug` | Issue is actually missing capability | `validate-feature` |
| `diagnose-bug` | Issue is actually spec drift | `sync-spec-code` |
| `sync-spec-code` | Drift confirmed | remediation path or work-item update |
| `sync-spec-code` | Structural cleanup with behavior preserved | `plan-changeset` |
| `validate-feature` | Not a new feature, but a broken existing flow | `diagnose-bug` |
| `validate-feature` | Existing repo not yet mapped | `onboard-repo` |
| `write-journeys` | Missing producer, missing persona, or fragmented concept | `validate-feature` or `build-personas` |
| `test-journeys` | Runtime failure in known behavior | `diagnose-bug` |
| `test-journeys` | Vague or missing ACs | `audit-ac` |
| `analyze-marketing` | Product context stale after spec changes | `sync-spec-code` then refresh marketing |

## Project State Checks

Before recommending a lane, inspect:

```bash
# Foundational svc state
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
| Clean repo, little established structure | Greenfield | `write-vision` or `route-workflow` lane recommendation |
| Existing repo, no svc state files | Brownfield unmapped | `onboard-repo` |
| Existing repo, mapped, feature request | Brownfield feature lane | `sync-spec-code` then `validate-feature` |
| Existing repo, mapped, bug or regression | Correction lane | `diagnose-bug` |
| Existing repo, mapped, doc/code mismatch | Drift lane | `sync-spec-code` |
| Work items exist, no external visibility | Tracker projection gap | `sync-work-items` |

## Recommendation Style

When answering "what should I do next?", give:

1. detected repo mode
2. detected change type
3. selected lane
4. immediate next skill
5. why that route is correct

Example:

> Repo mode: convert. Change type: regression. This repo is already mapped, so do not rerun conversion. Use the bugfix lane. Next skill: `diagnose-bug`, because the immediate problem is correcting broken behavior, not authoring a new feature.
