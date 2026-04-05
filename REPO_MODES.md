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
  - `docs/marketing/` (when using `analyze-marketing`)
- Default greenfield sequence:
  1. `write-vision`
  2. `analyze-domain`
  3. `analyze-competitors`
  4. `build-personas`
  5. `validate-feature`
  6. `write-spec`
  7. `audit-ac`
  8. `write-journeys`
  9. `design-ux`
  10. `design-ui`
  11. `design-tech`
  12. `explore-solutions`
  13. `define-code-style`
  14. `plan-changeset`
  15. `execute-changeset`
  16. `audit-implementation`
  17. `land-changeset`
  18. `verify-promotion`
- For prompts effectively meaning "build me an app", run this lane end to end automatically unless a real blocker or contradiction appears.

### Convert Mode

- Start with `onboard-repo` before feature, bugfix, or drift work.
- Do not force directory/file renames on first pass.
- Inventory existing artifacts and map them to expected outputs.
- Preserve established conventions; add compatibility notes where needed.
- Log discovered bugs, regressions, and drift as repo-canonical work items instead of fixing them inline.
- Finish the map first, then route each item into the right lane.

Suggested brownfield sequence:
1. `onboard-repo`
2. `sync-spec-code`
3. route by item type:
   - `write-spec` in delta mode for feature extension
   - `diagnose-bug` for bugs and regressions
   - `sync-spec-code` + selective updates for drift remediation
   - `sync-work-items` to project repo-canonical items to GitHub Issues

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
