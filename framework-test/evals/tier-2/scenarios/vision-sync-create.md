# Scenario: vision-sync create new vision

## Setup

Create an empty workspace with only `REPO_MODES.md`:

```markdown
# Repository Modes

**Current mode:** bootstrap

No product-spec workflow established yet. This is a new project.
```

Write to `REPO_MODES.md`.

## Prompt

```
Use the vision-sync skill to create a vision for a habit tracker app. The app helps users build daily habits through streaks, reminders, and progress visualization. Target audience is individuals who want to build better routines. The app should be a mobile-first web app with offline support.
```

## Expected Outputs

### File Exists

- `docs/specs/vision.md` — vision document created

### Content Checks

The vision.md must contain these 12 canonical sections (as defined by the vision-sync skill). Check for section headers:

- [ ] `## Purpose` or `## Problem`
- [ ] `## Boundaries` or `## Scope`
- [ ] `## Principles`
- [ ] `## Success Criteria` or `## Success Metrics`
- [ ] `## Product Type`
- [ ] `## Target Audience` or `## Users`
- [ ] Contains the word "habit" (confirms it's about the right product)
- [ ] Contains "streak" or "reminder" or "progress" (captures key feature concepts)
- [ ] At least 50 lines long (substantive, not a stub)
- [ ] No implementation details (should NOT contain "React", "Express", "database schema", "API endpoint" — vision is what, not how)

## Chain Continuation

If `--progressive` were set, next skill would be `persona-builder` (greenfield lane position 2).
