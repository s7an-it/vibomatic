# External Add-On Packs

This repository ships a **core skill pack** (35 skills). Some routes in
`route-workflow` support optional external ecosystems.

Use this file as the contract for which external skills are optional and how
they attach to the core pipeline.

## Core Pack (always available)

### Pipeline

`write-vision`, `analyze-domain`, `analyze-competitors`, `build-personas`,
`validate-feature`, `write-spec`, `audit-ac`, `write-journeys`,
`design-ux`, `design-ui`, `design-tech`, `explore-solutions`,
`define-code-style`, `plan-changeset`, `execute-changeset`,
`audit-implementation`, `land-changeset`, `verify-promotion`

### Review

`review-gate`, `review-security`, `review-cross-model`

### Sync

`sync-spec-code`, `sync-work-items`

### Test

`test-journeys`, `write-e2e`, `test-framework`

### Utility

`route-workflow`, `diagnose-bug`, `onboard-repo`, `research`,
`discover-skills`, `extract-bootstrap`, `track-visuals`,
`analyze-marketing`, `manage-learnings`

## Add-On: coreyhaines marketing ecosystem (optional)

Use these only when installed:

- `product-marketing-context` (optional downstream context transformer)
- `customer-research`
- `market-competitors`
- `competitor-alternatives`
- `copywriting`
- `page-cro`
- `launch-strategy`
- `market-social`
- `market-ads`
- `market-emails`
- `signup-flow-cro`
- `onboarding-cro`

Recommended integration point:
1. Run `analyze-marketing` first to generate canonical context from vibomatic mining.
2. If you use coreyhaines `product-marketing-context`, run it as a transformer:
   start from existing `.agents/product-marketing-context.md` and adapt/expand language without dropping vibomatic insight payload.
3. Keep output path the same: `.agents/product-marketing-context.md`.
4. Feed `.agents/product-marketing-context.md` into downstream add-on skills as grounding context.
5. If an add-on hardcodes `.claude/product-marketing-context.md`, mirror from `.agents` for compatibility, but keep `.agents` as canonical source.

Interop rule:
- Shared canonical file path: `.agents/product-marketing-context.md`
- Vibomatic `analyze-marketing` runs first and is the source of truth for weighted feature insights and tracker sync (`docs/marketing/feature-mining-tracker.json`).
- Coreyhaines `product-marketing-context` is a downstream transformation pass over vibomatic output.

## Add-On: implementation-planning (optional)

Some routes reference repo-specific implementation planning. If a planning skill
such as `writing-plans` exists in your environment, treat it as optional add-on.
