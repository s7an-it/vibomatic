---
name: cross-model-review
description: >
  Adversarial code review using a second model (Codex CLI or equivalent).
  Sends diff + goals + spec to the second model, gets findings back, then
  Claude evaluates each finding: accept with justification or reject with
  justification. Back and forth until all remaining findings are medium
  severity max. Use when "cross-model review", "second opinion", "codex
  review", "adversarial review", or automatically in progressive mode
  after review-protocol for features with new data models or integrations.
inputs:
  required:
    - { path: "docs/specs/features/<name>.md", artifact: feature-spec }
    - { path: "docs/plans/<date>-<name>/manifest.md", artifact: implementation-manifest }
  optional:
    - { path: "docs/specs/explorations/<name>/DECISION.md", artifact: solution-decision }
outputs:
  produces:
    - { path: "docs/specs/reviews/<name>-cross-model.md", artifact: cross-model-review }
chain:
  lanes: {}
  progressive: false
  self_verify: true
  human_checkpoint: false
---

# Cross-Model Review

Independent code review from a second model. Two models disagree on code quality
more often than you'd expect — those disagreements are where the real bugs hide.

**Announce at start:** "I'm using cross-model-review for an independent second-model review."

## Why Two Models

Same-model review has a blind spot: the model that wrote the code shares the
same training biases as the model reviewing it. A second model (Codex, Gemini,
or any model accessible via CLI) brings genuinely different pattern recognition.

When both models agree something is fine → high confidence.
When they disagree → that's the signal worth investigating.

## Prerequisites

- Codex CLI installed (`codex` command available), OR
- Any model accessible via CLI that can take a prompt and return text
- Feature branch with committed code in the worktree
- Feature spec with ACs

## Process

This skill runs **inside the worktree** where the code lives.

### Step 1: Prepare the Review Package

Gather context for the second model:

```markdown
## Review Package

### Goal
<one paragraph from the feature spec: what this feature does and for whom>

### Acceptance Criteria
<AC table from the spec>

### Key Decisions
<from docs/specs/decisions/ if exists — what was chosen and why>

### Diff
<git diff main..HEAD — the actual changes to review>

### Files Changed
<list with brief purpose of each>
```

Keep it under 50K tokens. If the diff is larger, split by subsystem and
run multiple review rounds.

### Step 2: Send to Second Model

```bash
codex -p "$(cat review-package.md)" --output-format text
```

Or via any model CLI:
```bash
echo "<review-package>" | <model-cli> --prompt "Review this code change..."
```

The prompt to the second model:

```
You are reviewing a code change. Here is the context:

<review package>

Review this diff for:
1. Bugs — logic errors, off-by-one, null handling, race conditions
2. AC violations — does the code actually satisfy each acceptance criterion?
3. Security — injection, auth bypass, data leaks, insecure defaults
4. Design — does the implementation match the stated decisions?
5. Missing — what should be here but isn't?

For each finding, provide:
- Severity: Critical / High / Medium / Low
- Location: file:line
- Finding: what's wrong
- Evidence: why you believe this
- Proposal: how to fix it

Be specific. "Error handling could be better" is not a finding.
"api/users.ts:42 — no try/catch around the database call, a connection
timeout will crash the process" is a finding.
```

### Step 3: Evaluate Each Finding

For each finding the second model returns, Claude evaluates independently:

```markdown
### Finding: <title from second model>
**Second model says:** <severity> — <finding summary>
**Location:** <file:line>

**Claude's evaluation:**
- [ ] **ACCEPT** — <justification: why this is a real issue>
  - Priority: <keep severity or adjust>
  - Action: <what to fix>
- [ ] **REJECT** — <justification: why this is not an issue>
  - Reason: <false positive / already handled / out of scope / misunderstood context>
  - Evidence: <code citation proving it's handled>
```

Rules:
- Never reject without citing code that proves it's handled
- Never accept without verifying the finding is real (read the code)
- If uncertain → accept and mark for investigation
- Rejections must be more specific than acceptances (higher bar to dismiss)

### Step 4: Convergence Loop

After first evaluation pass:

1. Count remaining accepted findings by severity
2. If any **Critical** or **High** → fix them in the worktree
3. After fixes, re-send the updated diff to the second model
4. Evaluate new findings
5. Repeat until: **no Critical, no High, only Medium or lower remain**

Maximum 3 rounds. If Critical findings persist after 3 rounds, escalate to user.

### Step 5: Document the Review

Save to `docs/specs/reviews/<feature-name>-cross-model.md`:

```markdown
# Cross-Model Review: <feature name>

**Date:** <timestamp>
**Models:** Claude (primary) + <second model name>
**Rounds:** <count>
**Branch:** <branch name>

## Summary
- Findings from second model: <count>
- Accepted: <count> (Critical: N, High: N, Medium: N, Low: N)
- Rejected: <count> (with justification for each)
- Fixed: <count>
- Remaining: <count> (all Medium or lower)

## Round 1
### Accepted
<finding + justification + fix>

### Rejected
<finding + rejection justification + evidence>

## Round 2 (if needed)
...

## Verdict
<CONVERGED at Medium max / ESCALATED to user>
```

## When To Skip

- Second model CLI not available (gracefully skip, don't block the pipeline)
- Pure documentation or config changes (no behavioral code to review)
- Changes under 20 lines (overhead not worth it)

## Anti-Patterns

- Accepting all findings without reading the code ("the other model must be right")
- Rejecting all findings without evidence ("I wrote it so it's fine")
- Stopping after round 1 with unresolved Critical findings
- Sending the entire codebase instead of just the diff + context

## Pipeline Continuation

### Self-Verify

| # | Check | How | PASS/FAIL |
|---|-------|-----|-----------|
| 1 | Review doc exists | `test -f docs/specs/reviews/<name>-cross-model.md` | |
| 2 | No Critical findings remaining | grep for `Critical` in accepted + not fixed | |
| 3 | No High findings remaining | grep for `High` in accepted + not fixed | |
| 4 | Every rejection has evidence | each REJECT has a code citation | |

### Chaining

This skill is standalone — invoke it when you want a second opinion.
It does not auto-chain in progressive mode (optional, not mandatory).
Suggest: "Cross-model review complete. Proceed to `systems-analysis` or `landing-change-set`."
