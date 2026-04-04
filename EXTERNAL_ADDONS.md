# External Add-On Packs

This repository ships a **core skill pack**. Some routes in `workflow-compass`
support optional external ecosystems.

Use this file as the contract for which external skills are optional and how
they attach to the core pipeline.

## Core Pack (always available)

- `vision-sync`
- `domain-expert`
- `competitor-analysis`
- `persona-builder`
- `journey-sync`
- `journey-qa-ac-testing`
- `feature-discovery`
- `spec-ac-sync`
- `spec-code-sync`
- `spec-style-sync`
- `agentic-e2e-playwright`
- `feature-marketing-insights`
- `workflow-compass`
- `repo-conversion`
- `bugfix-brief`
- `work-item-sync`
- `skill-finder`
- `research`
- `writing-spec`
- `writing-ux-design`
- `writing-ui-design`
- `writing-technical-design`
- `solution-explorer`
- `writing-change-set`
- `executing-change-set`
- `review-protocol`
- `systems-analysis`
- `landing-change-set`
- `verifying-promotion`
- `bootstrap-extract`
- `cross-model-review`
- `visual-tracker`
- `framework-test`

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
1. Run `feature-marketing-insights` first to generate canonical context from vibomatic mining.
2. If you use coreyhaines `product-marketing-context`, run it as a transformer:
   start from existing `.agents/product-marketing-context.md` and adapt/expand language without dropping vibomatic insight payload.
3. Keep output path the same: `.agents/product-marketing-context.md`.
4. Feed `.agents/product-marketing-context.md` into downstream add-on skills as grounding context.
5. If an add-on hardcodes `.claude/product-marketing-context.md`, mirror from `.agents` for compatibility, but keep `.agents` as canonical source.

Interop rule:
- Shared canonical file path: `.agents/product-marketing-context.md`
- Vibomatic `feature-marketing-insights` runs first and is the source of truth for weighted feature insights and tracker sync (`docs/marketing/feature-mining-tracker.json`).
- Coreyhaines `product-marketing-context` is a downstream transformation pass over vibomatic output.

## Add-On: implementation-planning (optional)

Some routes reference repo-specific implementation planning. If a planning skill
such as `writing-plans` exists in your environment, treat it as optional add-on.
