---
name: blend-external
description: >
  Blend patterns from external skill packs and repos into svc. Analyzes an
  external source, identifies what to take, produces a blend plan, and tracks
  what was taken with version/SHA for future re-blends. Use when "blend from",
  "what can we take from X", "integrate patterns from", "re-blend", "check for
  new stuff in gstack/superpowers/OMCC", "update from external", or when the
  user points at an external repo and wants to pull in useful patterns. Also
  triggers on "add a new source" or "blend a new repo". Also use when
  "rethink our blends", "did we blend the right thing", "review past blends",
  or when the user wants to reassess whether previous blend decisions still
  hold up.
inputs:
  required: []
  optional:
    - references/blend-registry.json (tracks what was taken from where)
    - NOTICES (attribution file)
    - references/skill-pack-comparison.md
---

You are evaluating an external repo or skill pack and deciding what svc should
take from it.

**Announce at start:** "I'm using the blend-external skill to analyze <source> and find patterns worth blending into svc."

## Modes

### 1. New source — first blend

The user points at a repo they haven't blended from before. Full analysis.

### 2. Re-blend — check for updates

A source already in `references/blend-registry.json`. Compare what they've
shipped since the last recorded SHA. Only analyze the delta.

### 3. Audit — check all sources

No specific repo. Walk through every entry in the blend registry and check
if any source has shipped improvements since last blend.

### 4. Rethink — reassess past blend decisions

Revisit what was previously blended and ask whether svc took the best approach.
This is not about new content from the source — it's about whether the
adaptation of old content was done well, whether svc's own evolution has made
a previous blend redundant or suboptimal, or whether a pattern that was skipped
at the time should now be reconsidered.

## Phase 1 — Acquire the source

If the source is a GitHub repo:

```bash
# Clone to tmp for analysis (shallow, read-only)
git clone --depth 50 <repo-url> /tmp/svc-blend-<name>
cd /tmp/svc-blend-<name>
```

Record the current HEAD SHA:
```bash
git rev-parse HEAD
```

If re-blending, check what changed since last blend:
```bash
git log --oneline <last-sha>..HEAD
git diff --stat <last-sha>..HEAD
```

## Phase 2 — Analyze the source

Read every skill/agent definition in the external repo. For each one:

1. **What does it do?** — core action, inputs, outputs
2. **Does svc already have this?** — check against all 37 svc skills
3. **If svc has it, is theirs better?** — compare depth, edge case handling,
   patterns, modes
4. **If svc doesn't have it, should it?** — does it address a real gap?

Build an assessment table:

| External skill | svc equivalent | Assessment | Action |
|---------------|---------------|------------|--------|
| `/their-skill` | `our-skill` | Theirs handles X better because Y | BLEND: add X pattern to our-skill |
| `/their-other` | — | Addresses gap Z | BLEND: new skill or new section |
| `/their-thing` | `our-thing` | Ours is better/equivalent | SKIP |
| `/their-niche` | — | Not relevant to svc goals | SKIP: reason |

### Phase 2b — Rethink past blends (mode 4, or always in audit mode)

For each pattern previously taken from this source (read from blend registry):

1. **Read the current svc implementation** of the blended pattern
2. **Read the original source** to remember what was taken
3. **Assess the adaptation:**
   - Did we take the right parts? Or did we miss the key insight?
   - Did we over-adapt and lose the original value?
   - Has svc evolved since the blend in a way that makes the adaptation
     awkward or redundant?
   - Has the source itself evolved the pattern in a better direction?
4. **Check skipped patterns:** Review `patterns_skipped` in the registry.
   Were any skip decisions wrong in hindsight? Has svc's growth created a
   need that a previously-skipped pattern would now address?

Build a rethink table:

| Blended pattern | svc skill | Verdict | Action |
|----------------|-----------|---------|--------|
| P0 founder persona | route-workflow | Adaptation is solid, working well | KEEP |
| /cso security audit | review-security | We took the checklist but missed the verification loop | IMPROVE: add active verification |
| /learn memory | manage-learnings | svc's quality gate is better than original | KEEP (svc improved on source) |
| /ship PR workflow | land-changeset | Redundant since we added our own version bump logic | SIMPLIFY: remove source-derived parts |

| Skipped pattern | Original reason | Reassessment | Action |
|----------------|-----------------|--------------|--------|
| /freeze scope guard | "land-changeset covers this" | Still true | KEEP SKIP |
| /retro weekly review | "not relevant" | Now that we have manage-learnings, a retro could feed it | RECONSIDER |

## Phase 3 — Produce the blend plan

For each BLEND item, specify exactly:
- **What pattern** to take (quote the relevant section from their source)
- **Where it goes** in svc (which SKILL.md, which section)
- **How to adapt** it (svc has different conventions, terminology, pipeline)
- **What NOT to take** (parts that conflict with svc doctrine or duplicate
  existing behavior)

Output: `proposals/<date>-blend-<source-name>.md`

```markdown
# Blend Plan: <source-name>

**Source:** <repo-url>
**SHA:** <commit-sha>
**Date:** <today>
**Previous blend:** <last-sha or "first blend">

## Summary
<N patterns to blend, M to skip, P already present>

## Blend items

### 1. <Pattern name> → <target svc skill>

**From:** <file:line in external repo>
**Into:** <svc skill file:section>
**What to take:**
<Specific pattern, quoted>

**How to adapt:**
<What changes for svc context>

**What NOT to take:**
<Parts to skip and why>

---
(repeat for each blend item)

## Skipped items
| External | Reason for skip |
|----------|----------------|
| ... | ... |

## Rethink: past blend reassessment
(Only in rethink/audit mode. Omit if first blend.)

### Blended patterns reassessed
| Pattern | svc skill | Verdict | Action |
|---------|-----------|---------|--------|
| ... | ... | KEEP / IMPROVE / SIMPLIFY / REPLACE | ... |

### Skipped patterns reconsidered
| Pattern | Original skip reason | Reassessment | Action |
|---------|---------------------|--------------|--------|
| ... | ... | KEEP SKIP / RECONSIDER | ... |

## Attribution update
<What to add to NOTICES>
```

## Phase 4 — Update the blend registry

After the blend plan is approved and implemented, update
`references/blend-registry.json`:

```json
{
  "sources": [
    {
      "name": "gstack",
      "url": "https://github.com/garrytan/gstack",
      "license": "MIT",
      "author": "Garry Tan",
      "blends": [
        {
          "sha": "abc123...",
          "date": "2026-04-05",
          "patterns_taken": [
            {
              "external_path": "skills/cso/SKILL.md",
              "svc_target": "review-security/SKILL.md",
              "pattern": "OWASP + STRIDE audit"
            }
          ],
          "patterns_skipped": [
            {
              "external_path": "skills/ship/SKILL.md",
              "reason": "land-changeset already covers this"
            }
          ]
        }
      ]
    }
  ]
}
```

This registry is the source of truth for what was taken, when, and from which
version. When re-blending, compare the current HEAD against the last recorded
SHA to scope the analysis.

## Phase 5 — Update NOTICES

For any new source or new patterns taken, update `NOTICES` with:
- Project name and URL
- Copyright and license
- Specific patterns derived, mapped to svc skills

## Rules

- Do not implement the blend. This skill produces the plan. Implementation
  happens by editing the target SKILL.md files directly (or through the normal
  pipeline for larger changes).

- Respect licenses. Only blend from repos with permissive licenses (MIT,
  Apache 2.0, BSD). If the source has a restrictive license, stop and tell
  the user.

- Do not take code verbatim unless the license explicitly allows it. Take
  patterns, approaches, and ideas — adapt them to svc conventions.

- When re-blending (mode 2), only analyze NEW content from the source — the
  delta since last SHA. For reassessing OLD blends, use rethink mode (mode 4)
  or audit mode (mode 3, which includes rethink automatically).

- If the external source is worse than svc in every dimension, say so. "Nothing
  worth taking" is a valid finding. Do not manufacture blend items to justify
  the analysis.

- Clean up: `rm -rf /tmp/svc-blend-<name>` after analysis is complete.

## Initializing the blend registry

If `references/blend-registry.json` doesn't exist, create it from NOTICES.
Read NOTICES to reconstruct the initial registry with the sources already
attributed. Set the SHA to "unknown-pre-registry" for sources that were
blended before tracking began — the next re-blend will establish a baseline.
