---
name: framework-test
description: Test and benchmark the vibomatic framework end-to-end. Use when you need to verify the pipeline works, prove doctrine claims, measure token efficiency, validate progressive narrowing, or run the autopilot that continuously tests all skills against real scenarios. Triggers on "test the framework", "prove it works", "benchmark vibomatic", "validate the pipeline", "run autopilot", "test all skills", "check for holes", or any request to verify vibomatic's methodology. Also use when comparing vibomatic against obra/gstack/raw approaches.
---

# Framework Test

End-to-end testing and benchmarking for the vibomatic doctrine. This skill
verifies that the methodology works as claimed — not by assertion, but by
measurement.

**Announce at start:** "I'm using the framework-test skill to test and benchmark vibomatic."

## Modes

| Mode | Command | What it does |
|------|---------|-------------|
| `static` | `bash scripts/run-all.sh --static-only` | Pipeline integrity, cache measurements, doctrine checks. No LLM. |
| `live` | `bash scripts/run-all.sh --include-live` | Static + spins up server + runs QA against it. |
| `autopilot` | "Run framework-test autopilot on scenario S1" | Full loop: execute vibomatic pipeline, simulate user, measure, compare, analyze. Read `references/autopilot-protocol.md` for details. |
| `comparison` | "Compare vibomatic vs raw on [feature]" | Same feature two ways, measure delta. |
| `skill-test` | "Test [skill-name] in isolation" | Single skill, multiple variants (with/without agent). |

### Autopilot Mode

The autopilot runs vibomatic end-to-end on a real scenario, playing the user
when skills ask questions, measuring every metric at every phase, then comparing
against a baseline (raw approach with no methodology).

**Read `references/autopilot-protocol.md`** for the full protocol including:
- Built-in scenarios (5 ready to use)
- User simulation rules
- KPIs and metrics (per-skill, per-phase, comparison, glue, doctrine)
- Output structure
- Loop control (when to stop, what to run next)

**To start autopilot:**

```
Run framework-test autopilot on scenario S1
```

The autopilot is a **continuous self-healing loop**, not a one-shot runner.

```
LOOP:
  1. PICK scenario (start with S1, or auto-suggest based on gaps)
  2. RUN all 19 skills in pipeline order on the scenario
     - Play the user when skills ask questions
     - Record metrics at every phase boundary
  3. CHECK every skill-to-skill handoff (glue check)
     - Does writing-spec output what writing-ux-design expects?
     - Does each skill reference the previous skill's artifacts?
     - Are all AC IDs traceable from spec → journey → E2E?
  4. FIND gaps
     - Missing artifacts? Broken cross-references? Skill produced nothing?
     - Skill asked a question the user-simulator couldn't answer?
     - Doctrine claim unsupported by this run's data?
  5. FIX gaps
     - If a skill's SKILL.md has a gap → suggest the edit, apply it, re-run THAT skill
     - If glue is broken between skill A → B → update A's routing or B's prerequisites
     - If a doctrine claim fails → flag it honestly, don't paper over it
  6. VERIFY fixes
     - Re-run the specific skill that was fixed
     - Re-check the glue at that boundary
     - Confirm the gap is closed
  7. COMPARE against raw baseline
     - Same scenario, single prompt, no methodology
     - Measure: ACs, enablers, tokens, edge cases, structure
  8. ANALYZE
     - What worked, what didn't, token cost at each phase
     - Which skills are strong, which are weak
     - What the doctrine gets right, what needs revision
  9. SUGGEST next scenario
     - If a skill was never tested → suggest scenario that exercises it
     - If a glue boundary failed → suggest scenario that stresses it
     - If all skills passed → suggest adversarial scenario
  10. CONTINUE or STOP
     - Continue if: uncovered skills, unverified claims, or fixes to verify
     - Stop if: all 19 skills tested + all glue checks pass + all claims verified
       OR token budget exhausted
     - On stop: produce final comprehensive report
```

The loop is the skill. It doesn't report findings and wait — it finds, fixes,
verifies, and moves on. The agent IS the QA team running continuously.

**No CI, no API tokens needed.** Everything runs locally through Claude Code
sub-agents. The LLM IS the test runner — it reads skills, executes them,
observes outputs, fixes problems, and measures results.

### What "fix" means

The autopilot can fix three categories of issues:

| Category | Example | Fix Action |
|----------|---------|------------|
| Skill gap | writing-ux-design doesn't check for Enabler type (skips it wrongly) | Edit SKILL.md to handle Enabler UX (admin/monitoring screens) |
| Glue gap | writing-spec outputs AC IDs as `AC-1.1` but journey-sync expects `FEAT-01` format | Update writing-spec's AC prefix convention or journey-sync's parser |
| Doctrine gap | Claim C3 (cache optimization) can't be verified from this run | Add a measurement step to the protocol, or flag claim as unverifiable locally |

For skill and glue fixes: the autopilot edits the SKILL.md, re-runs the
affected phase, and verifies the fix. For doctrine gaps: it updates the
findings document honestly.

### What "suggest next scenario" means

After each scenario, the autopilot looks at skill coverage:

```
Skills exercised this run: 15/19
Missing: journey-qa-ac-testing, agentic-e2e-playwright, feature-marketing-insights, promoting-change-set
→ Suggest: scenario that produces runnable code (so QA and E2E can execute against live server)
→ Suggest: scenario with marketing angle (so feature-marketing-insights runs)
```

It also looks at boundary coverage:

```
Glue boundaries tested: 8/11
Missing: writing-change-set → promoting-change-set, promoting → verifying, review-protocol at G5
→ Suggest: scenario that goes all the way to implementation + promotion
```

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

## Automated Test Runner

The full test suite runs end-to-end without manual intervention. The runner:
1. Spins up a test server from generated code
2. Runs all static suites
3. Runs generative suites via sub-agents
4. Runs live QA against the server
5. Aggregates results
6. Shuts down the server

```bash
bash framework-test/scripts/run-all.sh [--static-only] [--include-live] [--runs N]
```

### Server Lifecycle

The runner auto-generates a test server if none exists:

```bash
# 1. Check if a server exists from previous test runs
if [ -d /tmp/vibomatic-test-server ]; then
  cd /tmp/vibomatic-test-server && node src/index.js &
else
  # 2. Use vibomatic's own pipeline to generate one
  #    (or use the raw comparison output if available)
  cp -r /tmp/vibomatic-test-raw /tmp/vibomatic-test-server 2>/dev/null || \
  cp -r examples/todo-api /tmp/vibomatic-test-server
  cd /tmp/vibomatic-test-server && node src/index.js &
fi
SERVER_PID=$!

# 3. Wait for server ready
for i in $(seq 1 10); do
  curl -s http://localhost:3000/todos > /dev/null 2>&1 && break
  sleep 1
done

# 4. Run tests...

# 5. Cleanup
kill $SERVER_PID 2>/dev/null
```

## Statistical Rigor

Single runs prove nothing — they might be lucky. Statistical claims require
multiple runs with variance reporting.

### Multiple-Run Protocol

For any generative suite (2-7), run N times (default N=3) and report:

```json
{
  "suite": "progressive-narrowing",
  "runs": 3,
  "results": [
    { "run": 1, "variance_reduction": 78.2 },
    { "run": 2, "variance_reduction": 85.1 },
    { "run": 3, "variance_reduction": 81.5 }
  ],
  "statistics": {
    "mean": 81.6,
    "std_dev": 3.5,
    "confidence_interval_95": [74.9, 88.3],
    "min": 78.2,
    "max": 85.1,
    "n": 3
  },
  "pass": true,
  "pass_criteria": "lower bound of 95% CI > 0 (variance reduction is positive)"
}
```

### Confidence Intervals

For claims to be SUPPORTED, the 95% confidence interval must not cross the
null hypothesis:

| Claim | Null Hypothesis | CI Must Not Cross |
|-------|----------------|-------------------|
| C1: Narrowing reduces variance | variance_reduction = 0 | CI lower bound > 0% |
| C2: Spec-as-index saves tokens | token_ratio = 1.0 | CI upper bound < 1.0 |
| C4: Protocol catches more | detection_delta = 0 | CI lower bound > 0 |
| C5: Checkpoints prevent drift | ac_delta = 0 | CI lower bound > 0 |

For N=3, confidence intervals are wide. The runner recommends increasing N
when CI crosses the null: "Result is inconclusive at N=3. Run with --runs 5
for tighter bounds."

### Effect Size

Raw numbers can be misleading. Report Cohen's d for each comparison:

```
d = (mean_vibomatic - mean_baseline) / pooled_std_dev

d < 0.2  → negligible effect (claim is weak)
d 0.2-0.5 → small effect (claim is marginal)
d 0.5-0.8 → medium effect (claim is supported)
d > 0.8  → large effect (claim is strongly supported)
```

## Self-Evolving Test Coverage

The framework-test skill uses vibomatic's own pipeline to evolve its test
coverage. This is self-referential by design — the system tests itself using
its own methodology.

### How It Works

1. **After each test run**, the framework-test skill reads the results and
   identifies gaps:
   - Claims with wide confidence intervals → need more runs
   - Claims with UNTESTED status → need new test scenarios
   - Suites that always pass → might be too easy (non-discriminating)
   - Suites that always fail → might have bugs in the test itself

2. **To generate new test scenarios**, the skill invokes writing-spec:
   ```
   "Using writing-spec, define a feature that would stress-test [weak claim].
   The feature should exercise [specific aspect] in a way that could
   falsify the claim if it's wrong."
   ```

3. **The new scenario becomes a test case.** The writing-spec output is a
   feature spec. The test runner uses it as input for the relevant suite.

4. **Results feed back** into the findings document and the doctrine's
   claim verification table.

### Evolution Triggers

| Trigger | Action |
|---------|--------|
| New skill added to vibomatic | Generate test scenario for the new skill |
| Doctrine claim modified | Re-run relevant suite with increased N |
| Test suite always passes (>5 runs) | Generate adversarial scenario designed to fail |
| CI crosses null hypothesis | Increase N or generate discriminating scenario |
| New feature type discovered | Add cascade test for that type |

### Self-Test Integrity

The evolution process itself must be trustworthy:

1. **New scenarios are reviewed** before being added to the test suite
   (using the review-protocol skill).
2. **Results are append-only** — previous results are never modified,
   only new results are added. Historical comparison shows trends.
3. **The framework-test skill's own SKILL.md is versioned** with the
   same checkpoint system. Changes to the test skill require their own
   review gate.

## Integration with CI

For projects using vibomatic in CI/CD:

```yaml
# .github/workflows/vibomatic-test.yml
name: Vibomatic Pipeline Validation
on: [push, pull_request]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Static validation
        run: bash framework-test/scripts/validate-pipeline-integrity.sh .
      - name: Skill pack consistency
        run: |
          DIRS=$(find . -name "SKILL.md" -not -path "./.git/*" | wc -l)
          MANIFEST=$(python3 -c "import json; print(len(json.load(open('skills-manifest.json'))['includedSkills']))")
          [ "$DIRS" -eq "$MANIFEST" ] || exit 1
```

Static validation runs in CI without tokens. Generative tests run on-demand
or on a schedule (they cost tokens).

## Bootstrapping From Zero

If no test infrastructure exists, the framework-test skill bootstraps itself:

```
1. Read DOCTRINE.md → extract claims
2. For each claim → generate minimal test scenario using writing-spec
3. Run static validation on the generated artifacts
4. Run one generative suite (Suite 2: narrowing — the core claim)
5. Report results
6. Recommend which suites to run next based on findings
```

This means framework-test works on ANY project using vibomatic — not just
the todo-api example. It generates its own test scenarios from the project's
actual specs and code.
