# Autopilot Protocol

The autopilot is a continuous loop that runs vibomatic end-to-end on real
scenarios, playing the user when questions arise, measuring every metric,
and comparing against baselines (raw, obra, gstack).

## How It Works

```
OUTER LOOP (per scenario):
  1. PICK         → choose scenario (built-in or auto-suggested from gaps)
  2. EXECUTE      → run ALL 19 skills in pipeline order (simulate user for questions)
  3. MEASURE      → collect per-skill metrics (tokens, time, artifacts, ACs)
  4. GLUE CHECK   → verify every skill-to-skill handoff (references, formats, IDs)
  5. FIND GAPS    → missing artifacts, broken references, unsupported claims

  INNER LOOP (per gap found):
    5a. DIAGNOSE  → which skill has the problem? What's wrong?
    5b. FIX       → edit the SKILL.md to close the gap
    5c. RE-RUN    → re-execute the fixed skill on this scenario
    5d. VERIFY    → did the fix close the gap? If not, back to 5a (max 3 attempts)

  6. COMPARE      → run same scenario as raw baseline, measure delta
  7. ANALYZE      → comprehensive report: what works, what's weak, token costs
  8. SUGGEST NEXT → auto-pick next scenario based on coverage gaps
  → repeat OUTER LOOP until:
     - ALL 19 skills tested with at least 1 scenario each
     - ALL 11 glue boundaries verified (skill A → skill B handoffs)
     - ALL 7 doctrine claims have supporting evidence
     - OR token budget exhausted
     - OR 3 consecutive scenarios with zero new findings
```

## Scenarios

### Scenario Types

| Type | Description | Tests |
|------|-------------|-------|
| `greenfield` | Start from zero, user gives high-level goal | Full pipeline, cascade, all phases |
| `iteration` | Add feature to existing project | Convert mode, preserve existing |
| `adversarial` | Intentionally ambiguous/complex request | Edge cases, error handling |
| `comparison` | Same feature via vibomatic vs raw vs obra | Quality/cost tradeoff |
| `skill-isolation` | Test one specific skill deeply | Skill-specific edge cases |

### Built-in Scenarios

```json
[
  {
    "id": "S1",
    "type": "greenfield",
    "prompt": "I want to make an app that suggests what to learn for AI based on what is trendy in social platforms today. It should be free and self-hostable, or users can pay to have it hosted.",
    "complexity": "high",
    "expected_features": ["trend scraping", "content recommendation", "user accounts", "payment/hosting"],
    "expected_enablers": ["scraping service", "recommendation engine", "payment integration"],
    "expected_integrations": ["social media APIs", "payment provider"]
  },
  {
    "id": "S2",
    "type": "greenfield",
    "prompt": "Build a team retrospective tool where team members submit feedback anonymously, an AI summarizes themes, and the manager gets action items.",
    "complexity": "medium",
    "expected_features": ["anonymous submission", "AI summary", "action items dashboard"],
    "expected_enablers": ["LLM summarization service"],
    "expected_integrations": ["LLM API"]
  },
  {
    "id": "S3",
    "type": "iteration",
    "prompt": "Add real-time collaboration to the existing todo-api — multiple users can see each other's changes live.",
    "complexity": "medium",
    "base_project": "examples/todo-api",
    "expected_enablers": ["websocket service", "presence tracking"]
  },
  {
    "id": "S4",
    "type": "adversarial",
    "prompt": "Make it faster and better.",
    "complexity": "ambiguous",
    "expected_behavior": "Skill should ask clarifying questions, not proceed blindly"
  },
  {
    "id": "S5",
    "type": "skill-isolation",
    "prompt": "Run each vibomatic skill on the todo-api and report what each produces.",
    "complexity": "systematic",
    "skills_to_test": "all"
  }
]
```

## User Simulation

When a vibomatic skill asks a question (feature-discovery business questions,
brainstorming clarifications, review approvals), the autopilot responds as
the user based on the scenario context.

### Response Strategy

The autopilot uses the scenario's prompt and expected outputs to generate
reasonable user responses:

```
Skill asks: "What personas will use this feature?"
Scenario context: AI learning app, self-hostable
Autopilot responds: "Two main users — individual learners who self-host 
for free, and teams/companies who pay for hosted version."
```

### Response Rules

1. Stay consistent with the scenario prompt — don't invent new requirements
2. When asked for preferences, choose the simpler option (faster testing)
3. When asked for approval, approve if the output looks reasonable
4. When asked to clarify ambiguity, provide ONE clear answer (don't ramble)
5. Log every simulated response for review

## KPIs and Metrics

### Per-Skill Metrics

| Metric | How | Why |
|--------|-----|-----|
| `tokens_consumed` | Task notification total_tokens | Cost per skill invocation |
| `wall_time_ms` | Task notification duration_ms | Latency per skill |
| `artifacts_produced` | Count output files | Productivity measure |
| `ac_count` | Count AC rows in produced specs | Specificity measure |
| `cascade_depth` | Count Feature→Enabler→Integration chain | Dependency discovery depth |
| `cross_references` | Count links between artifacts | Glue quality |
| `errors_in_output` | Review-protocol findings on output | Quality measure |

### Per-Phase Metrics

| Metric | How | Why |
|--------|-----|-----|
| `phase_context_tokens` | Count lines loaded per phase | Cache efficiency |
| `phase_artifacts_read` | Count files read | Loading discipline |
| `phase_code_loaded` | Whether code was loaded in Phases 3-6 | Spec-as-index compliance |
| `handoff_integrity` | Does output match next phase's expected input | Glue check |

### Comparison Metrics

| Metric | Vibomatic | Baseline | Delta |
|--------|-----------|----------|-------|
| `total_tokens` | N | N | ratio |
| `total_time` | N | N | ratio |
| `ac_count` | N | 0 | absolute |
| `enabler_separation` | yes/no | yes/no | boolean |
| `cascade_discovered` | N specs | 0 | absolute |
| `edge_cases_caught` | N | N | delta |
| `drift_findings` | N | N/A | absolute |

### Glue Metrics (Skill-to-Skill)

These verify the pipeline has no holes:

| Transition | Check |
|------------|-------|
| writing-spec → writing-ux-design | UX design references spec AC IDs |
| writing-ux-design → writing-ui-design | UI design references UX screens |
| writing-ui-design → writing-technical-design | Tech design references UI components |
| writing-technical-design → writing-change-set | Change set covers all tech design components |
| writing-change-set → promoting-change-set | Manifest lists all changed files |
| promoting-change-set → verifying-promotion | spec-code-sync finds the RESOLVED items |
| review-protocol at each gate | Findings are actionable, not theater |

### Doctrine Verification

| Claim | Metric | Pass Criteria |
|-------|--------|--------------|
| C1: Progressive narrowing | variance across 2 runs | vibomatic variance < raw variance |
| C2: Spec-as-index | phase 3-6 code loading | zero code files loaded before Phase 7 |
| C3: Cache optimization | shared prefix length | > 60% prefix overlap across tasks |
| C4: Review catches more | findings count | protocol > single-pass |
| C5: Checkpoints prevent drift | AC match rate | with-checkpoint >= without |
| C6: Cascade discovery | enabler count | >= 1 enabler auto-discovered |
| C7: Worktree isolation | shared file changes | zero cross-contamination |

## Output Structure

```
framework-test/results/YYYY-MM-DD-HHMMSS/
  scenario-S1/
    vibomatic/
      phase-3-spec/           ← artifacts from each phase
      phase-4-ux/
      phase-5-ui/
      phase-6-tech/
      phase-7-code/
      metrics.json            ← per-skill token/time/artifact counts
      glue-check.json         ← skill-to-skill handoff verification
      user-responses.json     ← simulated user responses logged
    baseline/
      raw-output/             ← same scenario without vibomatic
      metrics.json
    comparison.json           ← side-by-side metrics
    analysis.md               ← what worked, what didn't, recommendations
  scenario-S2/
    ...
  aggregate/
    all-scenarios.json        ← combined metrics across all scenarios
    doctrine-verification.json ← claim-by-claim evidence
    skill-coverage.json       ← which skills tested, which gaps remain
    recommendations.md        ← improvements to make based on findings
```

## Full Skill Invocation Order

When running a scenario, execute ALL 19 skills in this order:

| # | Skill | Phase | Input | Output |
|---|-------|-------|-------|--------|
| 1 | `vision-sync` | Foundational | Scenario prompt | `docs/specs/vision.md` |
| 2 | `persona-builder` | Foundational | Vision | `docs/specs/personas/P*.md` |
| 3 | `workflow-compass` | Routing | Project state | Confirms next skill |
| 4 | `feature-discovery` | Discovery | Vision + personas + prompt | Feature Ship Brief |
| 5 | `writing-spec` | Phase 3 | Ship Brief | Feature spec (DRAFT) + cascade specs |
| 6 | `spec-ac-sync` | Phase 3 | Feature specs | Audited AC tables |
| 7 | `journey-sync` | Phase 3 | Specs + personas | Journey docs (J*.feature.md) |
| 8 | `writing-ux-design` | Phase 4 | DRAFT spec + personas + journeys | UX design doc |
| 9 | `writing-ui-design` | Phase 5 | UX design + spec | UI design doc + design-system.md |
| 10 | `writing-technical-design` | Phase 6 | DESIGNED spec + all designs | BASELINED spec |
| 11 | `review-protocol` | Gate G4 | BASELINED spec | Findings (self + cross) |
| 12 | `writing-change-set` | Phase 7 | BASELINED spec + designs | Code in worktree + manifest |
| 13 | `promoting-change-set` | Phase 8 | Change set | Promoted code on branch |
| 14 | `verifying-promotion` | Phase 9 | Promoted code + specs | Verification report |
| 15 | `spec-code-sync` | Verification | Specs + code | RESOLVED/DRIFT annotations |
| 16 | `journey-qa-ac-testing` | Verification | Journeys + live server | QA column updates |
| 17 | `agentic-e2e-playwright` | Verification | Journeys + ACs | E2E test files |
| 18 | `feature-marketing-insights` | Marketing | Feature specs | Marketing context doc |
| 19 | `framework-test` | Meta | All outputs | Coverage + metrics report |

For skills 16 (journey-qa-ac-testing): spin up the server from Phase 7 code first.
For skill 18 (feature-marketing-insights): run Mode 4 (Foundation) then Mode 2 (Single Feature).
After skill 18: document how the coreyhaines external marketing pack would consume the output.

## Completion Criteria

The autopilot is DONE when ALL of these are true:

```
□ All 19 skills invoked at least once with real output
□ All 11 glue boundaries verified (skill A → B handoffs)
□ All 7 doctrine claims have evidence (SUPPORTED or REFUTED — honest either way)
□ At least 2 different scenarios completed (exercises different feature types)
□ At least 1 iteration scenario (adding to existing project)
□ Marketing interop documented (how external packs consume vibomatic output)
□ Raw baseline comparison completed for at least 1 scenario
□ Zero critical glue gaps remaining (all fixed or flagged with justification)
□ Comprehensive analysis.md produced
```

If a criterion cannot be met (e.g., live server QA needs a framework the
scenario doesn't use), document WHY and count it as a justified skip.

## Loop Control

The autopilot runs until completion criteria are met or:
- Token budget exhausted (report what was achieved and what remains)
- User interrupts (save state, report progress)
- 3 consecutive scenarios with zero new findings (satisfied — stop)

After each scenario, decide what to run next:
1. If a skill was never tested → pick scenario that exercises it
2. If a glue boundary failed → re-run the two adjacent skills after fix
3. If all skills passed → generate adversarial scenario (ambiguous prompt, edge case)
4. If iteration mode untested → run scenario S3 (add feature to existing project)
5. If marketing untested → run scenario with B2B angle (exercises marketing insights)
6. If token budget is low → run only static checks + report remaining gaps
