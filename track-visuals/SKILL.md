---
name: track-visuals
description: >
  Capture and track visual state of all screens. Creates a baseline after first
  UI design or brownfield onboarding, then diffs against it when code changes.
  Use when "capture visuals", "visual baseline", "screenshot all screens",
  "visual regression", "what changed visually", "track visual state", or
  automatically after design-ui (baseline) and after execute-changeset
  (diff). Also works standalone for periodic visual audits.
inputs:
  required: []
  optional:
    - { path: "docs/specs/ux/<name>.md", artifact: ux-design }
    - { path: "docs/specs/ui/<name>.md", artifact: ui-design }
    - { path: "docs/specs/journeys/J*.feature.md", artifact: journeys }
outputs:
  produces:
    - { path: "docs/specs/visuals/baseline/", artifact: visual-baseline }
    - { path: "docs/specs/visuals/diffs/", artifact: visual-diff-report }
chain:
  lanes: {}
  progressive: false
  self_verify: true
  human_checkpoint: false
---

# Visual Tracker

Capture complete visual state of the app and track changes over time.
Visual regression testing integrated into the pipeline.

**Announce at start:** "I'm using track-visuals to capture/compare visual state."

## Modes

| Mode | When | What it does |
|------|------|-------------|
| `baseline` | After first UI design or brownfield onboarding | Captures screenshots of all screens/states |
| `diff` | After code changes | Re-captures, compares to baseline, reports changes |
| `update` | After intentional visual changes | Updates baseline to new state |
| `audit` | Periodic check | Compares current app to UI design docs |

## Process

### Baseline Mode

Run after `design-ui` produces the first visual design, or when
onboarding a brownfield project.

**Step 1: Build the screen inventory**

From UX design + UI design + journeys, list every distinct screen and state:

```markdown
| Screen | States | Route/URL | Source |
|--------|--------|-----------|--------|
| Dashboard | empty, loading, populated, error | /dashboard | UX doc |
| Profile | viewing, editing | /profile | UX doc |
| Login | default, error, loading | /login | Journey J01 |
| Settings | default, changed | /settings | UX doc |
```

**Step 2: Capture each screen + state**

For each entry in the inventory, navigate to the screen and capture:

```bash
# Using Playwright MCP
browser_navigate → <url>
browser_take_screenshot → save to docs/specs/visuals/baseline/<screen>-<state>.png

# Capture at multiple breakpoints if responsive
# Desktop (1280px), Tablet (768px), Mobile (375px)
browser_resize → { width: 1280, height: 800 }
browser_take_screenshot → <screen>-<state>-desktop.png
browser_resize → { width: 768, height: 1024 }
browser_take_screenshot → <screen>-<state>-tablet.png
browser_resize → { width: 375, height: 812 }
browser_take_screenshot → <screen>-<state>-mobile.png
```

For states that require setup (error state, empty state, populated state):
- Use the app's API or UI to create the state
- Document how to reproduce the state in the inventory

**Step 3: Save the baseline manifest**

```markdown
# Visual Baseline: <project name>

**Created:** <date>
**Screens:** <count>
**States:** <count>
**Breakpoints:** desktop (1280), tablet (768), mobile (375)

## Inventory

| Screen | State | Desktop | Tablet | Mobile |
|--------|-------|---------|--------|--------|
| Dashboard | empty | ✅ captured | ✅ | ✅ |
| Dashboard | populated | ✅ captured | ✅ | ✅ |
| ... | ... | ... | ... | ... |

## How to Reproduce States

### Empty state
<steps to get to empty state>

### Error state
<steps to trigger error>

### Populated state
<steps to create test data>
```

Save to `docs/specs/visuals/baseline/manifest.md`.

---

### Diff Mode

Run after code changes to detect visual regressions.

**Step 1: Re-capture all screens**

Use the same inventory from the baseline manifest. Capture to a temp directory.

**Step 2: Compare**

For each screen + state + breakpoint:
- Compare new screenshot to baseline
- Report: UNCHANGED / CHANGED / NEW / MISSING

Visual comparison approach (in order of preference):
1. **Pixel diff** — if `pixelmatch` or similar tool is available
2. **AI vision comparison** — use Claude's multimodal capability to compare two screenshots
3. **Manual visual inspection** — present both side by side

**Step 3: Generate diff report**

```markdown
# Visual Diff Report

**Date:** <date>
**Baseline:** <baseline date>
**Branch:** <current branch>

## Summary
- Unchanged: <count>
- Changed: <count>
- New screens: <count>
- Missing screens: <count>

## Changes

### Dashboard (populated, desktop)
**Status:** CHANGED
**Baseline:** baseline/dashboard-populated-desktop.png
**Current:** diffs/<date>/dashboard-populated-desktop.png
**What changed:** <description of visual difference>
**Intentional?** ⬜ Yes / ⬜ No (needs investigation)

### Settings (default, mobile)
**Status:** CHANGED
...

## New Screens
<screens that exist now but weren't in the baseline>

## Missing Screens
<screens from baseline that no longer exist — routes removed?>
```

Save to `docs/specs/visuals/diffs/<date>-diff.md`.

---

### Update Mode

After intentional visual changes are confirmed:

```bash
# Replace baseline with current state
mv docs/specs/visuals/baseline/ docs/specs/visuals/baseline-<old-date>/
# Re-run baseline mode
```

Or selectively update specific screens:
```
Update baseline for: Dashboard (populated), Settings (default)
Keep existing baseline for: Login, Profile
```

---

### Audit Mode

Compare current app visuals against UI design documents:

1. Load UI design docs (`docs/specs/ui/<name>.md`)
2. Extract expected component layouts, colors, spacing
3. Capture current app state
4. Compare: does the implementation match the design?
5. Report discrepancies: wrong colors, broken layout, missing components

---

## Integration Points

| Trigger | Mode | Automatic? |
|---------|------|-----------|
| After `design-ui` | baseline | Suggested (not auto) |
| After `execute-changeset` | diff | Suggested if baseline exists |
| After `land-changeset` | update | Suggested if intentional changes |
| Periodic / on-demand | audit | Manual |

## Pipeline Continuation

### Self-Verify

| # | Check | How | PASS/FAIL |
|---|-------|-----|-----------|
| 1 | Baseline or diff report exists | `test -d docs/specs/visuals/` | |
| 2 | All screens in inventory captured | count captured vs inventory | |
| 3 | Diff report flags all changes | no CHANGED without description | |

### Chaining

Standalone skill — not in progressive chains. Invoke when you want visual
tracking. Suggest after UI design (baseline) and after execution (diff).
