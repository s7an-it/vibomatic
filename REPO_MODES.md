# Repository Modes and Workflow Lanes

This skill pack supports two repository modes and six workflow lanes.

## Modes

- `bootstrap` (greenfield): no established product-spec workflow yet.
- `convert` (brownfield): existing code/docs/process already exist and must be
  adapted before the full svc pipeline governs the repo.

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

- If the repo is effectively clean, let svc define the workflow directly.
- If the repo already has meaningful shipped behavior, docs, tests, or
  conventions, run conversion first.

## Required Behavior for Every Skill

- Detect mode first.
- State selected mode explicitly.
- In `bootstrap`, create/initialize missing prerequisites instead of failing.
- In `convert`, adapt to current repo conventions before enforcing target structure.
- In `convert`, prefer delta-first changes over regenerating canonical artifacts
  from scratch.

## Mode Contract

### Bootstrap Mode

Create minimum scaffold first:

- `docs/specs/features/`
- `docs/specs/personas/`
- `docs/specs/journeys/`
- `docs/marketing/` (when using `analyze-marketing`)

Default greenfield sequence:

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

For prompts effectively meaning "build me an app", run automatically unless
a real blocker or contradiction appears.

### Convert Mode

- Start with `onboard-repo` before feature, bugfix, or drift work.
- Do not force directory/file renames on first pass.
- Inventory existing artifacts and map them to expected outputs.
- Preserve established conventions; add compatibility notes where needed.
- Log discovered bugs, regressions, and drift as repo-canonical work items
  instead of fixing them inline.
- Finish the map first, then route each item into the right lane.

Suggested conversion sequence:

1. `onboard-repo` — inventory, map, log work items
2. `sync-work-items` — project items to GitHub Issues
3. Route by item type:
   - `write-spec` (delta mode) for feature extension
   - `diagnose-bug` for bugs and regressions
   - `sync-spec-code` + selective updates for drift remediation

## Workflow Lanes

Six lanes are defined in `skills-manifest.json` under `laneDefinitions`.
Use `route-workflow` to detect the right lane automatically.

### Greenfield

Full progressive narrowing pipeline for new products or features.

```
write-vision → analyze-domain → analyze-competitors → build-personas →
validate-feature → write-spec → audit-ac → write-journeys →
design-ux → design-ui → design-tech → explore-solutions →
define-code-style → plan-changeset → execute-changeset →
audit-implementation → land-changeset → verify-promotion
```

**When to use:** Starting a new project, adding a major feature to a clean
repo, or the user says "build me an app."

**Skips:** None by default.

### Brownfield Conversion

Onboard an existing repo before applying other lanes.

```
onboard-repo → sync-work-items
```

**When to use:** Repo has shipped code, docs, tests, or conventions. Does not
rewrite anything — inventories existing state and routes findings to lanes.

**Skips:** None.

### Brownfield Feature

Extend an existing system with delta specs. Starts with drift check.

```
sync-spec-code → validate-feature → write-spec → write-journeys →
design-tech → explore-solutions → define-code-style →
plan-changeset → execute-changeset → review-gate →
audit-implementation → land-changeset → verify-promotion
```

**When to use:** Adding a feature to a repo with existing specs, journeys,
and working code.

**Default skips:** `design-ux`, `design-ui` (override with
`--include design-ux,design-ui` for UI-heavy features).

### Bugfix

Root-cause-first correction work.

```
diagnose-bug → plan-changeset → execute-changeset →
review-gate → audit-implementation → land-changeset → verify-promotion
```

**When to use:** Broken behavior, regression, or production issue.

**Default skips:** `define-code-style`.

### Drift / Maintenance

Reconcile specs, journeys, and code without shipping new behavior.

```
sync-spec-code → write-journeys → sync-work-items
```

**When to use:** Specs have drifted from code, journeys reference stale
behavior, annotations are outdated. Produces updated annotations and work items.

**Skips:** None.

### Refactor

Preserve behavior while making bounded structural changes.

```
sync-spec-code → plan-changeset → execute-changeset →
review-gate → audit-implementation → land-changeset → verify-promotion
```

**When to use:** Renaming, restructuring, extracting, or cleaning up code
without changing user-facing behavior.

**Skips:** None.

## Drift Guardrail

Core skill names and bootstrap sequence are source-of-truth in
`skills-manifest.json` and linted against this file plus routing docs.

Run:

```bash
node scripts/lint-skills-manifest.mjs
```
