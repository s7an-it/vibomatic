---
name: analyze-domain
description: >
  Identify and build domain expertise for the project. Reads vision to determine
  industry, tech stack, and domain. Loads or creates domain reference packs. In
  identify mode, produces docs/specs/domain-profile.md. In research mode, resolves
  domain questions for other skills. Use when: "what domain is this", "domain expertise",
  "what do I need to know about this space", "industry context", or automatically
  after write-vision in progressive mode. Also invoked by other skills when they need
  domain-specific knowledge beyond what training data provides.
inputs:
  required:
    - { path: "docs/specs/vision.md", artifact: vision }
  optional:
    - { path: "docs/specs/domain-profile.md", artifact: existing-domain-profile }
    - { path: "package.json", artifact: package-json }
    - { path: "docs/specs/analyze-competitors.md", artifact: analyze-competitors }
outputs:
  produces:
    - { path: "docs/specs/domain-profile.md", artifact: domain-profile }
chain:
  lanes:
    greenfield: { position: 2, prev: write-vision, next: build-personas, parallel: analyze-competitors }
  progressive: true
  self_verify: true
  human_checkpoint: false
---

# Domain Expert

Build and maintain domain expertise for the project. This is the bridge between
"we have a vision" and "we understand the space well enough to make good decisions."

**Announce at start:** "I'm using the analyze-domain skill to build domain expertise for this project."

## Modes

### Identify Mode (default — no existing domain-profile.md)

Run when the project has a vision but no domain profile yet.

**Step 1: Extract domain signals from vision**

Read `docs/specs/vision.md` and extract:
- **Industry:** What sector? (edtech, fintech, devtools, healthtech, etc.)
- **Tech stack:** What's being built with? (read package.json, tsconfig, Dockerfile if they exist)
- **Domain concepts:** What entities, workflows, or patterns does the product deal with?
- **User domain:** What expertise do the target users have? (developers, doctors, teachers, etc.)

**Step 2: Check for existing domain reference packs**

```bash
ls references/domains/ 2>/dev/null
```

If a matching pack exists (e.g., `references/domains/react-19/` for a React project), load it and note: "Domain reference pack found for [X]. Loading conventions."

**Step 3: Build domain profile from internal knowledge**

For the identified domain, produce what you confidently know:
- Key industry patterns and conventions
- Common architectural approaches
- Known pitfalls and anti-patterns
- Regulatory or compliance considerations (if applicable)
- Standard metrics and KPIs for this type of product

**Step 4: Identify knowledge gaps**

For each area, rate your confidence: high / medium / low.

- **High confidence:** Established patterns, well-known frameworks, stable APIs
- **Medium confidence:** Recent versions, evolving best practices, niche domains
- **Low confidence:** Brand-new frameworks, industry-specific regulations, regional conventions

For low-confidence areas:
1. Invoke the `research` skill with the specific question
2. If research reveals a framework/library gap, invoke `discover-skills` to check for external skills
3. Log all findings to `docs/specs/research-log.md`

**Step 5: Write domain profile**

Produce `docs/specs/domain-profile.md`:

```markdown
# Domain Profile

**Generated:** YYYY-MM-DD
**Industry:** [sector]
**Tech Stack:** [detected]
**Domain Concepts:** [key entities and patterns]

## Industry Context

[What this space looks like — major players, common approaches, user expectations]

## Technical Domain

[Framework conventions, architecture patterns, standard tooling]
[Version-specific notes if applicable]

## Known Pitfalls

[Common mistakes in this domain, anti-patterns, things that seem right but aren't]

## Regulatory / Compliance

[If applicable — GDPR, HIPAA, PCI-DSS, accessibility standards, etc.]
[If not applicable: "No specific regulatory requirements identified."]

## Success Metrics (industry standard)

[What KPIs matter in this space? DAU, conversion rate, time-to-value, etc.]

## Knowledge Gaps

[Areas where research was needed — with findings and confidence levels]
[Links to research-log.md entries]

## External Skills Discovered

[Skills found via discover-skills that could help — installed or recommended]

## Domain Reference Packs

[Packs loaded from references/domains/ — or packs created during this run]
```

**Step 6: Create domain reference pack if warranted**

If the domain profile reveals persistent tech-stack knowledge (not one-off findings), create a pack at `references/domains/<stack>/`:

```bash
mkdir -p references/domains/<stack>
```

Write conventions.md and testing.md with the domain-specific knowledge. These will be loaded by `execute-changeset` during code generation.

### Research Mode (invoked by other skills)

When another skill calls analyze-domain with a specific question:

1. Read the existing `docs/specs/domain-profile.md`
2. If the answer is in the profile: return it immediately
3. If not: invoke `research` skill, update the domain profile with the finding, return the answer
4. If research reveals a capability gap: invoke `discover-skills` to check for external skills

### Update Mode (existing domain-profile.md)

When invoked on a project that already has a domain profile:

1. Read the existing profile
2. Check if tech stack has changed (compare package.json against profile's Tech Stack)
3. Check if vision has evolved (compare vision.md against profile's Industry/Domain)
4. If changes detected: update the profile, research new areas
5. If no changes: report "domain profile is current"

## Auto Mode vs Guided Mode

**Auto mode** (`--progressive --auto-approve`):
- Extracts domain signals silently
- Researches gaps without asking
- Creates domain profile and reference packs
- Chains to analyze-competitors

**Guided mode** (standalone or `--progressive`):
- Presents extracted domain signals: "I see this as a [sector] product using [stack]. Sound right?"
- For each knowledge gap: "I'm not confident about [X]. Let me research."
- Presents findings with recommendations
- User can correct domain classification, add context, or skip research

## Self-Verify

| # | Check | How | PASS/FAIL |
|---|-------|-----|-----------|
| 1 | `docs/specs/domain-profile.md` exists | `test -f docs/specs/domain-profile.md` | |
| 2 | Profile has Industry and Tech Stack | grep for both sections | |
| 3 | Low-confidence areas were researched | Knowledge Gaps section present | |
| 4 | Domain reference pack created if warranted | check references/domains/ | |

## Audit Mode

When invoked with `--audit` to re-evaluate domain profile:

1. Read `docs/specs/domain-profile.md`
2. Check tech stack: does package.json match the profile's declared stack?
3. Check knowledge gaps: have any low-confidence areas been resolved by new code/research?
4. Check domain reference packs: still match the current framework versions?
5. Report: section-by-section CURRENT/STALE/OUTDATED

## Pipeline Continuation

**If `--progressive` and self-verify passed:**
- This skill runs in parallel with `analyze-competitors` (dispatched by route-workflow).
- Do NOT chain to analyze-competitors — the orchestrator handles both.
- When both complete, orchestrator chains to `build-personas`.

**If standalone:**
- Report domain profile summary
- Suggest: "Next: run `analyze-competitors` if not already done, or `build-personas`"
