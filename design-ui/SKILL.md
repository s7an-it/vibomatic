---
name: design-ui
description: Use when a UX-REVIEWED feature spec needs visual design — produces component specifications, design token usage, and responsive layout before technical design
inputs:
  required:
    - { path: "docs/specs/ux/<name>.md", artifact: ux-design }
  optional:
    - { path: "docs/specs/design-system.md", artifact: design-system }
outputs:
  produces:
    - { path: "docs/specs/ui/<name>.md", artifact: ui-design }
    - { path: "docs/specs/design-system.md", artifact: design-system }
chain:
  lanes:
    greenfield: { position: 8, prev: design-ux, next: design-tech }
  progressive: true
  self_verify: true
  human_checkpoint: false
---

# Writing UI Design

## Overview

UI design answers HOW it looks. It takes a UX-REVIEWED feature spec (screen flows, states, information hierarchy) plus the project's design system and produces component specifications, design token usage, visual hierarchy, dark mode behavior, animation, and responsive layout specifics.

This skill transitions a feature spec from UX-REVIEWED to DESIGNED.

```
write-spec              → DRAFT (WHAT: stories, ACs, journeys)
design-ux         → UX-REVIEWED (HOW users experience it: flows, states, interactions)
design-ui         → DESIGNED (HOW it looks: components, visual language, tokens)
design-tech  → BASELINED (HOW to build it: architecture, data model)
```

**Announce at start:** "I'm using the design-ui skill to define the visual design and component specifications."

## Design Alternatives

For each key decision in this phase (component strategy, layout system,
responsive approach), follow the Design Alternatives Protocol
(`references/design-alternatives.md`).

## Design Shotgun (variant exploration)

Before finalizing component specs, explore multiple visual directions through a structured variant generation process.

### Step 1: Context Gathering (5 Dimensions)

Before generating any variants, gather context across five dimensions:

| Dimension | Question | Source |
|-----------|----------|--------|
| **Who** | Who is the user? Demographics, technical comfort, aesthetic expectations. | Personas, vision.md |
| **Job to be done** | What is the user trying to accomplish on this screen? What is the primary action? | Feature spec, UX design |
| **What exists** | Is there an existing UI, design system, DESIGN.md, or brand guidelines to align with? | Codebase scan, DESIGN.md |
| **User flow** | Where did the user come from? Where do they go next? What is the emotional arc? | UX flows, state machines |
| **Edge cases** | Empty states, error states, overflowing content, long strings, first-time vs returning user. | UX design states, ACs |

Do not skip this step. Variants generated without context are generic.

### Step 2: Taste Memory

Before generating new concepts, read prior approved designs:

```bash
cat docs/specs/decisions/approved.json 2>/dev/null
ls docs/specs/decisions/taste-*.md 2>/dev/null
```

If prior approvals exist, bias toward the user's established preferences — font choices, density preferences, color temperature, decoration level. Taste compounds across sessions. A user who consistently picks minimal variants should not be shown maximalist options unless explicitly exploring a new direction.

### Step 3: Concept Generation

Generate N text-only concepts (typically 3-5). Each concept is a **distinct creative direction**, not a variation on the same idea.

Bad (variations):
- Concept A: Blue buttons with rounded corners
- Concept B: Blue buttons with square corners
- Concept C: Teal buttons with rounded corners

Good (directions):
- Concept A: **Editorial** — generous whitespace, large serif headings, content-first with minimal chrome
- Concept B: **Dashboard** — dense, data-forward, compact sidebar navigation, monospace accents
- Concept C: **Boutique** — bold brand color, oversized typography, personality-driven with illustration accents

Each concept description should include: name, aesthetic philosophy, typography approach, color temperature, density, and what makes it appropriate for the target user.

### Step 4: Concept Confirmation

Present the text concepts to the user BEFORE generating HTML. This is a gate.

```
I've drafted 3 design directions for [screen name]:

A) Editorial — generous whitespace, large serif headings, content-first...
B) Dashboard — dense, data-forward, compact sidebar navigation...
C) Boutique — bold brand color, oversized typography, personality-driven...

Shall I generate HTML mockups for all 3, or would you like to adjust/replace any direction?
```

In auto mode: P0 selects which concepts to generate with justification. In interactive mode: wait for user confirmation.

### Step 5: Variant Generation

For each confirmed concept, generate a self-contained HTML/CSS file:

- **50-100 lines of real HTML/CSS** — not pseudocode, not wireframes
- Inline styles or a `<style>` block — no external dependencies except Google Fonts
- Real content (not lorem ipsum) — use plausible data for the product's domain
- Responsive: looks reasonable at both 375px and 1200px
- All edge cases visible: show at least one empty state, one error state, or one overflow case per variant

```bash
# Generate variants
write docs/specs/ui/variants/<screen>-A-editorial.html
write docs/specs/ui/variants/<screen>-B-dashboard.html
write docs/specs/ui/variants/<screen>-C-boutique.html

# Open comparison board in browser
gstack browse docs/specs/ui/variants/<screen>-A-editorial.html
gstack browse docs/specs/ui/variants/<screen>-B-dashboard.html
```

### Step 6: Comparison and Selection

Open variants in browser (gstack browse) side by side for comparison.

- User picks direction (interactive) or P0 picks with justification (auto)
- Selection should note specific elements to keep, not just "I like B"
- Mixing is allowed: "B's layout with A's typography"

### Step 7: Iteration Loop

After selection:

1. **Capture feedback** — what to keep, what to change, what to combine from other variants
2. **Save taste preferences** — write approved direction to `docs/specs/decisions/approved.json`:

```json
{
  "screen": "<screen-name>",
  "date": "YYYY-MM-DD",
  "chosen_direction": "B — Dashboard",
  "keep": ["dense layout", "monospace accents", "compact sidebar"],
  "change": ["soften border-radius", "warmer background"],
  "combine_from": { "A": ["serif headings"] },
  "rejected": ["C — too playful for enterprise users"]
}
```

3. **Iterate or finalize** — generate a refined variant incorporating feedback, open in browser for verification. Repeat until approved.
4. **Log to decisions** — append to `docs/specs/decisions/` so future design shotgun runs inherit these preferences.

Taste preferences compound across runs. The first design shotgun for a project explores broadly; subsequent runs narrow based on established taste.

### Quick Reference

Variants should be genuinely different directions (not color swaps):
- Variant A: minimal/clean — lots of whitespace, muted colors
- Variant B: dense/functional — data-forward, compact layout
- Variant C: bold/branded — strong typography, distinctive personality
- etc.

## Adversarial Design Review (after UI is drafted)

Score each design dimension 0-10:

| Dimension | What to check |
|-----------|--------------|
| Consistency | Same patterns for same interactions across all screens? |
| Subtraction | Can anything be removed without losing function? |
| Component reuse | Are similar UI patterns using the same component? |
| Design system compliance | Does everything follow DESIGN.md tokens? |
| Dark mode | If applicable — does the palette work in both modes? |
| Trust signals | Loading states, skeleton screens, optimistic UI — all present? |

Fix anything under 7. In auto mode: P0 fixes automatically.

## What UI Design Is (And Is Not)

UI design defines the visual treatment, component structure, and interaction aesthetics of screens that UX design already mapped. It takes the screen inventory, state machines, flows, and information hierarchy from UX design and specifies exactly how each element renders — which components, which tokens, which states, which animations.

**UI design does NOT define:** Which screens exist, how users navigate between them, what information hierarchy to use, or what error recovery flows look like. Those are UX design (Phase 4). If you catch yourself adding new screens or changing flow logic, stop — that is a feedback loop to design-ux.

**The boundary:** UX says "this screen has a primary action, a list of results, and a filter panel." UI says "the primary action is a filled button using `color.primary` at `size.lg`, the list uses `CardList` with `spacing.md` between items, and the filter panel uses `CollapsiblePanel` that becomes a `BottomSheet` below the `breakpoint.md` threshold."

## The Design System

The design system is a foundational artifact — created once, evolved as features demand new patterns.

**Path:** `docs/specs/design-system.md`

### If The Design System Does Not Exist

Before designing any feature's UI, the design system must exist. If `docs/specs/design-system.md` is missing, create it first. This is a one-time bootstrapping step.

**Design system creation process:**

1. **Read the vision** (`docs/specs/vision.md`) for brand personality, target audience, and product positioning
2. **Read existing personas** for context on user demographics and technical comfort
3. **Survey the codebase** for any existing UI patterns, CSS variables, theme files, or component libraries already in use
4. **Create the design system** inspired by established systems (Google Material, Stitch, Tailwind) but adapted to this project's specific brand and needs

**Design system structure:**

```markdown
# Design System

**Project:** [Project name from vision]
**Created:** [YYYY-MM-DD]
**Last Updated:** [YYYY-MM-DD]

---

## Brand Personality

[Voice, tone, visual feeling — derived from vision.md]

---

## Color Palette

### Semantic Colors

| Token | Light Mode | Dark Mode | Usage |
|-------|-----------|-----------|-------|
| `color.primary` | [value] | [value] | Primary actions, brand accent |
| `color.primary.hover` | [value] | [value] | Hover state for primary elements |
| `color.secondary` | [value] | [value] | Secondary actions, supporting elements |
| `color.surface` | [value] | [value] | Card and container backgrounds |
| `color.surface.elevated` | [value] | [value] | Elevated surfaces (modals, dropdowns) |
| `color.background` | [value] | [value] | Page background |
| `color.text.primary` | [value] | [value] | Primary text |
| `color.text.secondary` | [value] | [value] | Supporting text, labels |
| `color.text.disabled` | [value] | [value] | Disabled element text |
| `color.error` | [value] | [value] | Error states, destructive actions |
| `color.warning` | [value] | [value] | Warning states, caution |
| `color.success` | [value] | [value] | Success states, confirmation |
| `color.info` | [value] | [value] | Informational states |
| `color.border` | [value] | [value] | Default borders |
| `color.border.focus` | [value] | [value] | Focus ring |

---

## Typography

| Token | Value | Usage |
|-------|-------|-------|
| `type.display` | [font, size, weight, line-height] | Hero headings |
| `type.h1` | [font, size, weight, line-height] | Page titles |
| `type.h2` | [font, size, weight, line-height] | Section headings |
| `type.h3` | [font, size, weight, line-height] | Subsection headings |
| `type.body` | [font, size, weight, line-height] | Body text |
| `type.body.small` | [font, size, weight, line-height] | Secondary body text |
| `type.caption` | [font, size, weight, line-height] | Labels, metadata |
| `type.code` | [font, size, weight, line-height] | Code blocks, monospace |
| `type.button` | [font, size, weight, line-height, letter-spacing] | Button labels |

---

## Spacing

| Token | Value | Usage |
|-------|-------|-------|
| `spacing.xs` | [value] | Tight spacing (between related elements) |
| `spacing.sm` | [value] | Small spacing (within components) |
| `spacing.md` | [value] | Medium spacing (between components) |
| `spacing.lg` | [value] | Large spacing (between sections) |
| `spacing.xl` | [value] | Extra large spacing (page-level separation) |

### Base Unit

[Define the base unit and scale — e.g., 4px base with multiples]

---

## Breakpoints

| Token | Value | Target |
|-------|-------|--------|
| `breakpoint.sm` | [value] | Mobile |
| `breakpoint.md` | [value] | Tablet |
| `breakpoint.lg` | [value] | Desktop |
| `breakpoint.xl` | [value] | Wide desktop |

---

## Component Patterns

### Button

| Variant | Usage | Tokens |
|---------|-------|--------|
| Primary | Main actions | `color.primary`, `type.button`, `spacing.sm` padding |
| Secondary | Supporting actions | `color.secondary`, `type.button` |
| Ghost | Tertiary actions, links | `color.text.primary`, `type.button` |
| Destructive | Delete, remove | `color.error`, `type.button` |

| State | Visual Change |
|-------|--------------|
| Default | [base appearance] |
| Hover | [change] |
| Active/Pressed | [change] |
| Disabled | [change — opacity, color] |
| Loading | [spinner, disabled interaction] |
| Focus | [focus ring using `color.border.focus`] |

### Card
[Pattern definition]

### Modal
[Pattern definition]

### Form Input
[Pattern definition]

### Navigation
[Pattern definition]

[Additional patterns as needed by the project]

---

## Motion

| Token | Value | Usage |
|-------|-------|-------|
| `motion.duration.fast` | [value] | Micro-interactions (hover, toggle) |
| `motion.duration.normal` | [value] | Standard transitions (expand, collapse) |
| `motion.duration.slow` | [value] | Large transitions (page enter, modal open) |
| `motion.easing.default` | [value] | Standard easing curve |
| `motion.easing.enter` | [value] | Elements entering view |
| `motion.easing.exit` | [value] | Elements leaving view |

### Motion Principles

- [When to animate vs. instant transitions]
- [Reduced motion behavior — what changes when `prefers-reduced-motion` is set]
- [Maximum animation duration — nothing blocks interaction longer than X]

---

## Dark Mode Strategy

[Approach: automatic from system preference / user toggle / both]
[Surface elevation in dark mode — how depth is communicated without shadows]
[Image treatment — dimming, border handling]
[Color adjustments beyond token swaps — contrast considerations]

---

## Accessibility Baseline

[Minimum contrast ratios]
[Focus indicator style]
[Touch target minimum sizes]
[Font size minimums]
```

**The design system is NOT a copy of Material or Tailwind.** It is inspired by established systems but adapted to the project's brand, audience, and technical stack. Read the vision and personas before choosing values.

### If The Design System Exists

Read it. Every UI design decision must reference design system tokens. If the feature requires a pattern that does not exist in the design system, extend the design system first, then use the new tokens in the feature UI design.

## When To Use

- After design-ux produces a UX-REVIEWED feature spec
- When a feature's screen flows and states are defined but visual design is not
- When the design system needs to be created (bootstrapping)
- Before invoking design-tech (requires DESIGNED spec)

## Prerequisites

| Artifact | Where | Required? | If missing |
|----------|-------|-----------|------------|
| Feature spec (UX-REVIEWED) | `docs/specs/features/<feature>.md` | Yes — must be UX-REVIEWED | Route to `design-ux` |
| UX design | `docs/specs/ux/<feature>.md` | Yes — screen inventory, states, flows | Route to `design-ux` |
| Design system | `docs/specs/design-system.md` | Yes — tokens and patterns | Create it first (see above) |
| Personas | `docs/specs/personas/P*.md` | Recommended | Provides audience context for visual decisions |
| Vision | `docs/specs/vision.md` | Recommended | Provides brand personality for design system |

**Gate:** Do not start UI design without a UX-REVIEWED spec and UX design artifact. If the UX design does not exist, route to `design-ux` first.

## Process

### Step 0a: Ensure DESIGN.md Exists (Brand + Aesthetic Foundation)

```bash
cat DESIGN.md 2>/dev/null || cat docs/specs/DESIGN.md 2>/dev/null
```

If no DESIGN.md exists, create it at project root using the **Design Consultation** process below. This defines the design direction ABOVE the token level — brand personality, aesthetic approach, motion principles, accessibility baseline.

If DESIGN.md already exists, read it and ensure all UI design decisions align.

#### Design Consultation Process (creating DESIGN.md)

##### Phase 1: Product Context Gathering

Before making any design decisions, understand what you are designing for.

1. **Read the README** — what does this product claim to be? What problem does it solve?
2. **Read package.json** (or equivalent manifest) — what frameworks, UI libraries, and dependencies are already in play?
3. **Scan existing components** — `ls src/components/ 2>/dev/null`, `ls app/ 2>/dev/null`, `ls pages/ 2>/dev/null`. Are there existing patterns, a component library, or a blank slate?
4. **Read any existing design artifacts** — `docs/specs/vision.md`, personas, prior DESIGN.md attempts
5. **Summarize the product context:**
   - What is this product?
   - Who uses it? (demographics, technical comfort, context of use)
   - What stage is it at? (greenfield, MVP, scaling, redesign)
   - What constraints exist? (framework, existing UI, brand guidelines)

##### Phase 2: Research the Landscape

Run a web search for 5-10 products in the same space. Look at direct competitors, adjacent products, and best-in-class examples from other domains that serve similar user needs.

For each product noted, capture: name, URL, what they do well visually, what they do poorly.

Then perform a **3-layer synthesis:**

- **Layer 1 — Convention:** What patterns does EVERY product in this space share? These are user expectations. Violating them creates friction. (e.g., dashboards always have left nav, e-commerce always shows price prominently)
- **Layer 2 — Trend:** What is trending or emerging? What are the best products doing that the average ones are not? (e.g., bento grids, glassmorphism fading out, variable fonts rising)
- **Layer 3 — Differentiation:** Given THIS product's specific users and positioning, where should we deliberately break from convention? What design choices would make this product feel different without confusing users?

##### Phase 3: Complete Design Proposal

Present the design direction as one coherent package. For each dimension, mark decisions as **SAFE** (following convention) or **RISK** (deliberate departure from norms).

**Always propose at least 2 RISKS** with clear rationale for why the departure serves this product's users.

| Dimension | Description |
|-----------|-------------|
| **AESTHETIC** | Overall visual direction — minimal, dense, playful, corporate, editorial, etc. Reference 2-3 real products. SAFE or RISK. |
| **DECORATION** | Border-radius, shadows, gradients, textures, dividers. How "decorated" vs "flat" is the UI? SAFE or RISK. |
| **LAYOUT** | Grid system, max-width, sidebar vs top-nav, content density. SAFE or RISK. |
| **COLOR** | Primary, secondary, accent, semantic colors — all with hex values. Light and dark mode. SAFE or RISK. |
| **TYPOGRAPHY** | Display, body, UI, and code fonts — 3 specific font recommendations with rationale. SAFE or RISK. |
| **SPACING** | Base unit, scale, density philosophy. SAFE or RISK. |
| **MOTION** | Approach (restrained vs expressive), easing curves, duration ranges. SAFE or RISK. |

Example RISK with rationale:
> **TYPOGRAPHY — RISK:** Use Satoshi (geometric sans) for headings instead of the expected neutral grotesque. Rationale: the product targets creative professionals who respond to typographic personality; a generic font signals "another SaaS tool."

##### Font Guidance

**Recommended fonts** (distinctive, high-quality, well-hinted):
- **Sans-serif:** Satoshi, Instrument Sans, DM Sans, Geist, Plus Jakarta Sans
- **Monospace:** JetBrains Mono, Geist Mono, Berkeley Mono, Fira Code

**Blacklisted** (never use under any circumstances):
- Papyrus, Comic Sans, Lobster, Impact, Jokerman, Curlz MT

**Overused** (never as primary — acceptable as fallback or body only if justified):
- Inter, Roboto, Arial, Open Sans, Poppins, Montserrat, Lato, Nunito

The goal is a font stack that gives the product a voice. If a user can't tell your product from a Tailwind template, the typography has failed.

##### Phase 4: Generate Font + Color Preview

After the proposal is confirmed, generate an HTML preview page showing:
- Typography specimens (display, heading, body, UI, code) at actual sizes
- Color palette swatches with hex values and contrast ratios
- Light and dark mode side by side

Open in browser for visual confirmation before writing DESIGN.md.

#### DESIGN.md Structure

The final DESIGN.md at project root must follow this structure:

```markdown
# Design: [Project Name]

**Generated:** YYYY-MM-DD
**Last Updated:** YYYY-MM-DD

---

## Product Context

[What this product is, who it serves, what stage it's at, what constraints exist.
This section is the "why" behind every design decision below.]

---

## Aesthetic Direction

[Overall visual approach. SAFE/RISK classification.
Reference 2-3 existing products with similar aesthetic goals.
What makes this product feel like THIS product and not a generic template.]

---

## Typography

| Role | Font | Weight | Size | Line Height | Usage |
|------|------|--------|------|-------------|-------|
| Display | [specific font] | [weight] | [size] | [lh] | Hero headings, marketing |
| Body | [specific font] | [weight] | [size] | [lh] | Paragraphs, descriptions |
| UI | [specific font] | [weight] | [size] | [lh] | Buttons, labels, nav items |
| Data | [specific font] | [weight] | [size] | [lh] | Tables, metrics, numbers |
| Code | [specific font] | [weight] | [size] | [lh] | Code blocks, CLI output |

**Font stack:** `[primary], [fallback], [system fallback]`
**Loading strategy:** [Google Fonts / self-hosted / variable font]

---

## Color

**Approach:** [Monochromatic, complementary, analogous, split-complementary — and why]

### Core Palette

| Token | Light Mode | Dark Mode | Usage |
|-------|-----------|-----------|-------|
| `color.primary` | #XXXXXX | #XXXXXX | Primary actions, brand accent |
| `color.primary.hover` | #XXXXXX | #XXXXXX | Hover state |
| `color.secondary` | #XXXXXX | #XXXXXX | Secondary actions |
| `color.accent` | #XXXXXX | #XXXXXX | Highlights, badges, emphasis |
| `color.background` | #XXXXXX | #XXXXXX | Page background |
| `color.surface` | #XXXXXX | #XXXXXX | Card/container backgrounds |
| `color.surface.elevated` | #XXXXXX | #XXXXXX | Modals, dropdowns |
| `color.text.primary` | #XXXXXX | #XXXXXX | Primary text |
| `color.text.secondary` | #XXXXXX | #XXXXXX | Supporting text |
| `color.border` | #XXXXXX | #XXXXXX | Default borders |

### Semantic Colors

| Token | Light Mode | Dark Mode | Usage |
|-------|-----------|-----------|-------|
| `color.error` | #XXXXXX | #XXXXXX | Error states |
| `color.warning` | #XXXXXX | #XXXXXX | Warning states |
| `color.success` | #XXXXXX | #XXXXXX | Success states |
| `color.info` | #XXXXXX | #XXXXXX | Informational |

---

## Spacing

**Base unit:** [e.g., 4px]
**Scale:** [e.g., 4, 8, 12, 16, 24, 32, 48, 64, 96]
**Density philosophy:** [compact / comfortable / spacious — and why]

| Token | Value | Usage |
|-------|-------|-------|
| `spacing.xs` | [value] | Tight (related elements) |
| `spacing.sm` | [value] | Small (within components) |
| `spacing.md` | [value] | Medium (between components) |
| `spacing.lg` | [value] | Large (between sections) |
| `spacing.xl` | [value] | Extra large (page-level) |

---

## Layout

| Property | Value | Rationale |
|----------|-------|-----------|
| Grid system | [e.g., 12-column CSS Grid] | [why] |
| Max content width | [e.g., 1200px] | [why] |
| Border radius | [e.g., 8px default, 12px cards, 9999px pills] | [why] |
| Sidebar width | [if applicable] | [why] |
| Content measure | [max line length for readability] | [why] |

---

## Motion

**Approach:** [restrained / expressive — and why]

| Property | Value | Usage |
|----------|-------|-------|
| Easing (default) | [e.g., cubic-bezier(0.4, 0, 0.2, 1)] | Standard transitions |
| Easing (enter) | [e.g., cubic-bezier(0, 0, 0.2, 1)] | Elements entering |
| Easing (exit) | [e.g., cubic-bezier(0.4, 0, 1, 1)] | Elements leaving |
| Duration (fast) | [e.g., 100ms] | Micro-interactions |
| Duration (normal) | [e.g., 200ms] | Standard transitions |
| Duration (slow) | [e.g., 350ms] | Large transitions |

**Reduced motion:** all animations collapse to instant or opacity-only.

---

## Decisions Log

| # | Decision | Classification | Rationale |
|---|----------|---------------|-----------|
| 1 | [e.g., Use Satoshi for display type] | RISK | [why this departure from convention serves the product] |
| 2 | [e.g., 8px border-radius on all cards] | SAFE | [follows established SaaS convention] |
| 3 | [e.g., No sidebar — top nav only] | RISK | [product is content-focused, sidebar wastes horizontal space] |

---

## Dark Mode Strategy

[Default or toggle? Semantic color tokens? Which surfaces change?
How is elevation communicated without shadows?]

---

## Accessibility Baseline

[WCAG target: AA minimum. Focus indicators. Touch targets ≥44px.
Minimum font sizes. Screen reader strategy. Contrast ratios.]
```

### Step 0b: Ensure Design System Exists (Tokens)

```bash
cat docs/specs/design-system.md 2>/dev/null
```

If the file does not exist, create it before proceeding to Step 1. Follow the design system creation process described in "The Design System" section above. The design system implements the direction from DESIGN.md as concrete tokens.

If it exists, read it and note:
- Available color tokens
- Typography scale
- Spacing system
- Existing component patterns
- Motion tokens
- Dark mode strategy

### Step 0c: UX→UI Traceability Table

Before designing components, map every screen and state from the UX design:

| UX Screen | UX States | UI Components (to design) | Coverage |
|-----------|-----------|---------------------------|----------|
| [from UX doc] | [loading, empty, populated, error] | [components to create] | — |

Missing entries = UX screens with no UI plan = design gap. Resolve before proceeding.

### Step 1: Read The UX Design And Spec

Read the UX design artifact and the feature spec. Understand:

- What screens exist (screen inventory)
- What states each screen has (state machines)
- What the information hierarchy is (priority per screen)
- What error and loading states are defined
- What the responsive strategy requires
- What accessibility requirements are specified

```bash
# Read UX design
cat docs/specs/ux/<feature-name>.md

# Read feature spec
cat docs/specs/features/<feature-name>.md

# Read design system
cat docs/specs/design-system.md

# Read personas for visual context
ls docs/specs/personas/P*.md 2>/dev/null
```

### Step 2: Component Specifications

For each screen in the UX design's screen inventory, specify the components that render it. Each element from the information hierarchy becomes a component with specific design tokens.

```markdown
## Component Specifications

### S1: [Screen Name]

#### Layout

[Overall layout structure — grid, flex, regions]
[Reference design system spacing tokens]

#### Components

| Element | Component | Variant | Tokens | Notes |
|---------|-----------|---------|--------|-------|
| [Primary action] | Button | Primary | `color.primary`, `type.button`, `spacing.sm` | Full width on mobile |
| [Result list] | CardList | Default | `spacing.md` gap, `color.surface` cards | Virtualized for large lists |
| [Filter panel] | CollapsiblePanel → BottomSheet (mobile) | Outlined | `color.border`, `spacing.lg` padding | Collapses below `breakpoint.md` |
| [Page title] | Heading | H1 | `type.h1`, `color.text.primary` | — |
| [Supporting text] | Text | Body | `type.body`, `color.text.secondary` | Max-width for readability |
```

**Rules:**
- Every element from the UX information hierarchy (Step 5) must have a component row
- Every token reference must exist in the design system (or be added to it)
- Component names should describe function, not implementation (e.g., "CardList" not "div.flex.flex-col")
- Note responsive behavior changes per component (from UX responsive strategy)

### Step 3: Design Token Usage

Map exactly which design system tokens each screen uses. This ensures the design system is sufficient and the feature is consistent.

```markdown
## Design Token Usage

### Tokens Used

| Token | Used In | Purpose |
|-------|---------|---------|
| `color.primary` | S1 primary button, S2 active tab | Brand action color |
| `color.surface` | S1 cards, S2 panels | Container backgrounds |
| `spacing.md` | S1 card list gap, S2 form fields | Standard component separation |
| `type.h1` | S1 page title | Screen heading |
| `motion.duration.normal` | S1 card expand, S2 panel toggle | Standard interaction transitions |

### New Tokens Required

| Token | Proposed Value (Light) | Proposed Value (Dark) | Justification |
|-------|----------------------|----------------------|---------------|
| [New token] | [Value] | [Value] | [Why this feature needs it] |
```

**If new tokens are required:** Add them to `docs/specs/design-system.md` before using them in the UI design. The design system grows through feature demands, not speculation.

### Step 4: Visual Hierarchy

For each screen, map how the information hierarchy (from UX) translates to visual weight. Priority 1 elements must be visually dominant; lower priority elements must be visually subordinate.

```markdown
## Visual Hierarchy

### S1: [Screen Name]

| Priority | Element | Visual Treatment | Size/Weight | Contrast |
|----------|---------|-----------------|-------------|----------|
| 1 | [Primary content] | [How it dominates — larger, bolder, higher contrast] | `type.h1` / `type.display` | High against `color.background` |
| 2 | [Secondary content] | [How it supports — medium weight, standard size] | `type.body` | Standard against `color.surface` |
| 3 | [Tertiary content] | [How it recedes — smaller, lighter] | `type.body.small` / `type.caption` | Lower, using `color.text.secondary` |
| Nav | [Navigation] | [Persistent but not dominant] | `type.button` | Medium |
| Meta | [Metadata] | [Minimal visual footprint] | `type.caption` | Low, using `color.text.disabled` or `color.text.secondary` |
```

**Rules:**
- Visual hierarchy must match information hierarchy from UX design — do not promote tertiary content visually
- Use typography scale, color, and spacing to create hierarchy — not decoration
- Every priority level must be visually distinguishable from adjacent levels

### Step 5: Dark Mode

Specify how each screen behaves in dark mode. This is not just "swap light tokens for dark tokens" — dark mode has its own visual considerations.

```markdown
## Dark Mode

### Strategy

[Reference design system dark mode strategy]

### Screen-Specific Dark Mode Behavior

| Screen | Element | Light Mode | Dark Mode | Notes |
|--------|---------|-----------|-----------|-------|
| S1 | Card surface | `color.surface` (light value) | `color.surface` (dark value) | Elevation communicated via border, not shadow |
| S1 | Primary button | `color.primary` (light) | `color.primary` (dark) | May need adjusted contrast ratio |
| S1 | Images/avatars | Full brightness | Dimmed to 85% | Prevent eye strain from bright images on dark background |
| S2 | Dividers | `color.border` (light) | `color.border` (dark) | May need opacity adjustment |
```

**Rules:**
- Every component from Step 2 that has color tokens must specify dark mode behavior
- Check contrast ratios in dark mode (WCAG AA minimum: 4.5:1 for text, 3:1 for large text)
- Elevated surfaces in dark mode use lighter shades (opposite of light mode shadow approach)
- Images may need treatment (dimming, border) to avoid visual harshness

### Step 6: Animation and Motion

Specify animation behavior for state transitions (from UX state machines) and interactions.

```markdown
## Animation and Motion

### State Transitions

| Screen | Transition | Animation | Duration | Easing | Reduced Motion Fallback |
|--------|-----------|-----------|----------|--------|------------------------|
| S1 | LOADING → POPULATED | Fade in + stagger children | `motion.duration.normal` | `motion.easing.enter` | Instant (no animation) |
| S1 | POPULATED → ACTION_PENDING | Button loading spinner | `motion.duration.fast` (loop) | linear | Static loading indicator |
| S2 | Screen enter | Slide from right | `motion.duration.normal` | `motion.easing.enter` | Instant (no animation) |

### Micro-Interactions

| Element | Interaction | Animation | Duration | Easing |
|---------|------------|-----------|----------|--------|
| Button | Hover | Scale 1.02 + shadow elevation | `motion.duration.fast` | `motion.easing.default` |
| Card | Tap/Click | Scale 0.98 (press) | `motion.duration.fast` | `motion.easing.default` |
| Toggle | State change | Slide + color morph | `motion.duration.fast` | `motion.easing.default` |
```

**Rules:**
- Every state machine transition (from UX Step 3) that the user can perceive must specify animation
- Every interaction must have a reduced motion fallback
- No animation should block user interaction (animations are decorative, not gating)
- Reference motion tokens from the design system — do not invent ad-hoc durations

### Step 7: Component States

For every interactive component in the feature, specify all visual states.

```markdown
## Component States

### Primary Button (S1, S2)

| State | Background | Text | Border | Shadow | Cursor | Additional |
|-------|-----------|------|--------|--------|--------|------------|
| Default | `color.primary` | `color.text.on-primary` | none | `shadow.sm` | pointer | — |
| Hover | `color.primary.hover` | `color.text.on-primary` | none | `shadow.md` | pointer | Scale 1.02 |
| Active | `color.primary.active` | `color.text.on-primary` | none | `shadow.none` | pointer | Scale 0.98 |
| Disabled | `color.primary` at 40% opacity | `color.text.disabled` | none | none | not-allowed | — |
| Loading | `color.primary` | hidden | none | `shadow.sm` | wait | Spinner centered |
| Focus | `color.primary` | `color.text.on-primary` | `color.border.focus` 2px | `shadow.sm` | pointer | Focus ring visible |
| Error | `color.error` | `color.text.on-error` | none | `shadow.sm` | pointer | Context-dependent |

### Card (S1)

| State | Background | Border | Shadow | Additional |
|-------|-----------|--------|--------|------------|
| Default | `color.surface` | `color.border` 1px | `shadow.sm` | — |
| Hover | `color.surface.elevated` | `color.border` 1px | `shadow.md` | Slight lift |
| Selected | `color.primary` at 8% opacity | `color.primary` 2px | `shadow.md` | Check indicator |
| Disabled | `color.surface` at 60% opacity | `color.border` 1px | none | Content dimmed |
| Loading | `color.surface` | `color.border` 1px | `shadow.sm` | Skeleton shimmer |

[Repeat for every interactive component]
```

**Rules:**
- Every interactive component must specify: default, hover, active, disabled, focus, loading states at minimum
- Error state is required for components that can enter an error condition (forms, submissions)
- All values must reference design system tokens
- Disabled and loading states must prevent interaction (cursor, pointer-events)

### Step 8: Responsive Layout Specifics

Translate the UX responsive strategy (behavior) into specific layout decisions (implementation-ready).

```markdown
## Responsive Layout

### Grid System

| Viewport | Columns | Gutter | Margin | Max Content Width |
|----------|---------|--------|--------|-------------------|
| Small (`< breakpoint.md`) | [N] | `spacing.sm` | `spacing.md` | 100% |
| Medium (`breakpoint.md` — `breakpoint.lg`) | [N] | `spacing.md` | `spacing.lg` | [value] |
| Large (`>= breakpoint.lg`) | [N] | `spacing.md` | auto (centered) | [value] |

### Screen Layouts

#### S1: [Screen Name]

**Small viewport:**
```
┌──────────────────┐
│ [Header]         │
├──────────────────┤
│ [Primary content]│
│ (full width)     │
├──────────────────┤
│ [Filters — as    │
│  bottom sheet]   │
├──────────────────┤
│ [Results list]   │
│ (single column)  │
├──────────────────┤
│ [Bottom nav]     │
└──────────────────┘
```

**Large viewport:**
```
┌──────────────────────────────────────┐
│ [Header + Navigation]                │
├──────────┬───────────────────────────┤
│ [Filter  │ [Primary content]         │
│  Panel]  │                           │
│          │ [Results grid — 2-3 cols] │
│          │                           │
│ (sidebar)│                           │
└──────────┴───────────────────────────┘
```

[Repeat for each screen]

### Component Responsive Behavior

| Component | Small | Medium | Large |
|-----------|-------|--------|-------|
| Navigation | Bottom tab bar | Bottom tab bar | Side navigation |
| Card grid | 1 column, full width | 2 columns | 3 columns |
| Filter panel | Bottom sheet (toggle) | Side panel (collapsible) | Side panel (persistent) |
| Modal | Full screen | Centered, 80% width | Centered, max 600px |
| Form fields | Stacked, full width | Stacked, full width | Inline where logical |
```

**Rules:**
- Every screen from the UX screen inventory must have a small and large viewport layout
- Layouts must preserve all ACs on all viewport sizes
- Use ASCII diagrams for layout — these are structural, not pixel-perfect
- Reference breakpoint tokens from the design system

### Step 9: Assemble The UI Design Document

Write the complete UI design to `docs/specs/ui/<feature-name>.md`:

```markdown
# UI Design: [Feature Name]

**Feature Spec:** `docs/specs/features/<feature-name>.md`
**UX Design:** `docs/specs/ux/<feature-name>.md`
**Design System:** `docs/specs/design-system.md`
**Status:** DRAFT (pending G3 review)
**Type:** [Feature | Enabler | Integration]
**Created:** [YYYY-MM-DD]

---

## Component Specifications

[From Step 2]

---

## Design Token Usage

[From Step 3]

---

## Visual Hierarchy

[From Step 4]

---

## Dark Mode

[From Step 5]

---

## Animation and Motion

[From Step 6]

---

## Component States

[From Step 7]

---

## Responsive Layout

[From Step 8]

---

## Design System Changes

[New tokens or patterns added to the design system for this feature]
[If none: "No design system changes required."]

---

## AC Traceability

| AC | Screen | Component(s) | States Covered | Responsive? |
|----|--------|-------------|---------------|-------------|
| [AC-ID] | [Screen] | [Components involved] | [Which states render this AC] | [Yes — all viewports / Partial] |

---

## Open Questions

[Any visual design decisions that need stakeholder input]
```

### Step 10: AC Traceability Check

Walk through every AC from the feature spec and verify the UI design addresses it visually.

```markdown
### AC Traceability

| AC | Screen | Component(s) | States Covered | Responsive? |
|----|--------|-------------|---------------|-------------|
| MATCH-01 | S3 | CardList, MatchCard | POPULATED, hover, selected | Yes — 1/2/3 col grid |
| MATCH-02 | S2 | SkeletonLoader → CardList | LOADING → POPULATED | Yes — same layout all viewports |
| MATCH-03 | S2 | ErrorBanner, RetryButton | ERROR | Yes — full width all viewports |
```

**Gate:** Every AC must have visual specifications. If an AC cannot be visually specified:
- The UX design may be incomplete (feedback loop to `design-ux`)
- The design system may lack required patterns (extend it first)
- The AC may be purely backend (confirm with spec — backend ACs skip UI design)

### Step 11: Trigger G3 Review

The UI design artifact is ready for Gate G3 review. Invoke the Review Protocol:

**G3 checks:**
- Is the design system referenced consistently (no ad-hoc values)?
- Is every component state specified (hover, active, disabled, error, loading, focus)?
- Does responsive layout preserve all ACs on all viewports?
- Is dark mode specified for every colored element?
- Are animations specified with reduced motion fallbacks?
- Does component reuse maximize (not duplicating similar components)?
- Is every AC traceable to specific components and states?

**Review Protocol steps:**
1. **Self-review** — review the UI design artifact for consistency and completeness
2. **Self-judgment** — accept or reject each finding with reasoning
3. **Cross-review** — fresh agent reviews artifact plus self-review findings
4. **Convergence check** — only medium/low issues remain? Pass. Critical/high? Fix and re-enter.
5. **Gate decision** — PASS (proceed to technical design) / FAIL (fix findings) / ESCALATE (human reviews)

### Step 12: Update Feature Spec Status

On G3 PASS, update the feature spec:

```markdown
**Status:** DESIGNED
```

Add a UI Design reference:

```markdown
## UI Design

**Artifact:** `docs/specs/ui/<feature-name>.md`
**Design System:** `docs/specs/design-system.md`
**G3 Review:** PASS — [date]
```

### Step 13: Handoff

Present a summary:

```
UI design saved: docs/specs/ui/<feature-name>.md
Design system: [created / updated / no changes]
Feature spec updated: docs/specs/features/<feature-name>.md
Status: DESIGNED (was UX-REVIEWED)
Components: N components specified across M screens
New design system tokens: K tokens added
Dark mode: fully specified
Animation: N transitions, all with reduced motion fallbacks
Responsive: all screens have small + large viewport layouts
AC coverage: [all / N of M covered, gaps listed]

Ready for technical design. Next step:
  "Run design-tech against docs/specs/features/<feature-name>.md"
```

**The terminal state is invoking design-tech.** This skill does not define architecture, data models, or technology choices.

## Feedback Loops

UI design often reveals problems upstream. Handle them:

| Discovery | Action |
|-----------|--------|
| UX screen flow is missing a screen needed for visual coherence | Route back to `design-ux` to add the screen |
| Information hierarchy doesn't map to a visual hierarchy that works | Route to `design-ux` to re-prioritize |
| Design system lacks patterns needed for this feature | Extend `docs/specs/design-system.md` first, then return |
| Component state from UX state machine has no visual representation | Route to `design-ux` to validate the state machine |
| Responsive strategy from UX doesn't work visually | Route to `design-ux` to adjust responsive strategy |
| AC implies a visual behavior not covered by any screen | Route to `design-ux` or `write-spec` depending on whether it is a flow gap or a spec gap |

**Key principle:** It is cheaper to extend the design system or revise UX now than to discover visual inconsistencies during implementation.

## Anti-Patterns

| Don't | Why | Instead |
|-------|-----|---------|
| Add new screens or change flows | That is UX design (Phase 4) | Feed back to design-ux if flow changes are needed |
| Use hardcoded values instead of tokens | Breaks design system consistency | Every color, spacing, and typography reference must use a design system token |
| Skip dark mode | Users expect it; accessibility requires it | Specify dark mode behavior for every colored element |
| Skip component states | Hover, disabled, error, loading are not optional | Every interactive component must have all states specified |
| Copy Material/Tailwind wholesale | The design system must reflect the project's brand | Use them as inspiration, adapt to the project |
| Skip reduced motion fallbacks | Accessibility requirement, not optional | Every animation must specify what happens with prefers-reduced-motion |
| Specify animations without duration tokens | Creates inconsistent timing across the product | Reference motion tokens from the design system |
| Design for one viewport only | Responsive is required, not optional | Every screen must have small and large viewport layouts at minimum |

## Routing

| Situation | Route to |
|-----------|----------|
| UI design complete, G3 passed | `design-tech` |
| UX flow needs revision for visual coherence | `design-ux` (feedback loop) |
| Design system needs new patterns | Extend `docs/specs/design-system.md` (then return) |
| No UX-REVIEWED spec exists | `design-ux` (prerequisite) |
| Feature has no visual surface | Skip to `design-tech` |
| Design system does not exist | Create it first (see "The Design System" section) |

## Audit Mode

When invoked with `--audit` to review existing UI design:

1. Read `docs/specs/ui/<name>.md`
2. UX→UI traceability: every UX screen has mapped UI components?
3. Design system compliance: components reference tokens from design-system.md, not ad-hoc values?
4. DESIGN.md alignment: visual decisions match brand personality?
5. Component state coverage: hover, active, disabled, error, loading states defined?
6. Report: component-by-component PASS/WARN/FAIL

## Pipeline Continuation

### Self-Verify

Before declaring done, verify:

| # | Check | How | PASS/FAIL |
|---|-------|-----|-----------|
| 1 | UI design file exists | `test -f docs/specs/ui/<name>.md` | |
| 2 | Design system file exists | `test -f docs/specs/design-system.md` | |
| 3 | Component specs reference design tokens (not ad-hoc values) | grep for hardcoded hex/px values in UI design file; should find only token references | |
| 4 | No unresolved questions | grep for TBD, TODO, open questions in output file | |

If any check FAILs, fix before continuing. If a fix requires upstream changes, stop and report.

### Chaining

**If `--progressive` flag is present AND self-verify passed:**
- Check `--skip` list. If this skill is in the skip list, pass through to next.
- Invoke next skill: `design-tech --progressive --lane greenfield`

**If `--progressive` flag is absent:**
- Report results to user
- Suggest: "Next: consider running `design-tech`"
