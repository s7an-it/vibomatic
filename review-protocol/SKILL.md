---
name: review-protocol
description: Use at every review gate (G1-G7) to run the universal 5-step review protocol — self-review, self-judgment, cross-review, convergence check, and gate decision — producing structured, parseable findings that block or pass artifact state transitions
inputs:
  required:
    - { path: "(artifact under review)", artifact: review-target }
  optional: []
outputs:
  produces:
    - { path: "(gate decision)", artifact: gate-decision }
chain:
  lanes:
    brownfield-feature: { position: 10, prev: executing-change-set, next: systems-analysis }
    bugfix: { position: 4, prev: executing-change-set, next: systems-analysis }
    refactor: { position: 4, prev: executing-change-set, next: systems-analysis }
  progressive: true
  self_verify: false
  human_checkpoint: false
---

# Review Protocol

## Overview

Every artifact state transition in the Vibomatic pipeline is gated by a review. This skill formalizes the 5-step review protocol designed around the specific failure modes of LLM agents: they miss their own errors, they agree too easily, and they rationalize incorrect output.

The protocol forces adversarial reasoning — an agent must argue with itself, then a fresh agent independently validates. No artifact advances without surviving this process.

**Announce at start:** "I'm using the review-protocol skill to run gate [G1-G7] review on [artifact name]."

## Why This Protocol Exists

LLMs have three review failure modes that prompt engineering cannot eliminate:

1. **Self-blindness.** An agent that wrote an artifact cannot reliably find its own errors — the same pattern matching that produced the error considers it correct.
2. **Agreement bias.** When shown existing findings, an agent defaults to "looks good" rather than independent evaluation.
3. **Review theater.** An agent lists trivial issues to appear thorough while missing structural problems.

The protocol compensates for each: Step 2 forces self-confrontation, Step 3 introduces a fresh perspective, and severity classification with convergence criteria prevents theater from blocking progress.

## When To Use

Invoke this skill at every gate in the pipeline:

| Gate | After Skill | Artifact Under Review | State Transition |
|------|-------------|----------------------|-----------------|
| G1 | `writing-spec` | Feature Spec | DRAFT → ready for UX |
| G2 | `writing-ux-design` | UX Design | DRAFT → UX-REVIEWED |
| G3 | `writing-ui-design` | UI Design | DRAFT → DESIGNED |
| G4 | `writing-technical-design` | Technical Design | DESIGNED → BASELINED |
| G5 | `executing-change-set` | Executed change set on branch | BASELINED → CHANGE-SET-APPROVED |
| G6 | `landing-change-set` | Promotion | CHANGE-SET-APPROVED → PROMOTED |
| G7 | `verifying-promotion` | Verification | PROMOTED → VERIFIED |

## Worktree Context

Review-protocol runs where the artifact lives:

- **G1-G4** (spec/design reviews): on main — artifacts are on main before any worktree exists.
- **G5** (post-execution review): **inside the worktree** — the code is there, tests are there, review it there. The feature must be fully validated before leaving the worktree.
- **G6** (promotion review): on main — reviewing the staged squash diff after `worktree.sh promote`.

If the G5 review finds issues, fix them in the worktree and re-review. The feature does not leave the worktree until it passes.

## Prerequisites

| Input | Where | Required? | If missing |
|-------|-------|-----------|------------|
| Artifact under review | Path from producing skill | Yes | Cannot proceed — run the producing skill first |
| Gate-specific checklist | See Gate Checklists below | Yes | Use the checklist table in this skill |
| Prior review findings (if re-entering) | From previous iteration | If iteration > 1 | First iteration starts clean |
| Upstream artifacts for context | See gate table | Recommended | Cross-check may miss consistency issues |

## The 5-Step Protocol

### Step 1: SELF-REVIEW

Agent A (the reviewing agent — may be the same agent that produced the artifact, or a fresh session) reviews the artifact against the gate-specific checklist.

**Process:**

1. Read the artifact in full.
2. Read the gate-specific checklist (see Gate Checklists below).
3. For each checklist item, evaluate the artifact.
4. Produce findings in the structured format below.

**Finding Format:**

Each finding is a structured block. Use this exact format so findings are parseable by downstream tools and agents:

```markdown
### Finding: [GATE]-[NNN]

- **Severity:** critical | high | medium | low
- **Location:** [file path:section] or [file path:line range]
- **Description:** [One-sentence summary of the issue]
- **Justification:** [Why this is an issue — reference the specific checklist item, AC, or doctrine principle violated. Quote the problematic text.]
- **Suggested fix:** [Concrete action to resolve — not "fix this" but "add error state for network timeout to screen S3"]
```

**Severity Definitions:**

| Severity | Meaning | Examples |
|----------|---------|---------|
| Critical | Artifact is structurally broken or violates a doctrine invariant; cannot proceed | Missing acceptance criteria, code doesn't match design, untestable story, placeholder content |
| High | Significant gap that will cause downstream failure if not fixed | Missing error states, incomplete dependency mapping, AC that contradicts another AC |
| Medium | Quality issue that should be fixed but won't block downstream phases | Ambiguous wording, missing edge case AC, inconsistent naming |
| Low | Minor polish that can be addressed later | Typos, formatting inconsistencies, verbose descriptions |

**Rules for Step 1:**

- Minimum 3 findings. If you find fewer than 3, you are not looking hard enough. Re-read the checklist.
- Maximum 20 findings. If you find more than 20, the artifact likely needs a rewrite, not a review. Flag this as a single critical finding: "Artifact requires rewrite — [reason]."
- Every finding must reference a specific location in the artifact. "The spec is vague" is not a finding. "Section 'User Stories', US-3: AC MATCH-07 is untestable because 'works correctly' has no measurable condition" is a finding.
- Do not manufacture findings. If the artifact is genuinely strong, your findings will be medium/low. That is fine. The convergence check handles this.

### Step 2: SELF-JUDGMENT

Agent A reviews its own findings from Step 1. For each finding, the agent must argue against itself — genuinely evaluate whether the finding holds up under scrutiny.

**Judgment Format:**

```markdown
### Judgment: [GATE]-[NNN]

- **Verdict:** ACCEPT | REJECT
- **Analysis:** [Why this finding is valid, or why it was a false positive. If rejecting, explain what you got wrong. If accepting, explain why the issue genuinely matters — do not just restate the finding.]
```

**Rules for Step 2:**

- You must reject at least one finding if you produced more than 5. If every finding survives self-judgment, you are not being critical enough of your own reasoning.
- A rejected finding means you recognized a false positive — this is good, not failure.
- The analysis must add information beyond the original finding. "This is valid because it's an issue" is not analysis. "This is valid because AC MATCH-03 requires response within 200ms but the design specifies a synchronous database query that will exceed this under load" is analysis.
- Do not downgrade severity as a compromise. If a finding is critical, accept it as critical or reject it entirely. Downgrading to "get it through" is review theater.

**Output of Step 2:** A list of accepted findings (with analysis) and rejected findings (with reasoning). Only accepted findings carry forward.

### Step 3: CROSS-REVIEW

Agent B receives the artifact, Agent A's findings, and Agent A's self-judgments. Agent B is a fresh perspective — a different agent session with no memory of producing or initially reviewing the artifact.

**Cross-Review Agent Prompt Template:**

Use this prompt to invoke the cross-review agent (Agent B). Pass the full content of the artifact and the Step 1-2 output.

```markdown
You are a cross-review agent for the Vibomatic review protocol. You are Agent B.

## Your Role

You are reviewing an artifact that Agent A has already reviewed. You have:
1. The artifact itself
2. Agent A's findings (with severity, location, justification)
3. Agent A's self-judgments (accept/reject with analysis)

## Your Task

### Part 1: Evaluate Agent A's Accepted Findings

For each of Agent A's ACCEPTED findings, produce:

### Cross-Review: [GATE]-[NNN]

- **Verdict:** ACCEPT | REJECT
- **Analysis:** [Your independent assessment. Do not defer to Agent A. If you agree, explain why from YOUR reading of the artifact. If you disagree, explain what Agent A missed or overcounted.]

### Part 2: New Findings

Identify issues Agent A missed entirely. Use the same finding format:

### Finding: [GATE]-[NNN] (new)

- **Severity:** critical | high | medium | low
- **Location:** [file path:section or line range]
- **Description:** [One-sentence summary]
- **Justification:** [Why this is an issue]
- **Suggested fix:** [Concrete action]

## Rules

- You must independently evaluate each finding. "I agree with Agent A" is not analysis.
- You must produce at least 1 new finding. If the artifact is genuinely excellent, your new finding will be low severity. That is acceptable.
- Do not rubber-stamp. If Agent A accepted a weak finding, reject it and explain why.
- Do not inflate severity to appear thorough. Rate honestly.
- Reference specific locations in the artifact for every decision.

## Artifact

[INSERT FULL ARTIFACT CONTENT]

## Agent A's Findings and Judgments

[INSERT STEP 1 AND STEP 2 OUTPUT]

## Gate Checklist

[INSERT GATE-SPECIFIC CHECKLIST FROM THE REVIEW PROTOCOL SKILL]
```

**Output of Step 3:** A consolidated findings list:
- Agent A findings accepted by both A and B (confirmed)
- Agent A findings accepted by A but rejected by B (disputed — treat as rejected unless severity is critical)
- Agent B new findings (added to the list)

### Step 4: CONVERGENCE CHECK

Evaluate the consolidated findings from Step 3 against the convergence criteria.

**Convergence Criteria:**

```
IF   all remaining findings are medium or low severity
THEN → PASS (proceed to Step 5 with PASS recommendation)

IF   any critical or high severity findings remain
THEN → FIX and re-enter Step 1 with:
       - The fixed artifact
       - The findings history (all prior iterations)
       - Iteration counter incremented

IF   iteration count = 3 and critical/high findings still remain
THEN → ESCALATE to human with:
       - Full findings history (all 3 iterations)
       - The current artifact
       - Summary of what was fixed and what remains
```

**Iteration Tracking Format:**

```markdown
## Convergence Status

- **Gate:** [G1-G7]
- **Artifact:** [file path]
- **Iteration:** [1|2|3] of 3
- **Findings summary:**
  - Critical: [count]
  - High: [count]
  - Medium: [count]
  - Low: [count]
- **Decision:** PASS | FIX-AND-REENTER | ESCALATE
- **Rationale:** [Why this decision — list the critical/high findings that block, or confirm only medium/low remain]
```

**Rules for Step 4:**

- Medium and low findings do not block. They are recorded and become improvement tasks, but the artifact advances.
- Disputed findings (Agent A accepted, Agent B rejected) are treated as resolved unless severity is critical. Critical disputed findings escalate to human.
- The 3-iteration cap is hard. No exceptions. If the artifact cannot pass in 3 iterations, a human must decide — the agents have demonstrated they cannot converge.

### Step 5: GATE DECISION

Based on the convergence check, issue the final gate decision.

**Gate Decision Format:**

```markdown
## Gate Decision: [G1-G7]

- **Artifact:** [file path]
- **Decision:** PASS | FAIL | ESCALATE
- **New state:** [target state if PASS] | [current state if FAIL] | [current state, pending human if ESCALATE]
- **Iterations completed:** [1-3]
- **Findings resolved:** [count]
- **Findings remaining (medium/low):** [count]
- **Findings escalated (critical/high):** [count, 0 if PASS]

### Remaining Findings (informational)

[List medium/low findings as improvement tasks — these do not block but should be tracked]

### Fix Tasks (if FAIL)

[List critical/high findings as concrete fix tasks with owners and suggested actions]

### Escalation Package (if ESCALATE)

[Full findings history across all iterations, current artifact state, what was tried, what remains unresolved]
```

**Decision Rules:**

| Decision | Condition | Effect |
|----------|-----------|--------|
| PASS | Only medium/low findings remain | Artifact transitions to next state. Remaining findings become backlog improvement tasks. |
| FAIL | Critical/high findings remain, iterations < 3 | Artifact stays in current state. Findings become fix tasks. After fixes, re-enter Step 1. |
| ESCALATE | Critical/high findings remain after 3 iterations | Artifact stays in current state. Human receives full findings history and makes the call. |

## Gate Checklists

Each gate reviews different aspects. Use the appropriate checklist for the gate being reviewed.

### G1: Feature Spec Review (DRAFT ready for UX)

| # | Check | What to look for |
|---|-------|-----------------|
| 1 | Stories testable? | Each story has a clear consumer, goal, and benefit. No compound goals ("and" in the goal = split). |
| 2 | ACs specific? | Each AC is one testable behavior. No "works correctly" or "handles gracefully" — measurable conditions only. |
| 3 | ACs cover error cases? | Happy path is not enough. Network failures, invalid input, auth failures, empty states. |
| 4 | Layer 3 clean? | Journey sync completed. No ungrounded preconditions remaining (or explicitly deferred with reasoning). |
| 5 | Dependencies identified? | System Dependencies table complete. Missing specs flagged. No hand-waved integrations. |
| 6 | Feature type correct? | Feature vs Enabler vs Integration correctly classified. Consumer matches type. |
| 7 | No technical design? | Technical Design section is empty placeholder. Spec does not prescribe implementation. |
| 8 | Story count reasonable? | 2-7 stories. >10 = decompose. 1 = might be a task, not a feature. |

### G2: UX Design Review (DRAFT to UX-REVIEWED)

| # | Check | What to look for |
|---|-------|-----------------|
| 1 | Flows cover all stories? | Every user story has a corresponding screen flow. No stories orphaned. |
| 2 | States complete? | Every screen has: default, loading, empty, error, success states defined. |
| 3 | Error handling explicit? | Every error state has a recovery path. No dead ends. |
| 4 | Accessibility addressed? | Screen reader flow, keyboard navigation, focus management, contrast requirements noted. |
| 5 | Information hierarchy clear? | Each screen identifies primary, secondary, tertiary content. Not a flat list. |
| 6 | Responsive strategy defined? | Mobile-first breakpoints. Reflow behavior for each screen. |
| 7 | No visual design? | No colors, fonts, spacing, or visual style. Those belong in UI design (Phase 5). |
| 8 | Transitions defined? | How does the user move between screens? What triggers transitions? Back navigation? |

### G3: UI Design Review (DRAFT to DESIGNED)

| # | Check | What to look for |
|---|-------|-----------------|
| 1 | Design system referenced? | All tokens (colors, spacing, typography) reference the design system, not ad-hoc values. |
| 2 | Component specs complete? | Every screen element has a component specification. No "standard button" without definition. |
| 3 | Responsive layouts specified? | Grid, breakpoints, reflow rules for each component. Not just "make it responsive." |
| 4 | Dark mode addressed? | Every color token has a dark mode variant or explicit "same" annotation. |
| 5 | Component states defined? | Hover, active, disabled, error, loading states for interactive elements. |
| 6 | Animation specified? | Motion principles applied. Duration, easing, triggers for each animation. |
| 7 | Visual hierarchy consistent? | Size, weight, contrast decisions align with UX information hierarchy from G2. |
| 8 | Component reuse maximized? | No duplicate components with different names. Shared patterns extracted. |

### G4: Technical Design Review (DESIGNED to BASELINED)

| # | Check | What to look for |
|---|-------|-----------------|
| 1 | All ACs feasible? | Every acceptance criterion has a plausible implementation path. None hand-waved. |
| 2 | Architecture sound? | Data flows make sense. No circular dependencies. Separation of concerns maintained. |
| 3 | Risks identified? | Performance, security, scalability risks called out with mitigation strategies. |
| 4 | Trade-offs explicit? | Decisions documented with alternatives considered and why they were rejected. |
| 5 | Data model complete? | All entities, relationships, indexes defined. Migration path from current state. |
| 6 | API contracts defined? | Request/response shapes, error codes, auth requirements for every endpoint. |
| 7 | Consistent with UX/UI? | Technical design doesn't silently drop UX flows or UI states. Everything mapped. |
| 8 | Dependencies resolvable? | All system dependencies from the spec have specs or are explicitly deferred. |

### G5: Executed Change Set Review (BASELINED to CHANGE-SET-APPROVED)

| # | Check | What to look for |
|---|-------|-----------------|
| 1 | Executed diff matches design? | The staged/task diff and final branch diff follow the technical design. No unplanned "improvements." |
| 2 | Tasks cover ACs? | Every AC is covered by one or more execution tasks and mapped tests. |
| 3 | Cross-file consistency? | Imports resolve. Types match across files. No file references a function that doesn't exist. |
| 4 | No placeholders? | No TODO, FIXME, "implement later", or stub functions in the executed branch state. |
| 5 | Manifest accurate? | Files planned in the manifest match the executed branch diff. |
| 6 | Task checkpoints clean? | Each completed task has a checkpoint commit and passed its task review/validation. |
| 7 | Tests written in the intended order? | Unit tests constrain implementation where required; the task graph reflects TDD intent. |
| 8 | Spec and journey updates included? | The implementation includes required spec/journey changes or explicitly defers them with reason. |

### G6: Promotion Review (CHANGE-SET-APPROVED to PROMOTED)

| # | Check | What to look for |
|---|-------|-----------------|
| 1 | Squash diff matches manifest? | The staged squash diff contains only manifest-listed files and intended changes. |
| 2 | No omissions? | Every manifest-listed file that should ship appears in the promotion diff. |
| 3 | No additions? | No files outside the manifest or approved execution path are being promoted. |
| 4 | Validation clean? | Final validation commands passed before promotion. |
| 5 | Checkpoint history trustworthy? | Promotion is backed by task checkpoints and reviewed execution, not ad hoc branch drift. |
| 6 | Promotion evidence produced? | The promoter recorded manifest/diff comparison and validation outcomes. |

### G7: Verification Review (PROMOTED to VERIFIED)

| # | Check | What to look for |
|---|-------|-----------------|
| 1 | Tests pass? | All unit tests, integration tests pass. No skipped tests without justification. |
| 2 | QA complete? | Manual QA checklist items verified. AC status annotations updated. |
| 3 | E2E complete? | End-to-end tests pass against deployed/running application. |
| 4 | Spec annotations updated? | Feature spec AC table shows QA and E2E status for every AC. |
| 5 | No regressions? | Existing tests still pass. No broken functionality outside the feature scope. |
| 6 | Journey scenarios verified? | Journey steps execute as documented. Layer 3 preconditions satisfied. |

## How Findings Feed Back as Fix Tasks

When a gate returns FAIL, the critical/high findings become structured fix tasks. Each fix task references back to the original finding so the fix can be verified in the next iteration.

**Fix Task Format:**

```markdown
### Fix Task: [GATE]-[NNN]

- **Source finding:** [GATE]-[NNN] from iteration [N]
- **Severity:** [from finding]
- **Artifact to fix:** [file path]
- **Location:** [section or line range]
- **Action required:** [from the finding's suggested fix — made concrete]
- **Verification:** [How to confirm the fix — what the next review should check]
- **Assigned to:** [producing skill name — the skill that created the artifact]
```

**Fix Cycle:**

```
1. Gate returns FAIL with fix tasks
2. Producing skill receives fix tasks
3. Producing skill applies fixes to the artifact
4. Review protocol re-enters at Step 1 with:
   - Updated artifact
   - Previous findings history
   - Iteration count + 1
5. New findings are checked against previous findings
   - Previously fixed findings should not reappear
   - If a "fixed" finding reappears, escalate its severity by one level
```

## Convergence: How Medium/Low Findings Are Tracked

Findings that remain after PASS are not discarded. They become improvement backlog items:

```markdown
## Improvement Backlog from [GATE] Review

| Finding | Severity | Description | Target |
|---------|----------|-------------|--------|
| G1-004 | medium | AC MATCH-03 missing timeout edge case | Next spec revision |
| G1-007 | low | Inconsistent capitalization in story titles | Next spec revision |
```

These do not block progress but are tracked so they are addressed before the artifact is considered finalized.

## Token Cost Considerations

The review protocol runs at every gate. Cost depends on artifact size and iteration count.

| Component | Estimated Tokens | Notes |
|-----------|-----------------|-------|
| Step 1: Self-Review | 3K-10K | Scales with artifact size |
| Step 2: Self-Judgment | 2K-5K | Proportional to finding count |
| Step 3: Cross-Review | 5K-15K | Includes full artifact + findings in context |
| Step 4: Convergence Check | 1K-2K | Fixed overhead |
| Step 5: Gate Decision | 1K-2K | Fixed overhead |
| **Total per iteration** | **12K-34K** | |
| **Total per gate (1-3 iterations)** | **12K-100K** | Most gates converge in 1-2 iterations |

**Optimization strategies:**

- Steps 1-2 (self-review + self-judgment) run in a single agent session — no context switch cost.
- Step 3 (cross-review) is a separate agent session — context loading cost is the main expense.
- For large artifacts (change sets), review tasks independently and run cross-reviews in parallel.
- Gate checklists focus the review — agents do not free-associate; they check specific items.
- If the producing skill is high-quality, most gates pass in iteration 1 with only medium/low findings.

## Anti-Patterns

| Anti-Pattern | What it looks like | Why it is harmful | Instead |
|-------------|-------------------|------------------|---------|
| Rubber-stamping | All findings are low severity. Self-judgment accepts everything. Cross-review agrees with everything. | Misses real issues. The review is theater — it looks like review happened but nothing was actually caught. | Enforce minimum finding counts. If an artifact has zero high/critical findings across all 3 steps, flag the review itself for human audit. |
| Review theater | Agent produces 15 findings, all about typos and formatting. Zero structural issues identified. | Creates false confidence. Looks thorough but ignores architecture, correctness, and consistency. | Gate checklists force structural evaluation. Findings must reference checklist items, not just surface observations. |
| Infinite loops | Fix cycle keeps finding new critical issues each iteration. Artifact never converges. | Wastes tokens. Indicates the artifact or the producing skill is fundamentally broken. | Hard cap at 3 iterations. If 3 rounds of fix-and-review cannot resolve critical issues, escalate to human. The agents cannot solve this. |
| Severity inflation | Agent marks everything as critical to seem thorough or to force fixes on minor issues. | Blocks progress unnecessarily. Causes the team to distrust severity ratings. | Severity definitions are strict (see table above). A finding's severity must match the definition. Cross-review agent independently rates severity — disagreements default to the lower rating unless both say critical. |
| Severity deflation | Agent marks critical issues as medium to avoid blocking the gate. Especially common in self-judgment. | Lets broken artifacts advance. Downstream phases inherit the problem. | Cross-review agent independently rates severity. If Agent B rates a finding higher than Agent A, the higher rating wins. |
| Copy-paste agreement | Cross-review agent restates Agent A's analysis verbatim and adds "I agree." | No independent evaluation occurred. Two agents said the same thing because Agent B pattern-matched on Agent A's output rather than reading the artifact. | Cross-review prompt explicitly forbids "I agree with Agent A." Every verdict requires analysis grounded in the artifact text, not in Agent A's text. |
| Finding reuse across iterations | Same finding appears in iteration 2 and 3 with identical wording because the fix was not applied or was applied incorrectly. | Wastes iterations. Agents are not verifying that fixes landed. | When re-entering Step 1, the agent receives previous findings. If a prior critical/high finding reappears, its severity escalates and the iteration may fast-track to ESCALATE. |

## Process Summary

```
                    ┌─────────────────────────────────┐
                    │  Artifact produced by skill      │
                    └───────────────┬─────────────────┘
                                    │
                    ┌───────────────▼─────────────────┐
        Step 1      │  SELF-REVIEW                     │
                    │  Agent A reviews against          │
                    │  gate checklist                   │
                    │  Output: structured findings      │
                    └───────────────┬─────────────────┘
                                    │
                    ┌───────────────▼─────────────────┐
        Step 2      │  SELF-JUDGMENT                   │
                    │  Agent A argues with itself       │
                    │  Accept or reject each finding    │
                    │  Output: filtered findings        │
                    └───────────────┬─────────────────┘
                                    │
                    ┌───────────────▼─────────────────┐
        Step 3      │  CROSS-REVIEW                    │
                    │  Agent B independently evaluates  │
                    │  Confirms, rejects, adds new      │
                    │  Output: consolidated findings    │
                    └───────────────┬─────────────────┘
                                    │
                    ┌───────────────▼─────────────────┐
        Step 4      │  CONVERGENCE CHECK               │
                    │  Only medium/low? → PASS          │
                    │  Critical/high? → FIX + re-enter  │
                    │  3 iterations? → ESCALATE         │
                    └───────────────┬─────────────────┘
                                    │
                    ┌───────────────▼─────────────────┐
        Step 5      │  GATE DECISION                   │
                    │  PASS → state transition          │
                    │  FAIL → findings become fix tasks │
                    │  ESCALATE → human decides         │
                    └─────────────────────────────────┘
```

## Routing

| Situation | Route to |
|-----------|----------|
| Gate returns PASS | Next skill in the pipeline (see Doctrine phase table) |
| Gate returns FAIL | Back to producing skill with fix tasks |
| Gate returns ESCALATE | Human review — present full findings package |
| Artifact needs rewrite (>20 findings) | Back to producing skill with rewrite directive |
| Review finds missing dependency spec | `writing-spec` to create the dependency |
| Review finds persona gap | `persona-builder` then re-review |
| Review finds journey inconsistency | `journey-sync` then re-review |
| Disputed critical finding (A accepts, B rejects) | Escalate that specific finding to human |

## Pipeline Continuation

### Self-Verify

Before declaring done, verify:

| # | Check | How | PASS/FAIL |
|---|-------|-----|-----------|
| 1 | Gate decision rendered | Output contains PASS, FAIL, or ESCALATE decision | |
| 2 | Findings list produced | Structured findings list exists in review output | |
| 3 | No unresolved questions | grep for TBD, TODO, open questions in review output | |

If any check FAILs, fix before continuing. If a fix requires upstream changes, stop and report.

### Chaining

**If `--progressive` flag is present AND self-verify passed:**
- Check `--skip` list. If this skill is in the skip list, pass through to next.
- In brownfield-feature lane: invoke `landing-change-set --progressive --lane brownfield-feature`
- In bugfix lane: invoke `landing-change-set --progressive --lane bugfix`
- In refactor lane: invoke `landing-change-set --progressive --lane refactor`

**If `--progressive` flag is absent:**
- Report results to user
- Suggest: "Next: consider running `landing-change-set`"
