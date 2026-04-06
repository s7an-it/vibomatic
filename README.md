# Serious Vibe Coding

> **Serious Series: Serious Vibe Coding**
>
> Progressive Deterministic Development — a methodology for reliable agentic software engineering

Named after Saitama's *[Serious Punch](https://onepunchman.fandom.com/wiki/Serious_Series)*
from One Punch Man. Everyone else throws everything they've got. Saitama
doesn't even try — then he does, and it's over in one hit.

Same energy. Everyone else vibe-codes their way through and hopes the agent
figures it out. You run the same prompt — but behind it are 18 phases of
progressive narrowing, adversarial reviews, and deterministic promotion.
The code actually works. First try.

Vibe coding, but the vibe is engineering rigor.

## Why This Exists

Three pain points from years of vibe coding:

1. **Unpredictability.** Same prompt, different output every run. No
   deterministic path from intent to working code.
2. **No end-to-end automation.** Most frameworks stop at code generation.
   Nobody closes the loop from high-level intent through spec, design,
   implementation, testing, and verified delivery.
3. **No rejection path.** Agents always say yes and produce *something*.
   There is no honest "this won't work, here's what might" path.

The idea: you give a high-level intent — a product idea or a feature within
an existing product — and the system either **delivers it** through
progressive narrowing, or **rejects it with evidence and proposes
alternatives** that you can accept or reject.

**It starts with you, not the product.** Before building anything, the
pipeline mines your builder profile — financial situation, time budget,
skills, team, social presence, existing subscriptions, business entity
status, and strategic goal. A broke developer working evenings gets
different recommendations than a funded founder with a marketer co-founder.
The profile persists across projects and gets smarter after each one.

**Don't know what to build? The pipeline finds it.** If your goal is
"I need money" but you don't have an idea, say so. The system reverse-
engineers what's making money RIGHT NOW, matches it to your skills and
distribution channels, and presents the top 3 opportunities — each with
evidence of existing revenue, a 1-2 week build plan, and a self-sustaining
free-tier stack. Target: $1K/mo within 1 month of launch. If you have a
big idea but need money first, the system proposes a staging plan — a
fast-money project (ideally feeding your big idea) before the main build.
"Build my idea anyway" always works.

**One prompt to product.** In `--autorun` mode, a single high-level intent
(or a selected opportunity) runs the full pipeline end-to-end. The virtual
founder (P0) makes taste decisions informed by your builder profile and
logs them for review. The only hard stops are: feature rejection (NO-SHIP),
unresolvable test failures, critical security findings, and merge
conflicts. Everything else flows.

**Designed for Claude Max plan** — up to ~100 Claude Code instances working
in parallel across features and tasks, coordinated through git worktrees
and a four-layer token cache that maximizes prompt cache hits across
subagents.

### What's Built vs. What's Next

| Capability | Status |
|---|---|
| Builder profile mining | Built — financial, time, skills, team, social/distribution, tools, entity, goals, project history, failure patterns; updates after every project; persists globally |
| Find what to build | Built — reverse-engineers current market winners, matches to builder skills/distribution, 1-2 week builds on free-tier infra, staging strategy for big ideas, $1K/mo target within month 1 |
| Progressive narrowing (vision → verified merge) | Built — 18 phases, 7 review gates |
| One prompt to product (`--autorun`) | Built — P0 decides at human checkpoints; only hard stops are NO-SHIP, test failure, security, merge conflict |
| Reject/pivot on infeasible intent | Built — 7 kill signals with evidence scoring; NO-SHIP produces structured rejection + alternative directions |
| Pipeline decision log | Built — every decision, interaction, and gate result logged to `docs/logs/pipeline-decisions.jsonl` |
| Worktree isolation per feature | Built — `worktree.sh` with guard, create, promote, cleanup |
| Subagent dispatch for parallel tasks | Specified — prompt protocol in execute-changeset; relies on LLM following instructions, no runtime orchestrator |
| Multi-agent coordination (~100 instances) | Architecture supports it — worktree isolation + token cache layers; no scheduler or lock layer yet |

## Origin Story

I had my own methodology — fully testable specs, every acceptance criterion
covered by E2E tests, progressive narrowing from vision to verified code. The
soul of the approach was already there.

Then I started using other people's incredible work:
[gstack](https://github.com/garrytan/gstack) (Garry Tan),
[superpowers](https://github.com/obra/superpowers) (Jesse Vincent),
[Oh My Claude Code](https://github.com/yeachan-heo/oh-my-claudecode) (Yeachan Heo),
and [claude-code-setup](https://github.com/petekp/claude-code-setup) (Pete Petrash).
Each one solved problems the others didn't. None of them combined into a single
streamlined flow.

So I built this — an opinionated blend of how I actually work. The best patterns
from each project, wired into one pipeline. The goal is that one day these
patterns can be ported back to help each project solve specific weaknesses,
while giving me (and anyone else who wants it) a single coherent experience
right now.

This is MIT-licensed. Fork it, break it apart, take what's useful, contribute
what's missing. If you find ways to make the pipeline faster or the specs
tighter, PRs are open.

## The Problem

Large language models generate code through pattern matching. Given a spec,
an LLM produces different implementations on different runs — different
abstractions, different edge cases, different integration patterns. Each one
is confidently presented as correct. This is not a bug. It is how these
systems work.

Every methodology that goes from ticket to code, from spec to implementation,
from design to "let the agent figure it out" is accepting non-determinism as
a feature. Most of the time it works. Sometimes it doesn't. You find out in
QA, or in production, or when two agents implemented the same feature
differently in parallel branches.

Serious Vibe Coding rejects that.

## The Solution: Progressive Narrowing

Each phase constrains the space of possible outputs for the next phase. By the
time code is written, the implementation surface is tightly constrained — not by
pattern matching alone, but by the accumulated constraints from every prior phase.

```
Phase 1:  Vision              → infinite possibilities
Phase 2:  Personas            → narrows WHO
Phase 3:  Feature Spec        → narrows WHAT (stories, acceptance criteria)
Phase 4:  UX Design           → narrows HOW users experience it
Phase 5:  UI Design           → narrows HOW it looks
Phase 6:  Technical Design    → narrows HOW to build it
Phase 7:  Implementation      → narrows to ONE reviewed branch outcome
Phase 8:  Promotion           → squash-merges the worktree to main
Phase 9:  Verification        → proves the merge matches the manifest
```

At Phase 1, the agent is generating. By Phase 7, the agent is executing against
a constrained implementation plan inside a worktree branched from main. The
creative work happens in Phases 1-6 and in any explicit loop-backs. Phase 7 is
controlled execution with task reviews and checkpoints. Phase 8 is a squash
merge. Phase 9 is checking.

## Why This Works (Technical Argument)

An LLM's output variance is inversely proportional to the constraints in its
context window. More context = less variance. The progressive narrowing model
exploits this:

1. **Context loading.** Each phase reads ALL prior artifacts. The agent writing
   the change set has read the vision, personas, spec, UX design, UI design,
   technical design, journeys, and existing code. Every constraint is in context.

2. **Variance reduction.** A one-line ticket produces 50 implementations.
   A spec with 12 acceptance criteria produces 5. A detailed implementation
   manifest with explicit tasks, files, validations, and checkpoints reduces
   the remaining variance to a small, reviewable branch diff.

3. **Review before generation.** Traditional: agent generates code, human
   reviews code. Serious Vibe Coding: human reviews intent (spec, design, plan),
   then the agent executes that intent task by task on a branch. Reviewing
   intent early is cheaper than reviewing a fully improvised implementation late.

4. **Deterministic promotion.** The worktree IS the code. Promotion is
   `git merge --squash` to main. Deviations are detected by diffing the
   merged result against the manifest. Nothing is left to interpretation.

5. **Attention decay mitigation.** LLMs suffer from positional attention
   decay — tokens loaded early in context receive less attention during
   generation. Checkpoints (commits at each phase boundary) reset this by
   forcing the agent to re-read artifacts fresh. The worktree keeps all
   artifacts consistent and accessible as the agent's external memory.

## The Review Protocol

Every phase transition is gated by a structured review designed around LLM
failure modes:

```
Step 1: SELF-REVIEW      → agent reviews own work, produces findings
Step 2: SELF-JUDGMENT     → agent accepts/rejects own findings with reasoning
Step 3: CROSS-REVIEW      → second agent independently evaluates
Step 4: CONVERGENCE       → medium/low only = PASS; critical/high = fix; 3 iterations = escalate
```

This catches: agents missing own errors (Step 3), agents agreeing too easily
(Step 2 forces adversarial self-reasoning), review theater (severity classification
+ convergence criteria), infinite loops (3-iteration cap).

## Local-First, Mock-by-Default, Feature-Toggleable

The first iteration of anything you build with svc is demoable, stunning, and
runs locally with zero credentials. Every external dependency (payments, email,
storage, auth) ships with two implementations:

- **Mock** — ON by default. Works locally, returns realistic data, exercises
  the full acceptance criteria. This is what demos and E2E tests run against.
- **Real** — OFF by default. Behind a feature toggle. Enabled per-environment
  when ready (staging → production).

This is enforced at every phase: specs require mock strategies for all
integrations (G1), tech design defines the toggle architecture (G4), and
execution must pass a first-demo test locally with zero network access (G5).

Full convention: [`references/feature-toggles.md`](references/feature-toggles.md)

## The Pipeline

### Foundational Artifacts (created once, evolved)

| Artifact | Skill | Purpose |
|----------|-------|---------|
| Vision | `write-vision` | Product direction, boundaries, principles |
| Domain Profile | `analyze-domain` | Industry, tech stack, domain reference packs |
| Competitor Analysis | `analyze-competitors` | Competitive landscape, whitespace, differentiation |
| Personas | `build-personas` | Who uses this (human and system consumers) |
| Design System | `design-ui` | Visual language: tokens, typography, colors, spacing |

### Builder Profile (created once, evolves)

| Artifact | Location | Purpose |
|----------|----------|---------|
| Builder Profile | `~/.claude/builder-profile.md` | Who is building: finances, time, skills, team, social presence, tools, entity, goals, project history, learned patterns. Persists across all projects and gets smarter after each one. |

### Per-Feature Pipeline

| Phase | Skill | Produces | Gate |
|-------|-------|----------|------|
| 3. Discovery | `validate-feature` | Feature Ship Brief or NO-SHIP rejection with evidence | Kill signal gate |
| 3. Spec | `write-spec` | User stories, ACs, system dependencies | G1 |
| 3b. AC Audit | `audit-ac` | Rewritten/added acceptance criteria | — |
| 3c. Journeys | `write-journeys` | BDD journey docs (.feature.md) with AC traceability | — |
| 4. UX Design | `design-ux` | Screen flows, states, interactions | G2 |
| 5. UI Design | `design-ui` | Component specs, design tokens, visual hierarchy | G3 |
| 6. Technical Design | `design-tech` | Architecture, data model, feasibility | G4 |
| 6b. Alternatives | `explore-solutions` | Challenge baseline with alternative paradigms | — |
| 6c. Code Style | `define-code-style` | Code style contract for the project | — |
| 7. Plan | `plan-changeset` | Implementation manifest, task graph, AC/test mapping | — |
| 7b. Execute | `execute-changeset` | Code in worktree, staged diffs, checkpoint commits | G5 |
| 7c. Correctness | `audit-implementation` | Deep correctness audit before landing | — |
| 8. Promote | `land-changeset` | Squash merge to main, version bump, PR | G6 |
| 9. Verify | `verify-promotion` | VERIFIED status (spec-sync + QA + E2E proof) | G7 |

### Feature Spec Lifecycle

```
DRAFT → UX-REVIEWED → DESIGNED → BASELINED → CHANGE-SET-APPROVED → PROMOTED → VERIFIED
  ↓
REJECTED (NO-SHIP with evidence) → PIVOTED (alternative accepted) → DRAFT (re-enter pipeline)
```

## Feature Types

Every feature spec carries a type that identifies its consumer:

| Type | Consumer | Example |
|------|----------|---------|
| Feature | Human user | Match discovery, chat, payments |
| Enabler | Other service | Score recalculation cron, email service |
| Integration | External system | Stripe webhooks, OAuth provider |

All types go through the same pipeline. The type changes the consumer, not the
rigor. Specifying a Feature automatically reveals every Enabler and Integration
it depends on (the cascade effect).

## Workflow Lanes

Serious Vibe Coding routes work into lanes based on repo state and change type.
Use `route-workflow` to detect the right lane automatically, or pick one manually.

### Greenfield

Full progressive narrowing pipeline for new products or features in clean repos.

```
mine-builder → [find-opportunity] → [stage-revenue] →
write-vision → analyze-domain → analyze-competitors →
build-personas → validate-feature → write-spec → audit-ac → write-journeys →
design-ux → design-ui → design-tech → explore-solutions →
define-code-style → plan-changeset → execute-changeset →
audit-implementation → land-changeset → verify-promotion
```

`mine-builder` runs once (or quick-checks on return visits). `find-opportunity`
runs when the user doesn't have an idea. `stage-revenue` runs when the idea
is big but the builder needs money first. All three are skippable — "build
my idea anyway" jumps straight to `write-vision`.

Use when: starting a new project, adding a major feature to an empty or
near-empty repo, or the user says "build me an app" or "help me find what
to build."

### Brownfield Conversion

Onboard an existing repo into svc before applying other lanes.

```
onboard-repo → sync-work-items
```

Use when: the repo has shipped code, docs, tests, or conventions that must be
inventoried and mapped before svc can govern it. Does not rewrite anything
— logs findings as work items and routes each to the right lane.

### Brownfield Feature

Extend an existing system with delta specs instead of regenerating the full world.
Skips UX and UI design by default (override with `--include design-ux,design-ui`).

```
sync-spec-code → validate-feature → write-spec → write-journeys →
design-tech → explore-solutions → define-code-style →
plan-changeset → execute-changeset → review-gate →
audit-implementation → land-changeset → verify-promotion
```

Use when: adding a feature to a repo that already has specs, journeys, and
working code. Starts with drift check to ensure the spec baseline is accurate.

### Bugfix

Root-cause-first correction. Skips code style by default.

```
diagnose-bug → plan-changeset → execute-changeset →
review-gate → audit-implementation → land-changeset → verify-promotion
```

Use when: a work item describes broken behavior, a regression, or a production
issue. The diagnosis produces a brief with root cause, fix surface, and proof
plan before any code is touched.

### Drift / Maintenance

Reconcile specs, journeys, and code without shipping new behavior.

```
sync-spec-code → write-journeys → sync-work-items
```

Use when: specs have drifted from code (PLANNED items are now implemented,
code contradicts spec, journeys reference stale behavior). Produces updated
annotations and work items.

### Refactor

Preserve behavior while making bounded structural changes.

```
sync-spec-code → plan-changeset → execute-changeset →
review-gate → audit-implementation → land-changeset → verify-promotion
```

Use when: renaming, restructuring, extracting, or cleaning up code without
changing user-facing behavior.

## The Worktree Model

All implementation phases happen in a single worktree branched from main.
Code lives in actual files, not markdown documents.

```
feature/match-discovery (worktree branch)
  src/...                  ← real code, real tests, real files
  docs/plans/manifest.md   ← what changed, why, task graph, validations
  checkpoint commits:
    phase-3-spec
    phase-4-ux-design
    phase-5-ui-design
    phase-6-technical-design
    task-1-types
    task-2-data-model
    task-3-tests
    ...
```

Each phase creates a checkpoint commit on the feature branch. The manifest
describes what changed, how tasks are grouped, and what validation should
happen, preserving reviewability. Promotion is `git merge --squash` to main —
one clean commit with the full context.

Full worktree model: [`WORKTREES.md`](WORKTREES.md)

## Token Efficiency

Serious Vibe Coding uses a four-layer cache architecture that reduces token costs by
50-60% compared to naive approaches:

| Layer | Scope | Cached across | Tokens |
|-------|-------|---------------|--------|
| 1. Project | Vision, personas, design system | All features, all tasks | ~15K |
| 2. Feature | Spec, UX, UI, tech design | All tasks of one feature | ~20K |
| 3. Code | Only files referenced by spec annotations | Parallel sub-agents | ~30K |
| 4. Task | Task instructions (unique) | Never cached | ~10K |

Key optimizations:
- **Phases 3-6 don't load source code.** The spec IS the codebase index
  (RESOLVED annotations with file:line). Code is loaded only in Phase 7.
- **Stable loading order** maximizes cache prefix matches across tasks.
- **Parallel sub-agents** share Layer 1-3 cache when dispatched together.
- **Phase-skipping** for non-UI features (Enablers skip Phases 4-5).

## Setup

### Platform

svc runs inside [Claude Code](https://docs.anthropic.com/en/docs/claude-code),
which executes bash commands, git operations, and file I/O through a Unix shell.
This means:

| Platform | Status | Notes |
|----------|--------|-------|
| **Linux** | Best | Native shell, fastest file I/O, no abstraction layers |
| **macOS** | Best | Native shell, fully supported |
| **Windows + WSL2** | Supported | Run inside WSL2 — not native Windows. Work in the Linux filesystem (`~/`), not `/mnt/c/` |
| **Windows native** | Not supported | Claude Code requires bash. cmd.exe and PowerShell don't work |

**If you're on Windows, use WSL2.** The entire svc pipeline — worktree
management, eval scripts, lint checks, skill execution — uses bash and assumes
a POSIX environment. WSL2 gives you a real Linux kernel with native ext4
performance. Working inside `/mnt/c/` (the Windows filesystem) is 3-5x slower
for git operations due to the 9P filesystem bridge — always keep your repo in
the Linux home directory.

### Prerequisites

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| **Node.js** | 18+ | 20+ (LTS) |
| **Git** | 2.25+ | Latest |
| **Claude Code** | Latest | Latest |
| **GitHub CLI** (`gh`) | Optional | Install for `land-changeset` PR creation |
| **Anthropic account** | Required | Claude Pro or Max subscription, or API key |

### Install

```bash
# 1. Install Claude Code (if not already installed)
npm install -g @anthropic-ai/claude-code

# 2. Install svc skill pack
npx skills add s7an-it/seriousvibecoding

# 3. Verify
claude
```

On first run, Claude Code prompts for authentication. After that, svc skills
are available in every conversation inside the repo.

### Optional: browser-based skills

`test-journeys`, `write-e2e`, and `track-visuals` need a browser for runtime
QA, E2E test authoring, and screenshot diffing. The primary integration is
[gstack](https://github.com/garrytan/gstack)'s browse daemon — if you have
gstack installed, `/browse` is available and auto-starts on first use.

Fallback chain if gstack browse is not available:
1. Playwright MCP (if configured) — functional but no persistence
2. Manual browser — the skill instructs you what to do

See [`references/browse-integration.md`](references/browse-integration.md)
for the full browser integration spec.

### Optional: live market research

[last30days](https://github.com/mvanhorn/last30days-skill) searches Reddit,
HN, X, YouTube, and Polymarket for real engagement signals from the past 30
days. When installed, `validate-feature` and `analyze-competitors` use it
to ground business questions in live data instead of LLM training data.

```bash
git clone https://github.com/mvanhorn/last30days-skill.git ~/.claude/skills/last30days
```

Zero-config start: Reddit, HN, and Polymarket work with no API keys.

### Optional: voice mode on WSL2

Claude Code supports voice input. On WSL2, audio requires PulseAudio or
PipeWire bridging between Windows and the Linux kernel — it doesn't work
out of the box. Run `/wsl2-audio` to diagnose and fix the full audio chain
(Application → ALSA → PulseAudio → WSLg → Windows speakers/mic).
This covers both Claude Code voice mode and general audio in WSL2.

## Repository Modes

- **bootstrap** — greenfield, no established workflow. Serious Vibe Coding creates the
  structure from scratch.
- **convert** — brownfield, existing code and conventions. Serious Vibe Coding inventories
  first, adapts second.

Mode contract and detection logic: [`REPO_MODES.md`](REPO_MODES.md)

## Included Skills

- `write-vision` — Create or refine the product vision
- `analyze-domain` — Build domain expertise and reference packs
- `analyze-competitors` — Map competitive landscape
- `build-personas` — Build user personas from vision and challenge libraries
- `write-journeys` — Generate BDD journey docs with AC traceability
- `test-journeys` — Journey-first QA against a live URL
- `validate-feature` — Validate a feature idea with 8 business questions + kill signal gate
- `audit-ac` — Audit and rewrite acceptance criteria for completeness
- `sync-spec-code` — Reconcile spec annotations against codebase
- `define-code-style` — Define or audit the project code style contract
- `write-e2e` — Write E2E test files from journey docs
- `analyze-marketing` — Mine feature specs for marketing angles
- `route-workflow` — Detect lane and route to the next skill
- `onboard-repo` — Inventory and map a brownfield repo
- `diagnose-bug` — Root-cause investigation before any fix
- `sync-work-items` — Push repo-canonical work items to GitHub Issues
- `discover-skills` — Find and install external skills
- `research` — Resolve uncertainty about APIs, libraries, patterns
- `write-spec` — Write feature spec with user stories and ACs
- `design-ux` — Define screen flows, state machines, interaction patterns
- `design-ui` — Define component specs, design tokens, visual hierarchy
- `design-tech` — Define architecture, data model, feasibility matrix
- `explore-solutions` — Challenge the chosen approach with alternative paradigms
- `plan-changeset` — Produce implementation manifest with task graph
- `execute-changeset` — Execute the plan in a worktree with TDD and checkpoints
- `review-gate` — Run the 5-step adversarial review at gates G1-G7
- `audit-implementation` — Deep correctness audit before landing
- `land-changeset` — Validate, version, PR, squash-merge, clean up
- `verify-promotion` — Post-merge verification (spec-sync + QA + E2E)
- `extract-bootstrap` — Extract patterns from a codebase into templates
- `review-cross-model` — Adversarial review via a second model
- `track-visuals` — Capture and diff screenshots across breakpoints
- `review-security` — OWASP Top 10 + STRIDE + supply chain audit
- `manage-learnings` — Review, search, prune, export project learnings
- `test-framework` — Benchmark the svc pipeline itself
- `evolve-framework` — Find improvement opportunities in the pipeline with grounded evidence
- `blend-external` — Analyze external repos and blend in useful patterns with version tracking
- `wsl2-audio` — Set up, diagnose, and fix audio/voice mode on WSL2
- `mine-builder` — Mine builder profile (finances, skills, social, tools, project history, patterns)
- `find-opportunity` — Reverse-engineer market winners, match to builder, score top 3
- `stage-revenue` — Break big ideas into revenue stages (fast money first, then the real thing)
- `create-skill` — Create new skills with eval infrastructure (forked from anthropics/skills)

## Full Doctrine

The complete methodology — technical argument for progressive narrowing,
review protocol specification, worktree model, promotion process, token cost
analysis, and execution model:

[`DOCTRINE.md`](DOCTRINE.md)

## Skill Pack Comparison

How svc compares to gstack and superpowers:

[`references/skill-pack-comparison.md`](references/skill-pack-comparison.md)

## External Add-Ons

Optional skill ecosystems: [`EXTERNAL_ADDONS.md`](EXTERNAL_ADDONS.md)

- `coreyhaines` marketing pack (12 skills: CRO, copy, SEO, launch strategy)

## Standing on the Shoulders of

Patterns, ideas, and code from these MIT-licensed projects made this possible:

- **[gstack](https://github.com/garrytan/gstack)** (Garry Tan) — founder persona, adversarial reviews, security audits, design exploration, ship workflow
- **[superpowers](https://github.com/obra/superpowers)** (Jesse Vincent) — task graph planning, TDD execution discipline, subagent-driven development
- **[Oh My Claude Code](https://github.com/yeachan-heo/oh-my-claudecode)** (Yeachan Heo) — ambiguity scoring, commit trailers, verified completion loops, tri-model review
- **[claude-code-setup](https://github.com/petekp/claude-code-setup)** (Pete Petrash) — solution exploration, systems analysis
- **[last30days](https://github.com/mvanhorn/last30days-skill)** (mvanhorn) — live market research for feature validation and competitive intelligence

Full attribution: [`NOTICES`](NOTICES)

## License

MIT — do whatever you want with it.

See [`LICENSE`](LICENSE) for full terms.
