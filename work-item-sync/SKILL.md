---
name: work-item-sync
description: >
  Sync repo-canonical vibomatic work items to GitHub Issues. Use after repo-conversion or
  whenever work-item files change and the team wants external execution visibility without
  making GitHub the source of truth. GitHub is the first-class integration target in v1.
  Linear is deferred.
---

# Work Item Sync

Vibomatic keeps project state in the repo. External trackers are projections for execution,
assignment, and visibility.

This skill syncs `docs/specs/work-items/WI-*.md` to GitHub Issues and writes the issue
number back into each work item. Repo files stay canonical.

**Announce at start:** "I'm using the work-item-sync skill to project repo-canonical work items to GitHub Issues."

## Source of Truth

- Canonical: repo files under `docs/specs/work-items/`
- Projection: GitHub Issues
- Deferred: GitHub Projects and Linear

## Inputs

Read:

- `docs/specs/project-state.md`
- `docs/specs/work-items/INDEX.md`
- `docs/specs/work-items/WI-*.md`

## Expected Fields

Each work item should include:

- ID
- title
- type
- status
- severity
- lane
- source skill
- source artifact
- GitHub issue number (optional on first sync)

## Sync Behavior

### Create issue

If a work item has no issue number:

- create a GitHub Issue
- use the work-item title as the issue title
- use the repo item body as the issue body
- apply labels for:
  - `type:*`
  - `status:*`
  - `lane:*`
  - `severity:*`
- write the resulting issue number back into the work item

### Update issue

If a work item already has an issue number:

- update the issue title/body if the repo item changed materially
- update labels to reflect current repo state

## Label Convention

Recommended labels:

- `type:feature`
- `type:bugfix`
- `type:regression`
- `type:refactor`
- `type:drift`
- `type:conversion`
- `type:chore`

- `status:identified`
- `status:triaged`
- `status:planned`
- `status:in_progress`
- `status:blocked`
- `status:resolved`
- `status:verified`
- `status:deferred`

- `lane:greenfield`
- `lane:conversion`
- `lane:brownfield-feature`
- `lane:bugfix`
- `lane:drift`

- `severity:critical`
- `severity:high`
- `severity:medium`
- `severity:low`

## Rules

- Do not treat GitHub as canonical
- Do not overwrite repo state from ad hoc tracker edits
- Do not attempt bidirectional sync in v1
- If a GitHub issue diverges from the repo item, prefer the repo item and resync outward

## Future Compatibility

Keep the work-item schema neutral enough that `linear_issue_id` can be added later.
Do not design dual-canonical sync rules in v1.
