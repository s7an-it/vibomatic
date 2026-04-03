# Repository Modes

This skill pack supports two repository modes.

## Modes

- `bootstrap` (greenfield): no established product-spec workflow yet.
- `convert` (brownfield): existing code/docs/process already exist and must be adapted.

## Mode Detection

Use this quick check before running any skill:

```bash
test -d docs/specs/features && test -d docs/specs/personas && test -d docs/specs/journeys
```

Interpretation:

- If missing/empty core spec directories -> default to `bootstrap`.
- If the repo already has active code/docs/testing conventions -> default to `convert`.

When ambiguous, choose `convert` to preserve existing structure.

## Mode Contract

### Bootstrap Mode

- Create minimum scaffold first:
  - `docs/specs/features/`
  - `docs/specs/personas/`
  - `docs/specs/journeys/`
  - `docs/marketing/` (when using `feature-marketing-insights`)
- Start sequence:
  1. `vision-sync`
  2. `persona-builder`
  3. `journey-sync`
  4. `feature-discovery` / feature specs
  5. `spec-ac-sync`
  6. `journey-qa-ac-testing`
  7. `spec-code-sync`
  8. `agentic-e2e-playwright`
  9. `feature-marketing-insights` (parallel marketing track)

### Convert Mode

- Do not force directory/file renames on first pass.
- Inventory existing artifacts and map them to expected outputs.
- Preserve established conventions; add compatibility notes where needed.
- Run sync/audit skills against current structure, then converge gradually.

## Required Behavior for Every Skill

- Detect mode first.
- State selected mode explicitly.
- In `bootstrap`, create/initialize missing prerequisites instead of failing.
- In `convert`, adapt to current repo conventions before enforcing target structure.

## Drift Guardrail

Core skill names and bootstrap sequence are source-of-truth in
`skills-manifest.json` and linted against this file plus routing docs.

Run:

```bash
node scripts/lint-skills-manifest.mjs
```
