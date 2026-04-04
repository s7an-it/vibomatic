---
name: bootstrap-extract
description: >
  Extract production-verified patterns from a real codebase into a reusable
  bootstrap template. Use when "extract patterns from", "create bootstrap from",
  "analyze this repo for patterns", "make a template from", or when pointing
  at a public/local repo to capture its architecture for reuse. Produces a
  manifest.md + decisions.md under references/bootstraps/.
inputs:
  required: []
  optional:
    - { path: "references/bootstraps/*/manifest.md", artifact: existing-templates }
outputs:
  produces:
    - { path: "references/bootstraps/<name>/manifest.md", artifact: bootstrap-manifest }
    - { path: "references/bootstraps/<name>/decisions.md", artifact: bootstrap-decisions }
chain:
  lanes: {}
  progressive: false
  self_verify: true
  human_checkpoint: true
---

# Bootstrap Extract

Analyze a real codebase and extract its production-verified patterns into
a reusable bootstrap template for `references/bootstraps/`.

**Announce at start:** "I'm using bootstrap-extract to capture patterns from this codebase."

## When To Use

- You have a repo that's running in production and want to reuse its patterns
- You found a well-architected open-source project and want to capture its approach
- Your team wants to standardize on patterns from a proven project
- You want `solution-explorer` to auto-skip for a known-good stack

## Process

### Step 1: Access the Codebase

**Local repo:**
```bash
ls <path>/package.json <path>/go.mod <path>/Cargo.toml <path>/requirements.txt 2>/dev/null
```

**Public repo (clone to temp):**
```bash
git clone --depth 1 <url> /tmp/bootstrap-source-<name>
```

**GitHub API (no clone needed for analysis):**
```bash
gh api repos/<owner>/<repo>/contents
gh api repos/<owner>/<repo>/languages
```

### Step 2: Extract Stack

Identify the exact versions — not just "Node.js" but "Node.js 20 + Next.js 14 App Router + Prisma 5.x + PostgreSQL":

```bash
# Node.js
cat package.json | head -50        # dependencies + devDependencies
cat .nvmrc .node-version 2>/dev/null

# Python
cat pyproject.toml requirements.txt setup.py 2>/dev/null | head -50

# Go
cat go.mod | head -20

# Rust
cat Cargo.toml | head -30
```

Record: runtime, framework, database, ORM, API style, auth, testing, CI.

### Step 3: Extract Architecture Patterns

Map the codebase structure:

```bash
find <path> -type f -name "*.ts" -o -name "*.py" -o -name "*.go" -o -name "*.rs" | head -50
ls -la <path>/src/ <path>/app/ <path>/lib/ <path>/components/ 2>/dev/null
```

Identify:
- **Module structure** — how code is organized (by feature, by layer, by domain)
- **Data flow** — how requests flow through the system
- **State management** — how state is held and shared
- **Error handling** — patterns for errors, validation, fallbacks
- **API design** — REST/GraphQL/tRPC, versioning, auth middleware
- **Database access** — ORM patterns, migrations, query style
- **Testing approach** — unit/integration/E2E split, fixtures, mocks vs real DB

### Step 4: Extract Conventions

Read actual code to identify naming and style:

```bash
# Naming conventions
grep -r "export function\|export const\|export class" <path>/src/ | head -20

# Import style
head -20 <path>/src/**/*.ts 2>/dev/null | head -40

# Error handling patterns
grep -r "throw\|catch\|Error\|Result" <path>/src/ | head -20

# Test patterns
ls <path>/tests/ <path>/__tests__/ <path>/src/**/*.test.* 2>/dev/null | head -20
```

### Step 5: Extract Key Decisions

For each major architectural choice, document:
- What was chosen
- What alternatives exist
- Why this choice works (evidence: scale, team size, deployment target)

Focus on decisions that `solution-explorer` would normally investigate:
- Why this database (not another)?
- Why this API pattern?
- Why this component structure?
- Why this deployment model?

### Step 6: Check Production Verification

Assess how battle-tested this is:

```bash
# Commit history depth
git log --oneline | wc -l

# Contributors
git shortlog -sn | head -10

# Recent activity
git log --oneline -10

# CI/CD
ls .github/workflows/ Dockerfile docker-compose.yml 2>/dev/null
```

If public repo: check stars, forks, issues, last release.
If internal: ask about user count, uptime, incident history.

### Step 7: Produce Template

Write to `references/bootstraps/<name>/`:

**manifest.md:**
```markdown
# Bootstrap: <name>

## Stack
- Runtime: <exact version>
- Framework: <exact version>
- Database: <exact version + ORM>
- API: <style + library>
- Testing: <frameworks>
- CI: <platform>

## Verified By
- Source repo: <url or "internal">
- Users: <scale>
- Last verified: <date>
- Commits: <count>
- Contributors: <count>

## When To Use
<specific conditions>

## When NOT To Use
<specific conditions>

## Patterns
### Module Structure
<how code is organized>

### Data Flow
<how requests flow>

### Error Handling
<patterns>

### Testing
<approach, split, fixtures>

## Conventions
### Naming
<functions, files, components, routes>

### File Structure
<directory layout>

### Import Style
<absolute vs relative, barrel files, etc.>
```

**decisions.md:**
```markdown
# Decisions: <name>

Pre-made paradigm decisions from production-verified codebase.
These replace solution-explorer's Phase 2-5 when the stack matches.

## Decision 1: <topic>
**Chose:** <what>
**Over:** <alternatives>
**Evidence:** <why this works — from the source repo>

## Decision 2: <topic>
...
```

### Step 8: Clean Up

If a temp clone was created:
```bash
rm -rf /tmp/bootstrap-source-<name>
```

## Audit Mode

When invoked with `--audit` on an existing template:

1. Re-check the source repo (if URL available) for updates
2. Compare template stack versions against current latest
3. Flag stale conventions or deprecated patterns
4. Report: CURRENT / OUTDATED / NEEDS-REFRESH

## Pipeline Continuation

### Self-Verify

| # | Check | How | PASS/FAIL |
|---|-------|-----|-----------|
| 1 | manifest.md exists | `test -f references/bootstraps/<name>/manifest.md` | |
| 2 | decisions.md exists | `test -f references/bootstraps/<name>/decisions.md` | |
| 3 | Stack section has exact versions | grep for version numbers in manifest | |
| 4 | At least 3 decisions documented | count `## Decision` headers in decisions.md | |
| 5 | "Verified By" has source and date | grep for source and date in manifest | |

### Chaining

This skill is standalone — no progressive chain. After extraction, suggest:
- "Template saved. `solution-explorer` will auto-skip when this stack matches."
