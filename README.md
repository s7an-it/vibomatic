# vibomatic

Skill repository for `npx skills add <github-username>/vibomatic`.

## Repository Modes

This skill pack supports:

- `bootstrap` — initialize a repo that has no established spec/journey/persona workflow yet.
- `convert` — adapt an existing repo with its current conventions/process.

Mode contract lives in [`REPO_MODES.md`](REPO_MODES.md).

## Included Skills

- `vision-sync`
- `persona-builder`
- `journey-sync`
- `journey-qa-ac-testing`
- `feature-discovery`
- `spec-ac-sync`
- `spec-code-sync`
- `agentic-e2e-playwright`
- `feature-marketing-insights`
- `workflow-compass`

## External Add-Ons (Optional)

Optional skill ecosystems are documented in [`EXTERNAL_ADDONS.md`](EXTERNAL_ADDONS.md).

Current add-on catalog:
- `coreyhaines` marketing ecosystem (customer research, competitor analysis, copy/CRO/social/launch helpers)
- repo-specific implementation planning add-ons (for example `writing-plans`)

## Skill Manifest Guardrail

Skill naming/routing is canonicalized in [`skills-manifest.json`](skills-manifest.json).

After changing any skill name or routing docs (`README.md`, `REPO_MODES.md`,
`workflow-compass/SKILL.md`, `EXTERNAL_ADDONS.md`), run:

```bash
node scripts/lint-skills-manifest.mjs
```
