---
name: manage-learnings
description: >
  Manage project learnings that compound across sessions. Review, search,
  prune, and export what was discovered during pipeline runs. Use when
  "what did we learn", "show learnings", "prune stale learnings", "search
  learnings for <topic>", or when starting a new session to load context.
inputs:
  required: []
  optional:
    - { path: "docs/learnings/learnings.jsonl", artifact: learnings-log }
outputs:
  produces:
    - { path: "docs/learnings/learnings.jsonl", artifact: learnings-log }
chain:
  lanes: {}
  progressive: false
  self_verify: false
  human_checkpoint: false
---

# Review Learnings

Manage the project's institutional memory. Every skill logs operational
discoveries during pipeline runs. This skill lets you review, search,
prune, and export those learnings.

Blended from gstack /learn. Adapted for vibomatic's pipeline.

**Announce at start:** "I'm reviewing project learnings."

## How Learnings Are Captured

Every skill's Pipeline Continuation section should log discoveries to
`docs/learnings/learnings.jsonl` (append-only).

### JSONL Schema

Each entry is a single JSON line with these fields:

```json
{
  "date": "2026-04-04",
  "skill": "execute-changeset",
  "type": "operational",
  "key": "prisma-force-flag-ci",
  "insight": "Prisma needs --force flag for reset in CI environment",
  "confidence": 8,
  "source": "observed",
  "files": ["prisma/seed.ts", ".github/workflows/ci.yml"],
  "saves_minutes": 15
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `date` | yes | ISO date of discovery |
| `skill` | yes | Which skill logged this |
| `type` | yes | One of: `pattern`, `pitfall`, `preference`, `architecture`, `tool`, `operational` |
| `key` | yes | Unique kebab-case identifier (e.g., `prisma-force-flag-ci`) |
| `insight` | yes | The learning itself — what was discovered |
| `confidence` | yes | Integer 1-10 (see scoring below) |
| `source` | yes | One of: `observed`, `user-stated`, `inferred`, `cross-model` |
| `files` | no | Array of file paths relevant to this learning |
| `saves_minutes` | yes | Estimated minutes saved if this learning is applied in a future session |

### Confidence Scoring

| Score | Meaning | When to use |
|-------|---------|-------------|
| 10 | User-stated | User explicitly told us this fact |
| 8-9 | Verified in code | Confirmed by reading source, running tests, or observing behavior |
| 7 | Observed not verified | Saw it happen but didn't trace root cause |
| 4-5 | Uncertain | Hypothesis based on limited evidence |
| 1-3 | Speculation | Guess based on patterns, not confirmed |

### Deduplication

Latest entry with the same `key` + `type` combination wins. When logging a new entry,
check if an entry with the same key+type already exists. If so, the new entry supersedes
it — do not delete the old one (append-only), but during `review` and `export`, only
the latest entry per key+type is shown.

### 5-Minute Threshold

Only log a learning if it would save 5+ minutes in a future session. Ask:
"If I encountered this situation again without this knowledge, would I lose 5+ minutes?"

**What's worth logging:**
- Commands that failed and how they were fixed
- Project-specific quirks (build order, env vars, test setup)
- Patterns that worked well (or didn't)
- Tools discovered during research
- Domain conventions that aren't in the codebase

**What's NOT worth logging:**
- Generic programming knowledge
- Things already documented in README or CLAUDE.md
- One-time fixes that won't recur

### Compound Mechanism

When a learning matches a finding during any future skill run, display:

```
Prior learning applied: [key]
  Insight: <the insight text>
  Confidence: <N>/10  |  Source: <source>
```

This creates a feedback loop: learnings become more valuable each time they fire.
When a learning fires, consider bumping its confidence by +1 (cap at 10).

## Modes

### `review` (default)

Show the last 20 learnings, newest first:

```bash
tail -20 docs/learnings/learnings.jsonl | jq -r '.date + " [" + .skill + "] " + .learning'
```

### `search <query>`

Find learnings matching a keyword:

```bash
grep -i "<query>" docs/learnings/learnings.jsonl | jq '.'
```

### `prune`

Remove stale or conflicting learnings:
- **Stale:** learning references a file/pattern that no longer exists
- **Conflicting:** two learnings say opposite things (same key, contradictory insights)
- **Low-confidence:** confidence <= 3 and older than 30 days
- **Superseded:** duplicate key+type where a newer entry exists

**Staleness detection:** for each learning with a `files` array, check if the referenced
files still exist in the repo:

```bash
for file in $(jq -r '.files[]?' docs/learnings/learnings.jsonl); do
  [ ! -f "$file" ] && echo "STALE: $file no longer exists"
done
```

If a file no longer exists, mark the learning as stale candidate. Present all stale
candidates to the user for confirmation before removing.

### `extract` (skill extraction from debugging)

After solving a tricky problem, extract the pattern into a reusable learning:

**Quality gate (ALL must be true):**
- "Could someone Google this in 5 minutes?" → NO
- "Is this specific to THIS codebase or stack?" → YES  
- "Did this take real debugging effort to discover?" → YES

If all three pass, log it as type `pattern` with confidence 9-10.

**Format:**
```json
{"skill": "executing-change-set", "type": "pattern", "key": "prisma-reset-force-flag", "insight": "In CI environments, Prisma migrate reset requires --force flag because stdin is not a TTY. Without it, the command hangs waiting for confirmation that never comes.", "confidence": 9, "source": "observed", "files": ["prisma/migrations/"], "saves_minutes": 30}
```

This is not just a note — it's a reusable debugging heuristic that prevents the same 30-minute investigation from happening again.

### `export`

Export learnings to markdown for inclusion in CLAUDE.md or onboarding docs.

The export groups learnings by `type`, using only the latest entry per key+type
(deduplication applied). Only learnings with confidence >= 5 are exported.

**Export format for CLAUDE.md embedding:**

```markdown
## Project Learnings (auto-generated)

### Patterns
- [prisma-seed-ordering] Seed files must run in alphabetical order due to FK constraints (confidence: 8, observed)
- [api-error-shape] All API errors return {code, message, details} shape (confidence: 9, verified)

### Pitfalls
- [prisma-force-flag-ci] Prisma needs --force flag for reset in CI environment (confidence: 8, observed)
- [auth-middleware-order] Auth middleware must be loaded before rate limiter (confidence: 9, verified)

### Preferences
- [test-naming] Test files use .test.ts suffix, not .spec.ts (confidence: 10, user-stated)

### Architecture
- [service-layer-pattern] Business logic lives in /src/services, controllers are thin (confidence: 7, observed)

### Tool
- [playwright-headed-debug] Use --headed flag for Playwright debugging in WSL (confidence: 8, observed)

### Operational
- [dev-server-port] E2E tests require the dev server running on port 3000 (confidence: 8, observed)
```

Each bullet includes the key in brackets for traceability, the insight text,
and parenthetical confidence + source metadata.

## Integration

`route-workflow` reads learnings at session start to inform routing:
- If a learning says "feature X requires special build step", the compass
  flags it when routing to `execute-changeset`
- If a learning says "this API pattern causes issues", `design-tech`
  can avoid it

Every skill can query learnings before making decisions:
```bash
grep -i "<topic>" docs/learnings/learnings.jsonl
```

## Pipeline Continuation

### Self-Verify

| # | Check | How | PASS/FAIL |
|---|-------|-----|-----------|
| 1 | learnings.jsonl exists or was created | `test -f docs/learnings/learnings.jsonl` | |

### Chaining

Standalone skill — not in progressive chains. Invoke at session start
to load context, or after any skill to review what was learned.
