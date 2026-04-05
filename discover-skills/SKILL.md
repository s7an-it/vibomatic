---
name: discover-skills
description: >
  Discover and install external skills from the open agent skill ecosystem.
  Wraps npx skills find/add. Invoked by analyze-domain or research when they
  encounter a capability gap an external skill could fill. Also works standalone:
  "find a skill for X", "is there a skill that can", "what skills exist for".
inputs:
  required: []
  optional:
    - { path: "docs/specs/domain-profile.md", artifact: domain-profile }
outputs:
  produces:
    - { path: "docs/specs/research-log.md", artifact: research-log }
chain:
  lanes: {}
  progressive: false
  self_verify: true
  human_checkpoint: false
---

# Skill Finder

Discover external skills when vibomatic encounters a capability gap.

**Announce at start:** "I'm using the discover-skills to search for external skills that could help."

## When Invoked

- `analyze-domain` finds a domain where a specialized skill would help
- `research` can't resolve a question from internal knowledge + WebSearch
- User asks directly: "is there a skill for X?"
- During `execute-changeset` when the tech stack needs domain expertise not in `references/domains/`

## Process

### Step 1: Search the ecosystem

```bash
npx skills find "[query]" 2>/dev/null
```

If `npx skills` is not available:
```bash
which npx >/dev/null 2>&1 && echo "NPX_AVAILABLE" || echo "NPX_NOT_AVAILABLE"
```

If not available, fall back to WebSearch:
- "claude code skill [capability]"
- "claude agent skill [domain]"
- "github claude skills [topic]"

### Step 2: Evaluate results

For each skill found:
- **Name and source** (GitHub repo or package)
- **What it does** (from description)
- **Relevance** to the current need (high/medium/low)
- **Trust signal** (stars, author reputation, update recency)

### Step 3: Present recommendation

**Guided mode:**
```
Found 3 skills for [query]:

1. [name] by [author] — [description]
   Relevance: high | Trust: [stars, last updated]
   RECOMMENDED

2. [name] by [author] — [description]
   Relevance: medium

3. [name] by [author] — [description]
   Relevance: low

Install the recommended one? (yes / pick another / skip)
```

**Auto mode:**
Install the highest-relevance, highest-trust skill automatically. Log the installation.

### Step 4: Install (if approved)

```bash
npx skills add [package]
```

After installation:
- Log to `docs/specs/research-log.md`: "Installed skill [name] for [reason]"
- If the skill provides domain-specific knowledge, consider copying relevant reference material to `references/domains/`

### Step 5: Report

If no relevant skills found:
"No external skills found for [query]. The analyze-domain or research skill should build this knowledge from primary sources (docs, WebSearch)."

If a skill was installed:
"Installed [name]. It provides [capability]. Available as /[skill-name] in future sessions."

## Self-Verify

| # | Check | How | PASS/FAIL |
|---|-------|-----|-----------|
| 1 | Search was performed | npx skills find or WebSearch executed | |
| 2 | Results evaluated with relevance | at least 1 result rated | |
| 3 | Finding logged | entry in research-log.md | |

## Pipeline Continuation

discover-skills does not participate in progressive chains.
After completing, control returns to the calling skill (analyze-domain, research) or the user.
