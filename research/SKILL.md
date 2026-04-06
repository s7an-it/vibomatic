---
name: research
description: >
  On-demand research when a skill or workflow encounters uncertainty about an API,
  library, framework version, pattern, or domain concept. Uses WebSearch and file
  reading to resolve questions. Logs findings to docs/specs/research-log.md for
  future sessions. Use when: "research", "look up", "find out", "how does X work",
  "what's the best practice for", or when any skill declares uncertainty.
  Also works standalone for general codebase/technology research.
inputs:
  required: []
  optional:
    - { path: "docs/specs/research-log.md", artifact: research-log }
    - { path: "package.json", artifact: package-json }
outputs:
  produces:
    - { path: "docs/specs/research-log.md", artifact: research-log }
chain:
  lanes: {}
  progressive: false
  self_verify: true
  human_checkpoint: false
---

# Research

Resolve uncertainty about APIs, libraries, frameworks, or domain concepts. Any skill in the pipeline can invoke this skill when it encounters something it doesn't confidently know.

**Announce at start:** "I'm using the research skill to investigate [topic]."

## When To Use

- A skill needs to know a library's API and isn't confident about the current version
- The tech stack uses a framework the agent hasn't seen recently (Spring Boot 3.x, React 19, etc.)
- A domain concept is ambiguous and needs clarification
- The codebase uses a pattern the agent doesn't recognize

## Process

### Step 1: Frame the Question

State clearly:
- What do I need to know?
- What context do I already have? (codebase, package.json, existing code)
- What would a confident answer look like?

### Step 2: Local Research First

Before going external:
1. Read `package.json` for exact versions of relevant packages
2. Grep the codebase for existing usage patterns of the thing in question
3. Check `node_modules/<package>/README.md` or type definitions if available
4. Read `docs/specs/research-log.md` for prior findings on this topic

### Step 3: External Research (if local didn't resolve)

Use WebSearch for:
- Official documentation for the specific version in use
- Migration guides if the version is recent
- Community patterns for the specific use case

Sanitize queries: no file paths, no proprietary names, no credentials.

### Step 4: Log the Finding

Append to `docs/specs/research-log.md`:

```markdown
## YYYY-MM-DD: [Question]

**Asked by:** [skill name or "standalone"]
**Context:** [what was being done when this came up]
**Finding:** [the answer, with specifics]
**Source:** [URL or file path]
**Confidence:** high | medium | low
**Version-specific:** [yes/no — does this only apply to version X?]
```

Create the file if it doesn't exist.

### Step 5: Return the Finding

If invoked by another skill: return the finding so the calling skill can proceed.
If standalone: report the finding to the user.

## Domain Reference Packs

If research reveals that a domain needs persistent reference material (not a one-off finding), suggest creating a domain reference pack at `references/domains/<domain>/`. These are markdown files that execute-changeset loads as context when the tech stack matches.

## Self-Verify

| # | Check | How | PASS/FAIL |
|---|-------|-----|-----------|
| 1 | Finding is specific (not generic advice) | Answer references exact version, API, or pattern | |
| 2 | Finding is logged to research-log.md | `grep "YYYY-MM-DD" docs/specs/research-log.md` | |
| 3 | Confidence level is stated | Finding has high/medium/low | |
| 4 | Source is cited | URL or file path present | |

## Pipeline Continuation

Research is on-demand — it does not participate in progressive chains.
After completing, control returns to the calling skill or the user.
