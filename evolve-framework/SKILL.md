---
name: evolve-framework
description: >
  Find improvement opportunities for the svc framework itself. Reads current
  skills, doctrine, test results, proposals, and comparison data to identify
  gaps, inefficiencies, and missing patterns. Produces a prioritized proposal
  with grounded justifications. Use when "evolve the framework", "improve svc",
  "what should we fix next", "find gaps", "framework audit", "meta-improvement",
  or when the user wants to make the pipeline itself better rather than using it
  on a project.
inputs:
  required: []
  optional:
    - test-framework/results/ (past test runs and comparisons)
    - proposals/ (existing improvement proposals)
    - references/skill-pack-comparison.md
---

You are improving the svc framework itself — not using it on a project.

**Announce at start:** "I'm using the evolve-framework skill to find improvement opportunities for the svc pipeline."

## What you're looking for

The goal is to find concrete, actionable improvements to the methodology,
skills, or pipeline that would make svc produce better results with less
friction. Every finding must be grounded in evidence, not vibes.

## Evidence sources (read in this order)

1. **DOCTRINE.md** — the methodology claims. Look for claims that aren't
   enforced by any skill, or enforcement gaps between what the doctrine says
   and what skills actually do.

2. **skills-manifest.json** — lane definitions, pipeline order, review gates.
   Look for ordering issues, missing skills in lanes, or gates that don't
   match the doctrine.

3. **Every SKILL.md** — read all 35+ skills. Look for:
   - Skills that overlap significantly (should be merged or one should defer)
   - Skills that reference patterns not yet implemented
   - Skills with TODO/FIXME/placeholder sections
   - Input/output mismatches between chained skills
   - Missing self-verify or chain position metadata
   - Inconsistencies in how skills handle bootstrap vs convert mode

4. **test-framework/results/** — past autopilot runs and comparisons. Look for:
   - Metrics that show regression or stagnation
   - Comparison findings where svc lost to alternatives
   - Patterns in what the pipeline gets wrong repeatedly

5. **proposals/** — existing improvement proposals. Check:
   - Which proposals were implemented vs still pending
   - Whether implemented proposals actually landed in the skills
   - Whether pending proposals are still relevant

6. **references/skill-pack-comparison.md** — capability gaps vs gstack and
   superpowers. Look for capabilities others have that svc lacks.

7. **references/blend-registry.json** (if exists) — check if blended sources
   have shipped improvements since last blend.

## Analysis framework

For each finding, classify it:

| Category | What it means |
|----------|--------------|
| **Gap** | Something the doctrine or pipeline should do but doesn't |
| **Drift** | A skill contradicts the doctrine or another skill |
| **Inefficiency** | The pipeline wastes tokens, time, or user turns on something |
| **Fragility** | A pattern that works but breaks easily under edge cases |
| **Opportunity** | Something not in scope today but would meaningfully improve outcomes |

## Output

Produce `proposals/<date>-evolution.md` with this structure:

```markdown
# Framework Evolution — <date>

## Method
<What you read, how you assessed, what evidence you used>

## Findings (by priority)

### P0 — Fix now (blocks quality)
<Finding with evidence and specific fix>

### P1 — Fix soon (degrades quality)
<Finding with evidence and specific fix>

### P2 — Improve when possible (nice to have)
<Finding with evidence and specific fix>

### P3 — Track (not actionable yet)
<Finding with evidence and why it's not actionable yet>

## Comparison delta
<What competitors do that svc doesn't, with assessment of whether it matters>

## Stale proposal audit
<Which existing proposals are implemented, pending, or obsolete>
```

## Rules

- Every finding must cite the specific file and line where you found the issue.
  "The pipeline could be better" is not a finding. "plan-changeset/SKILL.md:142
  references a simulation step but the simulation never checks import resolution"
  is a finding.

- Do not propose changes that would break existing lane definitions. If a lane
  needs restructuring, say so but frame it as a migration, not a rewrite.

- Do not propose adding skills just because another framework has them. Only
  propose additions where you can articulate what specific failure mode or
  inefficiency the addition would address.

- Do not implement any changes. This skill produces proposals. Implementation
  happens through the normal pipeline (write-spec → plan-changeset → etc).

- If you find fewer than 3 findings, say so honestly. A clean audit is a
  valid result.
