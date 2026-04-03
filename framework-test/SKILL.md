---
name: framework-test
description: Test and benchmark the vibomatic framework end-to-end. Use when you need to verify the pipeline works, prove doctrine claims, measure token efficiency, or validate that progressive narrowing actually reduces output variance. Triggers on "test the framework", "prove it works", "benchmark vibomatic", "validate the pipeline", or any request to verify vibomatic's claims.
---

# Framework Test

End-to-end testing and benchmarking for the vibomatic doctrine. This skill
verifies that the methodology works as claimed — not by assertion, but by
measurement.

**Announce at start:** "I'm using the framework-test skill to test and benchmark vibomatic."

## What This Tests

The doctrine makes specific, testable claims. This skill verifies each one.

| # | Claim | Test Method | Pass Criteria |
|---|-------|-------------|--------------|
| C1 | Progressive narrowing reduces output variance | Generate the same feature 3x with/without phases, measure diff | With-phases variance < without-phases variance |
| C2 | Spec-as-index reduces token usage | Measure tokens loading full codebase vs spec-referenced files only | Spec-indexed < 50% of full-codebase tokens |
| C3 | Cache-optimized loading order produces cache hits | Compare same-order vs random-order artifact loading | Same-order has fewer input tokens (cached) |
| C4 | Review protocol catches errors single-pass misses | Plant known errors, compare single-pass vs protocol detection rate | Protocol detects >80% of planted errors |
| C5 | Checkpoints prevent cumulative drift | Run 5 tasks with/without checkpoint re-reads, measure final AC match | Checkpoint version matches more ACs |
| C6 | Feature/Enabler/Integration cascade discovers full dependency chain | Start with one Feature, check if all Enablers are identified | All dependencies identified without manual prompting |
| C7 | Worktree isolation prevents cross-feature contamination | Run two features in parallel worktrees, verify no shared state leakage | Zero shared files modified |

## Test Suites

### Suite 1: Pipeline Integrity (Static)

Validates that all artifacts exist and cross-reference correctly. This is
what the todo-api validation script does, but generalized to any project.

**How to run:**

```bash
# On any project with vibomatic artifacts
bash scripts/validate-pipeline-integrity.sh <project-root>
```

**Checks:**
- All skill directories have SKILL.md
- skills-manifest.json lists all skill directories
- Every feature spec has Status field
- Every AC table has the correct column format
- Every journey references AC IDs that exist in a feature spec
- Every RESOLVED annotation points to a file that exists
- Every UX/UI design file has a corresponding feature spec
- Design system exists if any UI designs reference it

### Suite 2: Progressive Narrowing (Generative)

Proves claim C1: more phases = less variance.

**Method:**

1. Define a tiny feature: "Add a health check endpoint that returns service status"
2. Generate implementation 3 times with ONLY a one-line description (no phases)
3. Generate implementation 3 times with full pipeline (spec → UX → tech design → code)
4. Measure pairwise diff between the 3 outputs in each group
5. Report: average diff size (lines changed between variants)

**Expected result:** The no-phases group has larger diffs between variants
(more variance). The full-pipeline group has smaller diffs (more deterministic).

**How to run:**

Dispatch 6 sub-agents (3 no-phases, 3 full-pipeline) in parallel. Each
produces the implementation files. Then diff each pair within each group.

```
No-phases group:
  Agent A: "Add a health check endpoint that returns service status" → code
  Agent B: same prompt → code
  Agent C: same prompt → code
  Variance = avg(diff(A,B), diff(A,C), diff(B,C))

Full-pipeline group:
  Agent D: writing-spec → writing-technical-design → code
  Agent E: same pipeline → code
  Agent F: same pipeline → code
  Variance = avg(diff(D,E), diff(D,F), diff(E,F))
```

### Suite 3: Token Efficiency (Measurement)

Proves claims C2 and C3: spec-as-index and cache-optimized loading save tokens.

**Method:**

For C2 (spec-as-index):
1. Take a project with mature specs (RESOLVED annotations with file:line)
2. Count tokens to load: all source files in src/
3. Count tokens to load: only files referenced by spec annotations
4. Report ratio

For C3 (cache-optimized loading):
1. Load artifacts in the doctrine's prescribed order (stable prefix)
2. Load the same artifacts in random order
3. Compare input token counts across 3 sequential requests
4. Cache hits show as lower input tokens on requests 2-3

**Note:** C3 requires API-level token reporting. If running in Claude Code
(which abstracts token counts), use the task notification's `total_tokens`
field from sub-agent completions as a proxy.

### Suite 4: Review Protocol Effectiveness (Adversarial)

Proves claim C4: the review protocol catches errors that single-pass misses.

**Method:**

1. Take the todo-api example feature spec
2. Plant 5 known errors:
   - One AC that contradicts another AC
   - One RESOLVED annotation pointing to a nonexistent file
   - One journey step with an ungrounded precondition
   - One user story with "and" in the goal (should be split)
   - One AC that is untestable ("system should be fast")
3. Run single-pass review (just "review this spec for errors")
4. Run the full review protocol (self-review → self-judgment → cross-review)
5. Count how many of the 5 planted errors each approach finds

**Expected result:** Full protocol finds more errors, especially the subtle
ones (contradicting ACs, ungrounded preconditions).

### Suite 5: Checkpoint Drift (Comparative)

Proves claim C5: checkpoints prevent drift.

**Method:**

1. Define a 3-task implementation: types → service → API handler
2. Run WITHOUT checkpoints: one agent writes all 3 tasks sequentially in
   one context, no re-reading of spec between tasks
3. Run WITH checkpoints: separate agent per task, each re-reads spec first
4. After both: compare final implementation against ACs
5. Count how many ACs each approach satisfies

**Expected result:** Checkpoint version matches more ACs because each task
started with fresh spec attention.

### Suite 6: Cascade Discovery (Functional)

Proves claim C6: specifying a Feature reveals its Enablers.

**Method:**

1. Give writing-spec a feature: "User can see a real-time leaderboard"
2. Check if journey-sync Layer 3 identifies system dependencies:
   - Score aggregation service (Enabler)
   - WebSocket push service (Enabler)
   - Potentially: caching layer (Enabler)
3. Check if writing-spec queues these as dependency specs

**Expected result:** At least 2 Enabler dependencies identified without
manual prompting.

## Running The Full Test Suite

```bash
# Suite 1 (static, fast, no LLM needed):
bash scripts/validate-pipeline-integrity.sh examples/todo-api

# Suites 2-6 (generative, requires LLM sub-agents):
# Run from Claude Code:
"Run framework-test suites 2-6 on the todo-api example"
```

## Results Format

Each suite produces a results file in `framework-test-results/`:

```
framework-test-results/
  YYYY-MM-DD-HH-MM/
    suite-1-integrity.json
    suite-2-narrowing.json
    suite-3-tokens.json
    suite-4-review.json
    suite-5-drift.json
    suite-6-cascade.json
    summary.md              ← human-readable summary of all suites
    benchmark.json          ← machine-readable aggregate
```

### Results JSON Schema

```json
{
  "suite": "progressive-narrowing",
  "claim": "C1: Progressive narrowing reduces output variance",
  "timestamp": "2026-04-03T12:00:00Z",
  "method": "3x generation with/without phases, pairwise diff",
  "results": {
    "no_phases": {
      "variance_lines": 142,
      "variants": ["A: 85 lines", "B: 93 lines", "C: 78 lines"],
      "pairwise_diffs": [45, 62, 38]
    },
    "full_pipeline": {
      "variance_lines": 23,
      "variants": ["D: 91 lines", "E: 89 lines", "F: 92 lines"],
      "pairwise_diffs": [8, 12, 5]
    },
    "variance_reduction": "83.8%"
  },
  "pass": true,
  "pass_criteria": "full_pipeline variance < no_phases variance",
  "tokens_used": {
    "no_phases_total": 150000,
    "full_pipeline_total": 420000,
    "overhead_ratio": 2.8
  }
}
```

### Summary Report

The summary.md aggregates all suites:

```markdown
# Vibomatic Framework Test Results

**Date:** 2026-04-03
**Model:** claude-opus-4-6
**Project:** examples/todo-api

## Results

| Suite | Claim | Result | Key Metric |
|-------|-------|--------|-----------|
| 1. Integrity | Pipeline artifacts valid | PASS | 20/20 checks |
| 2. Narrowing | Phases reduce variance | PASS | 83.8% reduction |
| 3. Tokens | Cache-optimized loading | PASS | 52% fewer tokens |
| 4. Review | Protocol catches more errors | PASS | 5/5 vs 3/5 |
| 5. Drift | Checkpoints prevent drift | PASS | 6/6 ACs vs 4/6 |
| 6. Cascade | Dependencies auto-discovered | PASS | 2 Enablers found |

## Token Budget

| Suite | Tokens Used | Wall Time |
|-------|------------|-----------|
| 1 | 0 (static) | 2s |
| 2 | 570K | 180s |
| 3 | 45K | 30s |
| 4 | 120K | 90s |
| 5 | 280K | 120s |
| 6 | 85K | 60s |
| **Total** | **1.1M** | **~8 min** |

## Conclusion

[Auto-generated: which claims are proven, which need more evidence,
what the token cost of the full test suite is]
```

## Self-Review: Is The Doctrine True?

After running all suites, the framework-test skill performs a self-review
of the doctrine's claims:

```markdown
## Doctrine Claim Verification

| Claim | Tested? | Evidence | Verdict |
|-------|---------|----------|---------|
| Progressive narrowing reduces variance | Yes (Suite 2) | 83.8% reduction | SUPPORTED |
| Spec-as-index saves tokens | Yes (Suite 3) | 52% reduction | SUPPORTED |
| Cache-optimized loading works | Partial (Suite 3) | Measured, needs TTL control | PARTIALLY SUPPORTED |
| Review protocol catches more errors | Yes (Suite 4) | 5/5 vs 3/5 | SUPPORTED |
| Checkpoints prevent drift | Yes (Suite 5) | 6/6 vs 4/6 ACs | SUPPORTED |
| Cascade discovers dependencies | Yes (Suite 6) | 2 Enablers found | SUPPORTED |
| Worktree prevents contamination | Not tested | Need parallel feature test | UNTESTED |

### Unsupported or Weak Claims

[List any claims where the evidence is weak or contradictory.
Intellectual honesty is more valuable than a clean scorecard.]
```

The goal is not to prove everything works perfectly. The goal is to
MEASURE what works, what doesn't, and by how much — so the doctrine
can be refined based on evidence rather than assertion.

## When To Skip Suites

| Situation | Skip | Why |
|-----------|------|-----|
| Quick validation of a new project | Suites 2-6 | Suite 1 is enough for structure checks |
| After doctrine changes | Suite 2, 4, 5 | These test the core claims |
| After adding a new skill | Suite 1 | Verify manifest/cross-refs |
| Full benchmark (rare) | Nothing | Run everything |

## Anti-Patterns

| Don't | Why | Instead |
|-------|-----|---------|
| Run only Suite 1 and claim "tested" | Static checks don't prove behavioral claims | Run at least Suites 2 and 4 for meaningful evidence |
| Cherry-pick passing results | Undermines the methodology's credibility | Report all results including failures |
| Skip the self-review section | The point is intellectual honesty | Always produce the claim verification table |
| Test only the happy path | Failures teach more than successes | Include adversarial tests (Suite 4) |
