---
name: review-learnings
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
`docs/learnings/learnings.jsonl` (append-only):

```json
{"date": "2026-04-04", "skill": "executing-change-set", "feature": "notifications", "learning": "Prisma needs --force flag for reset in CI environment", "confidence": "high", "saves_minutes": 15}
```

**What's worth logging** (5+ minute savings threshold):
- Commands that failed and how they were fixed
- Project-specific quirks (build order, env vars, test setup)
- Patterns that worked well (or didn't)
- Tools discovered during research
- Domain conventions that aren't in the codebase

**What's NOT worth logging:**
- Generic programming knowledge
- Things already documented in README or CLAUDE.md
- One-time fixes that won't recur

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
- Stale: learning references a file/pattern that no longer exists
- Conflicting: two learnings say opposite things
- Low-confidence: marked "low" and older than 30 days

### `export`

Export learnings to markdown for inclusion in CLAUDE.md or onboarding docs:

```markdown
## Project Learnings (auto-generated)

### Build & Deploy
- Prisma needs --force flag for reset in CI (2026-04-04, high confidence)

### Testing
- E2E tests require the dev server running on port 3000 (2026-04-03, high confidence)

### Domain
- Tax calculations use banker's rounding, not standard (2026-04-02, high confidence)
```

## Integration

`workflow-compass` reads learnings at session start to inform routing:
- If a learning says "feature X requires special build step", the compass
  flags it when routing to `executing-change-set`
- If a learning says "this API pattern causes issues", `writing-technical-design`
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
