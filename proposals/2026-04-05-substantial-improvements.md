# Substantial Improvement Proposals

Not housekeeping. Architectural changes that make the pipeline fundamentally better.

---

## P1: Collapse the Pre-Implementation Stack (HIGH IMPACT)

### Problem

The greenfield lane has 14 skills before code starts. That's 14 LLM sessions
producing documents that reference each other. By the time `executing-change-set`
fires, the accumulated context is massive and the early documents (vision, personas)
are far from attention.

The real question: **does every pre-implementation skill earn its place?**

### Current pre-implementation chain (14 skills):
```
vision-sync → domain-expert → competitor-analysis → persona-builder →
feature-discovery → writing-spec → spec-ac-sync → journey-sync →
writing-ux-design → writing-ui-design → writing-technical-design →
solution-explorer → spec-style-sync → writing-change-set
```

### Proposed collapsed chain (8 skills):

```
vision-sync → domain-expert+competitor-analysis → persona-builder →
feature-discovery+writing-spec → journey-sync+spec-ac-sync →
design (UX+UI+DESIGN.md) → writing-technical-design+solution-explorer →
writing-change-set
```

**What merges:**
- `domain-expert` + `competitor-analysis` → one skill: "market-research" (they always run together, same inputs, complementary outputs)
- `feature-discovery` + `writing-spec` → feature-discovery already validates whether to build; writing-spec defines what. Merging means: validate AND spec in one pass, no handoff overhead
- `journey-sync` + `spec-ac-sync` → journeys exercise ACs, AC audit checks them. Run together, feed each other in one session
- `writing-ux-design` + `writing-ui-design` + DESIGN.md consultation → one "design" skill that produces UX flows, UI components, and DESIGN.md in one coherent pass
- `writing-technical-design` + `solution-explorer` → tech design picks the approach, then immediately challenges it with alternatives. Same session, same context, no handoff loss
- `spec-style-sync` → absorbed into writing-technical-design (it produces a style contract from the same codebase analysis)

**What this gains:**
- 14 → 8 pre-implementation skills (43% fewer LLM sessions)
- Each merged skill has FULL context of both halves (no information loss at handoff)
- Faster pipeline (fewer context loads, fewer self-verify gates)
- Finding 7 (spec-ac-sync ordering) solved automatically

**What this risks:**
- Larger skills are harder to maintain
- Individual audit modes become compound
- Existing users referencing specific skill names would need migration

**Recommendation:** Don't merge the skill files. Instead, create a "compact mode" flag that groups skills into sessions. `--progressive --compact` runs 8 sessions instead of 14 by keeping the LLM context alive across grouped skills.

---

## P2: Real-Time Feedback Loop, Not Waterfall (HIGH IMPACT)

### Problem

The pipeline is still waterfall. You write a vision, then personas, then specs,
then design, then tech design, then implement. If implementation reveals the
spec was wrong, you route back to writing-spec — losing all downstream work.

Real product development is iterative. The spec changes while you design. The
design changes while you implement. The implementation reveals new requirements.

### Proposed change: Checkpoint-and-Revise model

Instead of routing BACK to an upstream skill (losing all work after it),
introduce **in-place revision** at any point:

```
executing-change-set discovers AC-03 is infeasible
  → DON'T route back to writing-spec
  → INSTEAD: revise AC-03 in the spec IN PLACE
  → Update the manifest task that depends on AC-03
  → Continue execution
  → Log the revision in docs/specs/decisions/ with justification
```

**Rules for in-place revision:**
1. Only the specific AC/story/component that's infeasible gets revised
2. The revision is logged with justification (not silently changed)
3. Downstream artifacts that depend on the revised element get flagged for update
4. The revision is reviewed at the next gate (systems-analysis or review-protocol)

**What this gains:**
- No more "go back to Phase 2" loops that throw away Phase 3-8 work
- Faster iteration — fix the specific issue, don't redo the whole phase
- Better audit trail — every revision is documented with WHY

**What this risks:**
- Accumulated revisions could drift from the original vision
- Need a "revision count" threshold — too many revisions = the spec was fundamentally wrong

---

## P3: Parallel Skill Execution Where Independent (MEDIUM IMPACT)

### Problem

Skills run sequentially even when they're independent. `domain-expert` and
`competitor-analysis` don't depend on each other. `writing-ux-design` and
`writing-technical-design` don't depend on each other (UX is flows, tech is
architecture). But the progressive chain forces them sequential.

### Proposed change: Dependency graph with parallel execution

```
vision-sync
  ├── domain-expert ────┐
  └── competitor-analysis ──┤
                            └── persona-builder
                                 └── feature-discovery+writing-spec
                                      ├── journey-sync+spec-ac-sync
                                      ├── writing-ux-design ──┐
                                      └── writing-ui-design ──┤
                                                              └── writing-technical-design
```

Skills with no data dependency run in parallel (via subagents in worktrees).
The chain only serializes when there's a real data dependency.

**What this gains:**
- 2-3x faster pipeline for greenfield (parallel design phases)
- Better resource utilization

**What this risks:**
- Parallel agents may make conflicting decisions
- Need a merge/reconciliation step after parallel phases
- More complex worktree management (multiple worktrees simultaneously)

**Recommendation:** Start with the obvious parallel pairs:
- `domain-expert` + `competitor-analysis` (always parallel, same inputs)
- `writing-ux-design` + `writing-ui-design` (often parallel, UX doesn't block UI)

---

## P4: Living Spec, Not Frozen Artifacts (HIGH IMPACT)

### Problem

Each skill produces a markdown file and moves on. The spec is frozen at DRAFT,
then UX-REVIEWED, then DESIGNED, then BASELINED. But the spec should be a
living document that evolves as implementation reveals truth.

Currently: `BASELINED` means "locked, don't change." But that's wrong — the best
specs are the ones that get updated as you learn.

### Proposed change: Continuous spec reconciliation

After every checkpoint commit in `executing-change-set`, run a lightweight
spec-code reconciliation:

```
For each checkpoint commit:
  1. What ACs does this commit address?
  2. Does the implementation match the AC's intent?
  3. If not: UPDATE the AC to match reality (not the other way around)
  4. Log the update in docs/specs/decisions/
```

This is the inverse of `spec-code-sync` (which checks code matches spec).
This checks spec matches code — and updates the spec when the code is right
and the spec was wrong.

**What this gains:**
- Specs that are always current (not frozen in the past)
- Implementation discoveries feed back into specs immediately
- Post-merge spec-code-sync finds fewer false drifts

---

## P5: Confidence-Gated Pipeline (MEDIUM IMPACT)

### Problem

Every skill runs with the same intensity regardless of how confident P0 is.
A feature with strong demand validation (P0 Q1 score 9/10) gets the same
solution-explorer depth as a feature with weak validation (Q1 score 3/10).

### Proposed change: P0 confidence score drives pipeline depth

After the forcing questions, P0 has a confidence score (0-10) across multiple
dimensions:

```
P0 Confidence:
  Demand: 8/10 (strong evidence from Q1)
  Specificity: 6/10 (moderate — persona identified but not validated)
  Wedge: 9/10 (clear narrowest version from Q4)
  Future-fit: 4/10 (uncertain — needs more research)
```

Low-confidence dimensions get MORE exploration. High-confidence dimensions
get LESS (they've already been validated):

| Dimension | Score | Pipeline effect |
|-----------|-------|----------------|
| Demand 8+ | solution-explorer Quick mode (sanity check) |
| Demand <5 | solution-explorer Full mode + extra research |
| Specificity <5 | Extra persona-builder iteration |
| Future-fit <5 | domain-expert gets Deep research mode |

**What this gains:**
- Pipeline adapts to what's known vs unknown
- Less time on well-understood features
- More time where uncertainty is highest (which is where time matters most)

---

## P6: The "Just Show Me" Fast Path (HIGH IMPACT)

### Problem

For experienced builders who know what they want, 14 pre-implementation skills
is overhead. They want: "Here's my spec, just build it." The pipeline forces
them through vision → personas → feature discovery → etc. even when they've
already done that thinking.

### Proposed change: Fast path that starts from wherever you are

```
User: "I have a spec already. Here's my feature spec. Build it."
Pipeline: Detects existing spec → skips to writing-technical-design
          (or writing-change-set if tech design also exists)

User: "I have a tech design. Here's the architecture. Build it."
Pipeline: Detects existing tech design → skips to writing-change-set

User: "I have a manifest. Execute it."
Pipeline: Detects manifest → skips to executing-change-set
```

`workflow-compass` already routes based on what exists. This makes it
more aggressive: if the upstream artifact already exists AND is well-formed,
skip all the skills that would have produced it.

**What this gains:**
- Experienced users get straight to implementation
- Pipeline respects existing work instead of redoing it
- "Just build it" actually means "just build it"

**Validation:** Before skipping, run a quick audit of the existing artifact.
If it's well-formed (has ACs, has stories, etc.), skip. If it's incomplete,
route to the skill that fills the gap.

---

## Priority Ranking

| # | Proposal | Impact | Risk | Effort | Do first? |
|---|----------|--------|------|--------|-----------|
| P6 | Fast path from existing artifacts | HIGH | LOW | LOW | Yes |
| P4 | Living spec, continuous reconciliation | HIGH | LOW | MEDIUM | Yes |
| P1 | Compact mode (grouped skills) | HIGH | LOW | MEDIUM | Yes |
| P5 | Confidence-gated pipeline depth | MEDIUM | LOW | MEDIUM | Second |
| P2 | In-place revision instead of back-routing | HIGH | MEDIUM | HIGH | Second |
| P3 | Parallel skill execution | MEDIUM | MEDIUM | HIGH | Later |
