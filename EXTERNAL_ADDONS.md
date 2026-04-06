# External Add-On Packs

This repository ships a **core skill pack** (42 skills). Some routes in
`route-workflow` support optional external ecosystems.

Use this file as the contract for which external skills are optional and how
they attach to the core pipeline.

## Core Pack (always available)

- `write-vision`
- `analyze-domain`
- `analyze-competitors`
- `build-personas`
- `write-journeys`
- `test-journeys`
- `validate-feature`
- `audit-ac`
- `sync-spec-code`
- `define-code-style`
- `write-e2e`
- `analyze-marketing`
- `route-workflow`
- `onboard-repo`
- `diagnose-bug`
- `sync-work-items`
- `discover-skills`
- `research`
- `write-spec`
- `design-ux`
- `design-ui`
- `design-tech`
- `explore-solutions`
- `plan-changeset`
- `execute-changeset`
- `review-gate`
- `audit-implementation`
- `land-changeset`
- `verify-promotion`
- `extract-bootstrap`
- `review-cross-model`
- `track-visuals`
- `review-security`
- `manage-learnings`
- `test-framework`
- `evolve-framework`
- `blend-external`
- `wsl2-audio`
- `mine-builder`
- `find-opportunity`
- `stage-revenue`
- `create-skill`

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
1. Run `analyze-marketing` first to generate canonical context from svc mining.
2. If you use coreyhaines `product-marketing-context`, run it as a transformer:
   start from existing `.agents/product-marketing-context.md` and adapt/expand language without dropping svc insight payload.
3. Keep output path the same: `.agents/product-marketing-context.md`.
4. Feed `.agents/product-marketing-context.md` into downstream add-on skills as grounding context.
5. If an add-on hardcodes `.claude/product-marketing-context.md`, mirror from `.agents` for compatibility, but keep `.agents` as canonical source.

Interop rule:
- Shared canonical file path: `.agents/product-marketing-context.md`
- Serious Vibe Coding `analyze-marketing` runs first and is the source of truth for weighted feature insights and tracker sync (`docs/marketing/feature-mining-tracker.json`).
- Coreyhaines `product-marketing-context` is a downstream transformation pass over svc output.

## Add-On: Anthropic skill-creator (optional)

The official Anthropic `skill-creator` from [anthropics/skills](https://github.com/anthropics/skills).
Full skill creation pipeline with eval viewer, benchmark aggregation, subagent-based
A/B testing, and automated description optimization.

```bash
npx skills add anthropics/skills --skill skill-creator
```

**How it integrates with svc:**

Use Anthropic's skill-creator directly to author the skill, run evals, and
optimize the description. Then apply the svc checklist from CONTRIBUTING.md
to add pipeline wiring (frontmatter fields, manifest, README).

## Add-On: implementation-planning (optional)

Some routes reference repo-specific implementation planning. If a planning skill
such as `writing-plans` exists in your environment, treat it as optional add-on.
