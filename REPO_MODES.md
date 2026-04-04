# Repository Modes

This skill pack supports two repository modes.

## Modes

- `bootstrap` (greenfield): no established product-spec workflow yet.
- `convert` (brownfield): existing code/docs/process already exist and must be adapted before the full vibomatic pipeline governs the repo.

## Mode Detection

Use this quick check before running any skill:

```bash
test -d docs/specs/features && test -d docs/specs/personas && test -d docs/specs/journeys
```

Interpretation:

- If missing/empty core spec directories -> default to `bootstrap`.
- If the repo already has active code/docs/testing conventions -> default to `convert`.

When ambiguous, choose `convert` to preserve existing structure.

Default recommendation:

- If the repo is effectively clean, let vibomatic define the workflow directly.
- If the repo already has meaningful shipped behavior, docs, tests, or conventions, run conversion first.

## Mode Contract

### Bootstrap Mode

- Create minimum scaffold first:
  - `docs/specs/features/`
  - `docs/specs/personas/`
  - `docs/specs/journeys/`
  - `docs/marketing/` (when using `feature-marketing-insights`)
- Default greenfield sequence:
  1. `vision-sync`
  2. `persona-builder`
  3. `feature-discovery`
  4. `writing-spec`
  5. `spec-ac-sync`
  6. `journey-sync`
  7. `writing-ux-design`
  8. `writing-ui-design`
  9. `writing-technical-design`
  10. `writing-change-set`
  11. `executing-change-set`
  12. `promoting-change-set`
  13. `verifying-promotion`
- For prompts effectively meaning "build me an app", run this lane end to end automatically unless a real blocker or contradiction appears.

### Convert Mode

- Start with `repo-conversion` before feature, bugfix, or drift work.
- Do not force directory/file renames on first pass.
- Inventory existing artifacts and map them to expected outputs.
- Preserve established conventions; add compatibility notes where needed.
- Log discovered bugs, regressions, and drift as repo-canonical work items instead of fixing them inline.
- Finish the map first, then route each item into the right lane.

Suggested brownfield sequence:
1. `repo-conversion`
2. `spec-code-sync`
3. route by item type:
   - `writing-spec` in delta mode for feature extension
   - `bugfix-brief` for bugs and regressions
   - `spec-code-sync` + selective updates for drift remediation
   - `work-item-sync` to project repo-canonical items to GitHub Issues

## Required Behavior for Every Skill

- Detect mode first.
- State selected mode explicitly.
- In `bootstrap`, create/initialize missing prerequisites instead of failing.
- In `convert`, adapt to current repo conventions before enforcing target structure.
- In `convert`, prefer delta-first changes over regenerating canonical artifacts from scratch.

## Drift Guardrail

Core skill names and bootstrap sequence are source-of-truth in
`skills-manifest.json` and linted against this file plus routing docs.

Run:

```bash
node scripts/lint-skills-manifest.mjs
```
