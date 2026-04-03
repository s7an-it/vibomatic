---
name: spec-style-sync
description: >
  Define or audit a code style contract for the project. In create mode, analyzes
  existing codebase (brownfield) or design system + tech stack choice (greenfield) to
  produce a style contract. In audit mode, checks generated code against the contract.
  Produces docs/specs/style-contract.md. Use when: "code style", "naming conventions",
  "style contract", "style audit", "check code consistency", or automatically between
  writing-technical-design and writing-change-set in the pipeline.
inputs:
  required:
    - { path: "docs/specs/features/*.md", artifact: feature-spec }
  optional:
    - { path: "docs/specs/design-system.md", artifact: design-system }
    - { path: "docs/specs/style-contract.md", artifact: existing-style-contract }
    - { path: "package.json", artifact: package-json }
    - { path: "tsconfig.json", artifact: tsconfig }
outputs:
  produces:
    - { path: "docs/specs/style-contract.md", artifact: style-contract }
chain:
  lanes:
    greenfield: { position: 10, prev: writing-technical-design, next: writing-change-set }
    brownfield-feature: { position: 6, prev: writing-technical-design, next: writing-change-set }
  progressive: true
  self_verify: true
  human_checkpoint: false
---

# Spec Style Sync

Define the code style contract between technical design and implementation. The style contract is a project-level artifact — created once, evolved as the codebase grows.

**Announce at start:** "I'm using the spec-style-sync skill to define (or audit) the code style contract."

## Modes

### Create Mode (no existing style-contract.md)

Analyze the project to derive conventions:

**Brownfield (existing code):**
1. Read 5-10 representative source files across domains (services, routes, components, tests)
2. Extract patterns: naming, file structure, import style, test patterns, error handling
3. Produce `docs/specs/style-contract.md` that codifies what IS, not what should be

**Greenfield (no source files yet):**
1. Read `docs/specs/design-system.md` if it exists (visual language → component naming)
2. Read `package.json` and `tsconfig.json` for tech stack signals
3. Read the technical design section for architecture patterns
4. Produce a style contract based on community conventions for the detected stack

### Audit Mode (existing style-contract.md)

1. Read the current style contract
2. Scan source files for violations
3. Report violations as a table: file, line, convention violated, actual vs expected
4. Do NOT auto-fix — report only. The developer decides what to change.

### Staleness Check

The style contract is stale if:
- It predates the most recent `writing-technical-design` checkpoint commit
- `package.json` dependencies have changed since the contract's `Generated:` date

If stale, re-run Create Mode to refresh.

## Style Contract Structure

```markdown
# Code Style Contract

**Generated:** YYYY-MM-DD
**Source:** [codebase analysis | design system + tech stack]
**Tech Stack:** [detected from package.json / tsconfig]

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Files | [detected] | user-service.ts |
| Functions | [detected] | getUserById |
| Types/Interfaces | [detected] | UserProfile |
| Constants | [detected] | MAX_RETRY_COUNT |
| Test files | [detected] | user-service.test.ts |

## File Structure Patterns

- Services: [detected path pattern]
- Components: [detected path pattern]
- Types: [detected path pattern]
- Tests: [co-located | separate directory]

## Import Style

- [absolute | relative | aliased]
- [named exports | default exports]
- [type imports separated | inline]

## Test Patterns

- Framework: [vitest | jest | mocha | detected]
- Structure: [describe/it | test() | detected]
- Assertion style: [expect | assert | detected]
- Mock strategy: [boundary mocks | no mocks | detected]

## Error Handling

- [custom classes | plain Error | error codes | detected]
- [try/catch | Result type | detected]

## Component Patterns (if UI exists)

- Props naming: [detected]
- Hook extraction: [detected]
- State management: [detected]
```

## Self-Verify

Before declaring done:

| # | Check | How | PASS/FAIL |
|---|-------|-----|-----------|
| 1 | `docs/specs/style-contract.md` exists | `test -f docs/specs/style-contract.md` | |
| 2 | Contract has all required sections | grep for Naming, File Structure, Import, Test, Error | |
| 3 | Conventions are specific (not "TBD" or generic) | No placeholder text | |
| 4 | Tech stack matches `package.json` | Compare detected stack with actual deps | |

## Pipeline Continuation

**If `--progressive` and self-verify passed:**
- Check `--skip` list. If `style` is in skip list, pass through to next skill.
- Determine lane from `--lane` flag.
- Invoke next skill: `writing-change-set --progressive --lane <lane>`

**If standalone:**
- Report the style contract summary
- Suggest: "Next: run `writing-change-set` to produce the implementation manifest"
