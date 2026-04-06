# Subagent Context Rules

Universal rules for any skill that spawns subagents (Agent tool) in the svc
pipeline. These rules prevent token waste from unscoped codebase scanning.

## The Problem

A subagent spawned without explicit constraints will:
1. Encounter an unknown import or reference
2. Grep the entire codebase to resolve it
3. Load 20-50K tokens of irrelevant code
4. Repeat for every unknown reference

This cascades. A 5-task parallel execution with unconstrained subagents can
waste 100-250K tokens on code that has nothing to do with their tasks.

## The Rules

### Rule 1: Every subagent prompt must include a constraint block

```
## Constraints
- Do NOT grep, find, or scan the codebase beyond the files listed below.
- Do NOT read files not in your context. If you need something not provided,
  report the need back to the orchestrator.
- Do NOT follow imports transitively beyond one level unless the import target
  is in your file list.
```

This must appear in EVERY subagent prompt template. No exceptions.

### Rule 2: Context is passed, not discovered

The orchestrator reads the manifest, spec, and style contract. It extracts
the relevant slices and injects them into each subagent's prompt. Subagents
do NOT read these files themselves — they receive the content pre-extracted.

Why: reading a file costs tokens. If 5 subagents each read the same spec,
that's 5x the cost. The orchestrator reads once and distributes.

### Rule 3: File lists are explicit and closed

Every subagent receives an explicit list of files it may read or modify.
Files not on the list are off-limits. The orchestrator derives the file list
from the manifest's task file assignments.

### Rule 4: Unknown references go back to the orchestrator

When a subagent encounters something it doesn't understand (unknown import,
unfamiliar type, missing dependency), it does NOT search for it. It reports:

```
NEED: I need the type definition for PaymentResult.
      Expected location: src/types/payment.ts (based on import statement)
```

The orchestrator provides the file content on the next message. This is
cheaper than the subagent grepping the entire `src/types/` directory.

### Rule 5: Orchestrator model vs implementor model

| Role | Model | Effort | Token budget |
|------|-------|--------|-------------|
| Orchestrator | Opus | medium | No hard limit — reads specs, coordinates |
| Implementor | Sonnet | medium-high | ~20-35K context per task |
| Reviewer | Opus | medium | Receives diff + findings, not full codebase |

The expensive model (Opus) spends tokens on decisions. The fast model (Sonnet)
spends tokens on generation. Never use Opus for code generation or Sonnet for
holistic review.

## Which skills spawn subagents

| Skill | Subagent type | Template location |
|-------|--------------|-------------------|
| `execute-changeset` | Implementor (Sonnet) | Inline in SKILL.md, "Subagent context" section |
| `audit-implementation` | Auditor (Sonnet) | Inline in SKILL.md, "Parallel subsystem audit" section |
| `review-gate` | Cross-reviewer (Opus) | Inline in SKILL.md, "Cross-Review Agent Prompt Template" |
| `review-cross-model` | External model (Codex/Gemini) | Inline in SKILL.md, "Tri-Model Orchestration" |

## Anti-patterns

| Anti-pattern | Why it wastes tokens | Fix |
|-------------|---------------------|-----|
| Subagent greps `src/` for an import | Loads entire directory | Report back to orchestrator |
| Subagent reads the full feature spec | 5 subagents × 5K = 25K wasted | Orchestrator extracts AC slice |
| Subagent reads the full style contract | Redundant if constraints are in prompt | Include only relevant patterns |
| Subagent follows imports 3+ levels deep | Cascading loads | One-level limit, report beyond |
| Orchestrator passes full codebase to subagent | Defeats the purpose of scoping | Pass only manifest file list |
