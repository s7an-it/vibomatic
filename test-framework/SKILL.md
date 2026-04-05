---
name: test-framework
description: Test and benchmark the vibomatic framework end-to-end. Use when you need to verify the pipeline works, prove doctrine claims, measure token efficiency, validate progressive narrowing, or run the autopilot that continuously tests all skills against real scenarios. Triggers on "test the framework", "prove it works", "benchmark vibomatic", "validate the pipeline", "run autopilot", "test all skills", "check for holes", or any request to verify vibomatic's methodology. Also use when comparing vibomatic against obra/gstack/raw approaches.
inputs:
  required: []
  optional: []
outputs:
  produces:
    - { path: "test-framework/results/", artifact: test-results }
chain:
  lanes: {}
  progressive: false
  self_verify: false
  human_checkpoint: false
---

# Framework Test

End-to-end testing that produces running applications, not documents about running applications. Every test ends with a live server responding to requests, E2E tests executing against it, and a three-way comparison proving vibomatic produces better output than alternatives.

**Announce at start:** "I'm using the test-framework skill to test and benchmark vibomatic."

## Modes

| Mode | Command | What it does |
|------|---------|-------------|
| `static` | `bash scripts/run-all.sh --static-only` | Pipeline integrity, cache measurements, doctrine checks. No LLM. |
| `live` | `bash scripts/run-all.sh --include-live` | Static + spins up server from generated code + runs QA against it. |
| `autopilot` | "Run test-framework autopilot on scenario S1" | Full loop: worktree per scenario, all pipeline skills produce real output, server runs, three-way comparison, self-improvement. Read `references/autopilot-protocol.md` for scenario definitions and KPIs. |
| `comparison` | "Compare vibomatic vs obra vs raw on [feature]" | Three parallel worktrees, same feature three ways, measure delta. |
| `skill-test` | "Test [skill-name] in isolation" | Single skill, multiple variants, real output required. |

## Autopilot Mode

### Worktree Lifecycle

Every scenario runs inside a git worktree. No exceptions.

1. **Open:** `git worktree add /tmp/vibomatic-test-{scenario-id} main`
2. **Work:** All 19 skills execute inside the worktree. All generated code lands there.
3. **Close:** Either merge to main (`git merge`) or create a PR with findings (`gh pr create`). Then `git worktree remove`.

For three-way comparison, open THREE worktrees:
- `/tmp/vibomatic-test-{id}-vibomatic`
- `/tmp/vibomatic-test-{id}-obra`
- `/tmp/vibomatic-test-{id}-raw`

Clean up all worktrees when the scenario completes. Never leave orphaned worktrees.

### The Loop

```
LOOP:
  1.  PICK scenario (start with S1, or auto-suggest based on gaps)
  2.  OPEN worktree from main
  3.  RUN all pipeline skills in pipeline order
      - Phase 7 produces FULL runnable code (all 8 parts)
      - land-changeset writes files into the worktree
  4.  START server
      - cd into worktree
      - npm install (or equivalent)
      - npm start (or node src/index.js)
      - Wait for http://localhost:3000 to respond
      - If server fails to start: fix the code, re-run Phase 7, try again (max 3 attempts)
  5.  TEST live
      - sync-spec-code against actual source files in the worktree
      - test-journeys against the live server
      - write-e2e generates AND RUNS tests against localhost
  6.  COMPARE: obra approach
      - Open second worktree
      - Run brainstorm -> plan -> execute (parallel agents) -> running app
      - Same scenario, same ACs to measure against
  7.  COMPARE: raw approach
      - Open third worktree
      - Single prompt -> code -> running app
      - Same scenario, same ACs to measure against
  8.  MEASURE three-way delta
      - ACs satisfied (count per approach)
      - Edge cases handled (count per approach)
      - Token cost (total per approach)
      - Test coverage (lines/branches if measurable)
      - Time to running server (wall clock per approach)
  9.  FIND gaps in skills
      - Which skills produced weak output?
      - Which handoffs lost information?
      - Which ACs were missed?
  10. FIX: edit SKILL.md, re-run the skill, verify the fix
      - If the fix breaks something else, revert and try differently
      - Max 3 fix attempts per gap before flagging for human review
  11. COMMIT fixes with descriptive message
  12. SUGGEST next scenario based on coverage gaps
  13. CLOSE worktrees (merge or PR), clean up
  -> Repeat until completion criteria met or token budget exhausted
```

### What "Full Running App" Means

Phase 7 (plan-changeset) produces ALL 8 parts. Not just types. Not just a spec. The change set IS the codebase.

| Part | Contents | Required |
|------|----------|----------|
| `part-01-types` | TypeScript interfaces, enums, shared types | Yes |
| `part-02-data-model` | Database migrations, schema files, seed data | Yes |
| `part-03-tests-unit` | Unit tests written BEFORE implementation (TDD) | Yes |
| `part-04-services` | Backend business logic, domain services | Yes |
| `part-05-api-routes` | Route handlers, middleware, validation | Yes |
| `part-06-components` | Frontend components (if the scenario has UI) | If applicable |
| `part-07-tests-e2e` | Playwright E2E test files | Yes |
| `part-08-config` | package.json, tsconfig.json, docker-compose.yml, .env.example | Yes |

land-changeset writes ALL files into the worktree. Then:

```bash
cd /tmp/vibomatic-test-{id}-vibomatic
npm install
npm start &
# Wait for server
for i in $(seq 1 15); do
  curl -sf http://localhost:3000/health > /dev/null && break
  sleep 2
done
```

If the server does not start, that is a bug in the change set. Fix it:
1. Read the error output
2. Identify the failing file
3. Re-run plan-changeset for that part only
4. Try `npm start` again
5. Repeat up to 3 times. If still broken, log the failure with full error output.

### Multi-Approach Comparison

Every scenario produces running applications from multiple approaches. The comparison is only valid if each approach uses its methodology's skills as designed.

#### Fairness Rules

Background agents CANNOT run interactive skills (AskUserQuestion, iterative review loops). Therefore:

1. **Each approach MUST be run in the FOREGROUND as a sequential conversation**, not as a background Agent. The operator plays the user role, answering skill questions naturally based on the scenario context.
2. **Every skill invocation MUST use the Skill tool**, not inline approximation. If an agent "brainstorms" without invoking `superpowers:brainstorming`, that is NOT a fair test of the superpowers methodology.
3. **Log every skill invoked** with: skill name, input summary (what was passed), output summary (what was produced), and whether the skill asked questions (and what the operator answered).
4. **If a methodology's skill cannot be invoked** (missing dependency, tool not available), record it as SKIPPED with reason — do not approximate it inline.

#### Approach Definitions

**Approach 1 -- Vibomatic (full 19-skill pipeline):**
- Run all pipeline skills in pipeline order using the Skill tool
- Each skill reads prior phase artifacts from the worktree
- Server runs on port 3000
- **Verification requirement:** Skills 14-18 (verify-promotion, sync-spec-code, test-journeys, write-e2e, analyze-marketing) MUST be run, not skipped

**Approach 2 -- gstack (office-hours + review pipeline):**
- Invoke `/office-hours` with the scenario prompt — answer the 6 forcing questions naturally
- Invoke `/design-consultation` to create DESIGN.md
- Invoke `/autoplan` OR `/plan-ceo-review` → `/plan-design-review` → `/plan-eng-review` sequentially
- Write code guided by the reviewed plan
- Invoke `/qa` against the running server
- Invoke `/review` on the diff
- Server runs on port 3001
- **Log:** Each skill invocation, what questions it asked, what the operator answered

**Approach 3 -- Obra/Superpowers (brainstorm-plan-execute):**
- Invoke `superpowers:brainstorming` — answer clarifying questions naturally, approve design
- Invoke `superpowers:writing-plans` with the brainstorm output
- Invoke `superpowers:test-driven-development` — write failing tests BEFORE implementation
- Invoke `superpowers:executing-plans` with the plan
- Invoke `superpowers:requesting-code-review` on the result
- Invoke `superpowers:verification-before-completion` before declaring done
- Server runs on port 3002
- **Log:** Each skill invocation and its output

**Approach 4 -- Raw (single prompt):**
- One prompt: "Build [scenario description]. Produce a complete, runnable Node.js application."
- No methodology, no phases, no review, no skills
- Server runs on port 3003

#### Universal Expectations (Phase 0)

BEFORE running any approach, derive a checklist of what a user who typed the scenario prompt would expect to see. This checklist must:
- Be derived ONLY from the user's sentence, not from any methodology's specs
- Include sub-items that are independently scorable (1 = met, 0 = not met)
- Cover: does it run, does it show the right data, does it do the core thing, does it address every explicit requirement in the prompt, is it usable on first visit
- Be written to `test-framework/results/{date}/phase-0-expectations.md` BEFORE any approach runs

#### Measurements (per approach)

| Metric | How to measure |
|--------|---------------|
| Universal score | Phase 0 checklist pass rate |
| Skills invoked | Count of methodology skills actually invoked via Skill tool |
| Skills skipped | Count of methodology skills not invoked, with reason |
| ACs satisfied | Check each AC from the vibomatic spec against the running server |
| Vision-to-code traceability | Suite 9 score |
| First-time UX | Suite 8 pass/fail |
| Test coverage | Run unit tests, report pass/fail counts |
| Time to running server | Wall clock from first prompt to server responding |
| Code structure | Count files, modules, separation of concerns |
| Files produced | Total source files (src + views) |
| LOC | Lines of code in source files |

#### Methodology Usage Audit

After all approaches complete, produce `methodology-usage-audit.md` with:
- For each approach: recommended workflow (from that methodology's docs) vs actual workflow (what was invoked)
- Skill-by-skill table: recommended → invoked? → input → output
- Fairness verdict: FAIR / PARTIALLY FAIR / UNFAIR with explanation
- If any approach is UNFAIR, the comparison results for that approach carry a caveat

**Report format:** Side-by-side table in `comparison.json` and `comparison.md`. Include the methodology usage audit as a section. The comparison is only credible if the audit shows all approaches were fairly tested.

### Self-Improvement Protocol

When the autopilot finds a gap:

1. **Identify** which skill's SKILL.md has the deficiency
2. **Edit** the SKILL.md file directly (use the Edit tool)
3. **Re-run** that specific skill on the current scenario
4. **Verify** the gap is closed (the output now handles the case)
5. **Commit** with message: `fix({skill-name}): {what was wrong and how it's fixed}`
6. **If the fix breaks a downstream skill:** revert the edit, analyze why, try a different approach
7. **If 3 attempts fail:** log the gap as `NEEDS-HUMAN-REVIEW` with full context

Fixes are real commits, not documentation. The autopilot improves vibomatic's skills as it tests them.

## Doctrine Claims -- ALL Testable

Every doctrine claim has a concrete test that produces numerical evidence. No claim is "structurally untestable." If it cannot be tested, downgrade or remove it from the doctrine.

| # | Claim | Test Method | Pass Criteria |
|---|-------|-------------|---------------|
| C1 | Progressive narrowing reduces output variance | Run the SAME scenario 3x with full pipeline and 3x with single prompt. Diff the outputs pairwise within each group. | Full-pipeline pairwise diffs < single-prompt pairwise diffs |
| C2 | Spec-as-index reduces token usage | On a brownfield project: count tokens to load all files in `src/`. Count tokens to load only files referenced by spec RESOLVED annotations. Report ratio. | Spec-indexed tokens < 50% of full-codebase tokens |
| C3 | Cache-optimized loading order | Load artifacts in doctrine-prescribed order (most-stable-first) across 3 sequential sub-agent tasks. Load same artifacts in random order across 3 tasks. Compare `total_tokens` from task notifications -- cache hits show as lower input tokens on requests 2-3. | Prescribed-order total_tokens < random-order total_tokens across runs 2-3 |
| C4 | Review protocol catches errors single-pass misses | Plant 5 known errors in a spec (contradicting ACs, invalid references, untestable criteria, compound stories, ungrounded preconditions). Run single-pass review. Run full review-gate (self-review + self-judgment + cross-review). Count detections. | Full protocol detects more planted errors than single-pass |
| C5 | Checkpoints prevent cumulative drift | Run 3-task implementation (types, service, handler) WITHOUT checkpoints (one agent, no spec re-reads between tasks). Run WITH checkpoints (separate agent per task, each re-reads spec first). Compare final AC compliance. | Checkpoint version satisfies more ACs |
| C6 | Feature/Enabler/Integration cascade discovers full chain | Give write-spec a Feature. Check if write-journeys Layer 3 identifies Enabler dependencies. Check if write-spec queues cascade specs. | At least 2 Enabler dependencies auto-discovered without manual prompting |
| C7 | Worktree isolation prevents cross-feature contamination | Run TWO features in parallel worktrees simultaneously. After both complete, check: (a) no files modified in both worktrees that shouldn't be, (b) no shared state leakage, (c) each worktree's git status is clean relative to its own changes only. | Zero unexpected shared-file modifications. Each worktree contains only its own feature's changes. |

**For C3:** Use `total_tokens` from sub-agent task notification results as the measurement proxy. If Claude Code does not surface this field, instrument the test with a wrapper that logs token counts from the Anthropic API response headers.

**For C7:** Use the `worktree-manager` skill to create two worktrees. Dispatch parallel agents (one per worktree) using `superpowers:dispatching-parallel-agents`. This is infrastructure the framework already provides -- use it.

## Test Suites

### Suite 1: Pipeline Integrity (Static)

Validates all artifacts exist and cross-reference correctly.

```bash
bash scripts/validate-pipeline-integrity.sh <project-root>
```

Checks: all SKILL.md files exist, manifest matches directories, AC IDs are consistent across specs/journeys, RESOLVED annotations point to real files, UX/UI designs reference valid specs.

### Suite 2: Progressive Narrowing (C1)

Dispatch 6 sub-agents in parallel:
- 3 agents: single prompt -> code (no methodology)
- 3 agents: full vibomatic pipeline -> code

Diff outputs pairwise within each group. Report variance reduction with confidence interval.

The output is RUNNING CODE, not spec documents. Each agent produces files that compile and start.

### Suite 3: Token Efficiency (C2, C3)

**C2:** Count tokens for full `src/` load vs spec-referenced-only load on a real brownfield project. Report ratio.

**C3:** Run 3 sequential sub-agent tasks with prescribed artifact order. Run 3 with random order. Compare total_tokens across the second and third requests in each series.

### Suite 4: Review Protocol Effectiveness (C4)

Plant 5 known errors in a feature spec. Run single-pass review. Run full review-gate. Count detections. The test is adversarial -- it tries to break the review process.

### Suite 5: Checkpoint Drift (C5)

3-task implementation with and without checkpoints. Measure AC compliance at the end. The implementation must COMPILE AND RUN -- not just exist as text.

### Suite 6: Cascade Discovery (C6)

Give write-spec a Feature. Verify that Enabler dependencies are discovered automatically. The cascade must produce additional specs, not just a note saying dependencies exist.

### Suite 7: Worktree Isolation (C7)

Two features, two worktrees, parallel execution. Verify zero cross-contamination. This suite uses real git worktrees and real parallel agents.

## Suite 8: First-Time User Experience

After the server starts, test the FIRST VISIT experience with no profile, no login, no setup:

1. `curl http://localhost:{port}/` — does the homepage show useful content without requiring any user action?
2. Are all vision-level product concepts visible in the UI? (Check vision doc sections 3-4 against what the homepage shows.)
3. Can a user understand what the app does within 5 seconds of landing?

If the first visit shows "No data" or requires setup before showing value, that is a FAILURE of the pipeline. Flag it as a skill gap in write-spec (missing zero-state AC).

## Suite 9: Vision-to-Code Traceability

The most dangerous pipeline failure is information loss at phase boundaries. This suite catches it.

1. Read `docs/specs/vision.md` sections 3 (Who We Serve), 4 (Value Proposition), and 6 (Boundaries).
2. Extract every distinct product concept that implies user-visible behavior (deployment modes, persona types, platform sources, pricing, privacy).
3. For each concept, grep the `src/` directory for evidence it's implemented in code.
4. Score: concepts with code evidence / total concepts.

**Pass criteria:** >= 80% of vision concepts have code evidence. Any concept at 0% is a critical finding — it means the pipeline translated the user's requirement into a spec but then lost it during code generation.

**Root cause mapping for failures:**
- Concept in vision but NOT in spec ACs → write-spec missed it during vision-to-spec traceability
- Concept in spec ACs but NOT in code → plan-changeset missed it during vision cross-check
- Concept in code but NOT working at runtime → land-changeset or verify-promotion gap

## Completion Criteria

The autopilot is DONE when ALL of these are true:

- [ ] All 19 skills produced REAL output (no simulations, no outlines, no "interface-tier" hedging)
- [ ] Server runs and responds to HTTP requests from generated code
- [ ] E2E tests execute against the live server (pass or fail -- but they RUN)
- [ ] First-time user experience test passes (useful content on first visit without setup)
- [ ] Three-way comparison completed (vibomatic vs obra vs raw) with numerical results
- [ ] At least 1 SKILL.md improvement committed (a real fix, not a formatting change)
- [ ] All 7 doctrine claims tested with numerical evidence
- [ ] Worktree opened and closed cleanly for every scenario
- [ ] At least 2 scenarios completed (1 greenfield, 1 iteration)
- [ ] Results written to `test-framework/results/` with timestamps
- [ ] Comprehensive comparison report produced

## Anti-Patterns

| Do NOT | Why | Instead |
|--------|-----|---------|
| Call a skill "simulated" or "interface-tested" | If it cannot run, the pipeline has a bug | Fix the pipeline so the skill runs for real |
| Produce specs without code | The point is a running application | Phase 7 must generate all 8 code parts |
| Document gaps instead of fixing them | Documentation is not improvement | Edit the SKILL.md, re-run, verify |
| Skip the three-way comparison | The comparison IS the value proposition | Always run vibomatic vs obra vs raw |
| Leave worktrees unclosed | Orphaned worktrees accumulate and confuse | Always clean up: merge, PR, or remove |
| Hedge with "may," "could consider," "if possible" | Tests are pass/fail, not suggestions | State what MUST happen, then do it |
| Report "STRUCTURALLY UNTESTABLE" | Everything is testable with the right infrastructure | Build the infrastructure or downgrade the claim |
| Run only static checks and call it "tested" | Static checks prove structure, not behavior | Run live tests against running code |

## Convert Mode Testing

Bootstrap (greenfield) and convert (iteration) exercise different skill behaviors. Test both.

| Skill | Bootstrap | Convert | Key difference |
|-------|-----------|---------|----------------|
| write-vision | Create from scratch | Proposal with Evidence Table + Approval Gate | Never overwrites existing |
| build-personas | Mode 7 (Auto-Discovery) | Mode 3 (Add New) or Mode 4 (Expand) | Incremental |
| validate-feature | No existing specs | Cross-validates against existing ACs | Validates before creating |
| write-spec | Clean slate | References existing ACs across features | Cross-feature references |
| sync-spec-code | Nothing to sync | Checks existing VERIFIED specs for drift | Finds real inconsistencies |
| write-journeys | Mode 1 (Bootstrap) | Mode 2 (Expand) with prerequisite chaining | Extends, does not replace |

Run at least one convert-mode scenario (S3: add real-time collab to todo-api) to cover these behaviors.

## Statistical Rigor

Single runs prove nothing. For any generative suite, run N times (default N=3) and report:

- Mean, standard deviation, 95% confidence interval
- Effect size (Cohen's d): < 0.2 negligible, 0.2-0.5 small, 0.5-0.8 medium, > 0.8 large
- If CI crosses the null hypothesis, increase N and re-run

A claim is SUPPORTED only when the 95% CI lower bound is on the correct side of the null hypothesis. Otherwise the result is INCONCLUSIVE and requires more runs.

## Results Format

```
test-framework/results/YYYY-MM-DD-HHMMSS/
  scenario-{id}/
    vibomatic/
      worktree-path.txt       <- path to worktree used
      phase-*/                <- artifacts from each phase
      server-log.txt          <- stdout/stderr from npm start
      metrics.json            <- per-skill token/time/artifact counts
    obra/
      worktree-path.txt
      server-log.txt
      metrics.json
    raw/
      worktree-path.txt
      server-log.txt
      metrics.json
    comparison.json           <- three-way metrics
    comparison.md             <- human-readable comparison
    e2e-results.json          <- Playwright test results per approach
  aggregate/
    all-scenarios.json
    doctrine-evidence.json    <- claim-by-claim numerical evidence
    skill-coverage.json       <- 19/19 must be REAL, not simulated
    improvements.json         <- SKILL.md edits made during this run
```

## References

- `references/autopilot-protocol.md` -- Scenario definitions, user simulation rules, KPIs, full invocation order, loop control
- `DOCTRINE.md` -- The claims this skill tests
- `skills-manifest.json` -- Canonical list of all pipeline skills
