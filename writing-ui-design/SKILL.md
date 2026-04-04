---
name: writing-ui-design
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
    greenfield: { position: 8, prev: writing-ux-design, next: writing-technical-design }
  progressive: true
  self_verify: true
  human_checkpoint: false
---

# Writing UI Design

## Overview

UI design answers HOW it looks. It takes a UX-REVIEWED feature spec (screen flows, states, information hierarchy) plus the project's design system and produces component specifications, design token usage, visual hierarchy, dark mode behavior, animation, and responsive layout specifics.

This skill transitions a feature spec from UX-REVIEWED to DESIGNED.

```
writing-spec              → DRAFT (WHAT: stories, ACs, journeys)
writing-ux-design         → UX-REVIEWED (HOW users experience it: flows, states, interactions)
writing-ui-design         → DESIGNED (HOW it looks: components, visual language, tokens)
writing-technical-design  → BASELINED (HOW to build it: architecture, data model)
```

**Announce at start:** "I'm using the writing-ui-design skill to define the visual design and component specifications."

## Design Alternatives

For each key decision in this phase (component strategy, layout system,
responsive approach), follow the Design Alternatives Protocol
(`references/design-alternatives.md`).

## Design Shotgun (variant exploration)

Before finalizing component specs, explore multiple visual directions:

1. For each key screen, generate 3-5 variant HTML/CSS mockups with distinct aesthetic approaches
2. Open variants in browser (gstack browse) side by side for comparison
3. User picks direction (interactive) or P0 picks with justification (auto)
4. Log taste preferences to `docs/specs/decisions/` — they compound across runs

Variants should be genuinely different directions (not color swaps):
- Variant A: minimal/clean — lots of whitespace, muted colors
- Variant B: dense/functional — data-forward, compact layout
- Variant C: bold/branded — strong typography, distinctive personality
- etc.

Each variant is 50-100 lines of real HTML/CSS you can see in the browser.

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

**UI design does NOT define:** Which screens exist, how users navigate between them, what information hierarchy to use, or what error recovery flows look like. Those are UX design (Phase 4). If you catch yourself adding new screens or changing flow logic, stop — that is a feedback loop to writing-ux-design.

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

- After writing-ux-design produces a UX-REVIEWED feature spec
- When a feature's screen flows and states are defined but visual design is not
- When the design system needs to be created (bootstrapping)
- Before invoking writing-technical-design (requires DESIGNED spec)

## Prerequisites

| Artifact | Where | Required? | If missing |
|----------|-------|-----------|------------|
| Feature spec (UX-REVIEWED) | `docs/specs/features/<feature>.md` | Yes — must be UX-REVIEWED | Route to `writing-ux-design` |
| UX design | `docs/specs/ux/<feature>.md` | Yes — screen inventory, states, flows | Route to `writing-ux-design` |
| Design system | `docs/specs/design-system.md` | Yes — tokens and patterns | Create it first (see above) |
| Personas | `docs/specs/personas/P*.md` | Recommended | Provides audience context for visual decisions |
| Vision | `docs/specs/vision.md` | Recommended | Provides brand personality for design system |

**Gate:** Do not start UI design without a UX-REVIEWED spec and UX design artifact. If the UX design does not exist, route to `writing-ux-design` first.

## Process

### Step 0a: Ensure DESIGN.md Exists (Brand + Aesthetic Foundation)

```bash
cat DESIGN.md 2>/dev/null || cat docs/specs/DESIGN.md 2>/dev/null
```

If no DESIGN.md exists, create it at project root. This defines the design direction ABOVE the token level — brand personality, aesthetic approach, motion principles, accessibility baseline.

```markdown
# Design: [Project Name]

**Generated:** YYYY-MM-DD

## Brand Personality
[Voice, tone, visual feeling — design direction, not marketing copy]

## Aesthetic Direction
[Overall visual approach. Reference 2-3 existing products with similar aesthetic goals.]

## Motion Principles
[When to animate, when not to. Duration ranges. Easing preferences.]

## Dark Mode Strategy
[Default or toggle? Semantic color tokens? Which surfaces change?]

## Accessibility Baseline
[WCAG target: AA minimum. Focus indicators. Touch targets ≥44px. Screen reader strategy.]
```

If DESIGN.md already exists, read it and ensure all UI design decisions align.

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
- The UX design may be incomplete (feedback loop to `writing-ux-design`)
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
  "Run writing-technical-design against docs/specs/features/<feature-name>.md"
```

**The terminal state is invoking writing-technical-design.** This skill does not define architecture, data models, or technology choices.

## Feedback Loops

UI design often reveals problems upstream. Handle them:

| Discovery | Action |
|-----------|--------|
| UX screen flow is missing a screen needed for visual coherence | Route back to `writing-ux-design` to add the screen |
| Information hierarchy doesn't map to a visual hierarchy that works | Route to `writing-ux-design` to re-prioritize |
| Design system lacks patterns needed for this feature | Extend `docs/specs/design-system.md` first, then return |
| Component state from UX state machine has no visual representation | Route to `writing-ux-design` to validate the state machine |
| Responsive strategy from UX doesn't work visually | Route to `writing-ux-design` to adjust responsive strategy |
| AC implies a visual behavior not covered by any screen | Route to `writing-ux-design` or `writing-spec` depending on whether it is a flow gap or a spec gap |

**Key principle:** It is cheaper to extend the design system or revise UX now than to discover visual inconsistencies during implementation.

## Anti-Patterns

| Don't | Why | Instead |
|-------|-----|---------|
| Add new screens or change flows | That is UX design (Phase 4) | Feed back to writing-ux-design if flow changes are needed |
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
| UI design complete, G3 passed | `writing-technical-design` |
| UX flow needs revision for visual coherence | `writing-ux-design` (feedback loop) |
| Design system needs new patterns | Extend `docs/specs/design-system.md` (then return) |
| No UX-REVIEWED spec exists | `writing-ux-design` (prerequisite) |
| Feature has no visual surface | Skip to `writing-technical-design` |
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
- Invoke next skill: `writing-technical-design --progressive --lane greenfield`

**If `--progressive` flag is absent:**
- Report results to user
- Suggest: "Next: consider running `writing-technical-design`"
