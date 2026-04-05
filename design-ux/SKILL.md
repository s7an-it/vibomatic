---
name: design-ux
description: Use when a DRAFT feature spec needs UX design — produces screen flows, state machines, information hierarchy, and interaction patterns before any visual design
inputs:
  required:
    - { path: "docs/specs/features/<name>.md", artifact: feature-spec }
    - { path: "docs/specs/personas/P*.md", artifact: personas }
    - { path: "docs/specs/journeys/J*-<name>.feature.md", artifact: journeys }
  optional: []
outputs:
  produces:
    - { path: "docs/specs/ux/<name>.md", artifact: ux-design }
chain:
  lanes:
    greenfield: { position: 7, prev: write-journeys, next: design-ui }
  progressive: true
  self_verify: true
  human_checkpoint: false
---

# Writing UX Design

## Overview

UX design answers HOW users experience the feature. It takes a DRAFT feature spec (user stories, ACs, journeys) plus personas and produces screen flows, state machines, information hierarchy, error handling, and accessibility requirements.

This skill transitions a feature spec from DRAFT to UX-REVIEWED.

```
write-spec              → DRAFT (WHAT: stories, ACs, journeys)
design-ux         → UX-REVIEWED (HOW users experience it: flows, states, interactions)
design-ui         → DESIGNED (HOW it looks: components, visual language, tokens)
design-tech  → BASELINED (HOW to build it: architecture, data model)
```

**Announce at start:** "I'm using the design-ux skill to define the user experience."

## Design Alternatives

For each key decision in this phase (navigation model, interaction pattern,
information hierarchy), follow the Design Alternatives Protocol
(`references/design-alternatives.md`).

## Adversarial Design Review (after UX is drafted)

Before finalizing, P0 runs a full adversarial review of the UX design using 7 review dimensions, the AI Slop Blacklist, and the 12 Designer Cognitive Patterns. This is not a checkbox exercise — it is a design critique. The reviewer must adopt the cognitive patterns below, internalize the slop blacklist, then score each dimension honestly.

### 12 Designer Cognitive Patterns

Before scoring anything, the reviewer must adopt these mental models. These are not suggestions — they are the lens through which every dimension is evaluated.

1. **Seeing the system, not the screen** — Every screen exists inside a flow. Review the connections between screens, not each screen in isolation. A beautiful screen inside a broken flow is a broken screen.
2. **Empathy as simulation** — Mentally become each persona. What did they do 30 seconds before arriving at this screen? What are they anxious about? What are they trying to get back to?
3. **Hierarchy as service** — Visual hierarchy is not decoration, it is wayfinding. If the user has to search for the primary action, the hierarchy has failed. The most important thing should be unmistakable.
4. **Constraint worship** — Constraints produce better designs. Screen size, accessibility requirements, slow networks, limited attention spans — these are not problems, they are design materials. Embrace them.
5. **The question reflex** — For every design decision, ask "why this and not that?" If the answer is "it felt right" or "that is how it is usually done," the decision is unexamined. Every choice must have a reason traceable to a user need, a persona goal, or a system constraint.
6. **Edge case paranoia** — The happy path is 40% of the user's experience. The other 60% is loading, errors, empty states, partial data, interrupted flows, permission denied, timeout, slow network, wrong input, and "what if they press back?" Design the 60%.
7. **The "Would I notice?" test** — Open the design. Look at it for 3 seconds. Close it. What do you remember? If you cannot recall the primary action, neither will the user. If everything blurs together, hierarchy has failed.
8. **Principled taste** — Taste is not subjective — it is debuggable. "This feels wrong" is the start of an investigation, not the end. Why does it feel wrong? Is it misaligned hierarchy? Competing focal points? Inconsistent density? Name the principle being violated.
9. **Subtraction default** — "As little design as possible" (Dieter Rams). Every element must earn its place. The default is to remove, not to add. If removing an element does not break the experience, remove it.
10. **Time-horizon design** — Design operates on three timescales simultaneously: 5 seconds (visceral — does it look right?), 5 minutes (behavioral — can I accomplish my task?), 5 years (reflective — do I trust this product?). All three must be served.
11. **Design for trust** — Users are lending you their attention and their data. Every interaction is either building or eroding trust. Error messages, empty states, loading states, and permission requests are trust-critical moments — they deserve more design attention, not less.
12. **Storyboard the journey** — Do not review static screens. Narrate the experience like a film: "Sarah opens the app. She sees... She taps... She waits... She sees..." This reveals gaps that static review misses.

### AI Slop Blacklist

The following 10 patterns are indicators of generic AI-generated design. If any appear in the UX design, they must be identified and replaced with intentional, product-specific alternatives. Presence of any slop pattern is an automatic deduction on the AI Slop Risk dimension.

| # | Pattern | Why it is slop | What to do instead |
|---|---------|---------------|--------------------|
| 1 | Purple/violet gradient backgrounds | Every AI design tool defaults to purple gradients. It signals "nobody made a real choice here." | Choose a color that comes from your brand, your content, or your context. If you cannot justify the color, use neutral. |
| 2 | The 3-column feature grid (icon in colored circle + bold title + 2-line description) | This is the default layout AI produces for "show features." It communicates nothing about relative importance. | Prioritize. What is the ONE thing the user needs? Lead with that. If three things are equally important, you have not prioritized. |
| 3 | Icons in colored circles as decoration | Decorative icons that do not aid comprehension are visual noise. They fill space without earning it. | Use icons only when they genuinely aid recognition or wayfinding. If removing the icon changes nothing, remove it. |
| 4 | Centered everything | Center-alignment is the absence of a layout decision. It works for a single heading; it fails for content-heavy screens. | Left-align content. Use alignment intentionally based on reading patterns and content structure. |
| 5 | Uniform bubbly border-radius on every element | When every element has the same large border-radius, nothing has visual identity. The uniformity is the problem. | Vary border-radius by element role. Cards, buttons, inputs, and badges should feel distinct. Or use sharp corners — it is a valid choice. |
| 6 | Decorative blobs, floating circles, wavy SVG dividers | These are filler. They add visual weight without information. | Remove them. Use whitespace instead. If you need visual separation, a 1px rule or a background-color shift is enough. |
| 7 | Emoji as design elements | Emoji in headings, feature descriptions, or CTAs is a sign that no one designed an icon system or visual language. | Design proper iconography or use none. Emoji is for chat, not for product surfaces. |
| 8 | Colored left-border on cards | This pattern (left accent border) has been cargo-culted across thousands of AI-generated UIs. It rarely serves a purpose. | If you need to indicate category or status, use the full card treatment (background tint, icon, label). If not, remove the border. |
| 9 | Generic hero copy ("Welcome to [X]", "Unlock the power of...", "Your all-in-one solution") | This copy tells the user nothing. It is a placeholder that was never replaced. | Write copy that tells the user EXACTLY what they can do right now. "3 invoices need your approval" beats "Welcome to InvoiceHub" every time. |
| 10 | Cookie-cutter section rhythm (hero → features → testimonials → CTA → footer) | This is the default page structure AI produces. It is not wrong, but it is not designed — it is assembled. | Structure the page around the user's actual decision journey. What do they need to know, in what order, to take the action you want? |

### 7 Review Dimensions

Score each dimension 0-10. For any dimension scoring under 7/10: explain concretely what a 10 would look like, then fix the UX design to get there.

---

#### Dimension 1: Information Architecture (0-10)

**What to evaluate:** Is the hierarchy explicitly defined for every screen? Can you state with certainty what the user sees first, second, and third on each screen? Is there a single, unambiguous primary action per screen?

**Scoring rubric:**
- **0-3:** No hierarchy defined. Screen inventory lists elements but not their priority. Multiple competing CTAs per screen.
- **4-6:** Hierarchy partially defined. Some screens have clear primary actions, others are ambiguous. Priority rationale is missing or generic ("this is important").
- **7-8:** Every screen has a defined hierarchy with numbered priorities. Primary action is identified. Rationale references persona goals.
- **9-10:** Every screen has numbered priority elements, a single primary action justified by persona goals, explicit secondary/tertiary ordering, and the hierarchy has been validated against the "Would I notice?" test (Cognitive Pattern 7). Hierarchy decisions trace back to journey steps.

**How to evaluate:**
- For each screen, can you answer: "What does the user see first?" If the answer is "it depends" or "everything is equal," score low.
- Check that Priority 1 elements serve the screen's primary action from the Screen Inventory.
- Verify that no screen has two Priority 1 elements (that is a refusal to prioritize).

---

#### Dimension 2: Interaction State Coverage (0-10)

**What to evaluate:** Are all five interaction states (loading, empty, error, success, partial) specified for every feature on every screen? Not just acknowledged — actually designed, with content, behavior, and transitions defined.

**Scoring rubric:**
- **0-3:** Only the happy path (success state) is designed. Error and loading are mentioned but not specified.
- **4-6:** Loading and error states exist but are generic ("An error occurred"). Empty states are missing or use placeholder text. Partial states are not considered.
- **7-8:** All five states specified for every screen. Error messages are actionable and specific. Loading states specify behavior (can user interact? skeleton vs spinner?). Empty states have contextual prompts.
- **9-10:** All five states are fully designed with specific content, transitions between states are defined, partial states handle real-world data scenarios (what if only 2 of 5 API calls succeed?), and every state has been validated against Edge Case Paranoia (Cognitive Pattern 6).

**State Coverage Table** (fill this out for every feature-screen combination):

| FEATURE | SCREEN | LOADING | EMPTY | ERROR | SUCCESS | PARTIAL |
|---------|--------|---------|-------|-------|---------|---------|
| [Feature/capability name] | [Screen ID] | [Specified? Y/N + brief description] | [Specified? Y/N + brief description] | [Specified? Y/N + brief description] | [Specified? Y/N + brief description] | [Specified? Y/N + brief description] |
| | | | | | | |
| | | | | | | |

**PARTIAL state guidance:** Partial means the screen has some data but not all. Examples: search returned results but images failed to load. Profile loaded but activity history timed out. Dashboard shows 3 of 5 widgets (2 errored). The UX must specify what happens in each partial scenario — does the screen show what it has with error indicators for the rest, or does it block until everything loads?

---

#### Dimension 3: User Journey Emotional Arc (0-10)

**What to evaluate:** Has the experience been storyboarded as a journey? Not just screens and transitions — the emotional experience. What does the user feel at each step? Where are they anxious, confused, delighted, or frustrated? Does the UX design address those emotional states?

This dimension enforces Cognitive Pattern 12 (Storyboard the journey) and Cognitive Pattern 2 (Empathy as simulation).

**Scoring rubric:**
- **0-3:** No journey perspective. Screens are designed in isolation. No mention of user emotion or experience flow.
- **4-6:** Journey flows exist but are mechanical (screen A → screen B → screen C). No emotional consideration. No storyboarding.
- **7-8:** Journey is narrated from the user's perspective. Key emotional moments are identified (first impression, waiting for results, error recovery). UX addresses anxiety points.
- **9-10:** Full emotional arc storyboarded for each persona. Every step specifies what the user does, what the user feels, and how the UX design addresses that feeling. Trust-critical moments (Cognitive Pattern 11) are explicitly designed.

**User Journey Emotional Arc Table** (fill this out for each primary journey):

| STEP | USER DOES | USER FEELS | UX ADDRESSES IT? | HOW |
|------|-----------|-----------|-------------------|-----|
| 1. [First interaction] | [Action] | [Emotion: curious, anxious, impatient, confused...] | [Y/N] | [What the UX does to serve this feeling] |
| 2. [Next step] | [Action] | [Emotion] | [Y/N] | [How] |
| 3. [Waiting/loading] | [Waits] | [Anxious, uncertain — "did it work?"] | [Y/N] | [Loading state design, progress indication] |
| 4. [Result/outcome] | [Sees result] | [Relieved, satisfied, confused, frustrated] | [Y/N] | [How success/error state addresses this] |
| 5. [Recovery / next action] | [Action] | [Emotion] | [Y/N] | [How] |

---

#### Dimension 4: AI Slop Risk (0-10)

**What to evaluate:** Is the UX design specific to THIS product, or could it describe any generic app? Check every element against the AI Slop Blacklist above. Count violations. But also evaluate beyond the blacklist: is the design language specific, opinionated, and intentional?

**Scoring rubric:**
- **0-3:** Multiple blacklist violations. Design reads like a template. Microcopy is generic ("Welcome to...", "Get started"). Layout follows cookie-cutter patterns.
- **4-6:** No blacklist violations, but design is still generic. Could swap in any product name and the UX would still "work." Nothing about the UX reflects the specific domain, user context, or product personality.
- **7-8:** Design is specific to this product. Microcopy references actual user tasks. Layout serves the actual information hierarchy (not a template). No blacklist violations.
- **9-10:** Design is unmistakably THIS product. Screen layouts reflect the actual data shapes and user tasks. Microcopy uses domain language. Empty states reference real scenarios. Error messages name specific failure modes. The UX could not be copy-pasted to another product without rewriting everything.

**How to evaluate:**
- Run each screen through the 10-item blacklist. Any match is a flag.
- Read all microcopy. Replace the product name with "GenericApp." Does the copy still make sense? If yes, it is too generic.
- Check for Subtraction Default (Cognitive Pattern 9): is every element earning its place, or are elements present because "that is what apps have"?

---

#### Dimension 5: Design System Alignment (0-10)

**What to evaluate:** Does the UX design align with the project's DESIGN.md (if one exists)? Are interaction patterns consistent with established conventions? Does the UX introduce new patterns without acknowledging existing ones?

**Scoring rubric:**
- **0-3:** No reference to DESIGN.md. UX introduces patterns that contradict existing conventions. Terminology is inconsistent.
- **4-6:** DESIGN.md is referenced but not consistently applied. Some patterns align, others introduce new conventions without rationale.
- **7-8:** All patterns align with DESIGN.md. New patterns are justified. Terminology is consistent. Component behavior expectations match established norms.
- **9-10:** Full alignment with DESIGN.md. New patterns are proposed with rationale and documented as candidates for the design system. Interaction models, naming conventions, and behavioral expectations are fully consistent. The UX design explicitly references DESIGN.md decisions and extends them coherently.

**How to evaluate:**
- If `DESIGN.md` exists: read it. Check every interaction pattern, component behavior, and naming convention in the UX against it.
- If `DESIGN.md` does not exist: evaluate internal consistency. Are similar interactions handled the same way across screens? Are naming patterns consistent?
- Check that the UX does not assume UI patterns that contradict the design system's direction (e.g., specifying a sidebar navigation when DESIGN.md establishes bottom tab navigation).

---

#### Dimension 6: Responsive and Accessibility (0-10)

**What to evaluate:** Are mobile and tablet behaviors specified (not just "it stacks")? Is keyboard navigation explicitly defined? Screen reader flow? Are these feature-specific decisions or generic WCAG boilerplate?

**Scoring rubric:**
- **0-3:** No responsive strategy. No accessibility beyond "meets WCAG." Keyboard navigation not mentioned.
- **4-6:** Responsive strategy says "stacks on mobile" without specifying what stacks, what hides, or what reorders. Accessibility requirements are generic (copied from guidelines, not feature-specific).
- **7-8:** Responsive strategy specifies behavior per screen per viewport. Accessibility defines tab order, focus management for modals and dynamic content, screen reader announcements for state changes. Feature-specific, not boilerplate.
- **9-10:** Responsive strategy addresses content priority on small viewports (references Information Hierarchy from Dimension 1), touch target sizing for primary actions, and scroll behavior. Accessibility defines keyboard shortcuts, live regions for dynamic content, landmark structure, focus trap for modals, and prefers-reduced-motion behavior. Every timed interaction has an extension mechanism. Constraint Worship (Cognitive Pattern 4) is evident — mobile constraints have improved the design, not merely been accommodated.

**How to evaluate:**
- Open the responsive strategy section. For each screen, can you describe exactly what happens on mobile without guessing? If not, it is underspecified.
- Check keyboard navigation: is tab order defined for each screen? Is focus management defined for modals, route changes, and dynamic content?
- Check screen reader: are announcements defined for every state transition from Dimension 2?
- Ask: "Could a developer implement the mobile version from this spec alone?" If no, score low.

---

#### Dimension 7: Unresolved Design Decisions (0-10)

**What to evaluate:** Are there ambiguities that will haunt implementation? Places where the UX says "TBD" or relies on the developer to figure it out? Decisions that were deferred but never resolved?

**Scoring rubric:**
- **0-3:** Multiple TBDs, open questions, and "the developer can decide" handwaves. Key interactions are ambiguous. Flows have decision points without specified outcomes.
- **4-6:** Most decisions are made, but edge cases are hand-waved. Some flows have implicit assumptions that are not documented. Open questions exist but are acknowledged.
- **7-8:** All core decisions resolved. Edge cases addressed. Open questions are few, low-impact, and explicitly documented with proposed answers.
- **9-10:** Zero ambiguity. Every decision is made and justified. No TBDs remain. Edge cases are specified. The UX design is so complete that a developer could implement it without asking a single clarification question. Open Questions section exists but is empty or contains only genuine "stakeholder input needed" items with proposed defaults.

**How to evaluate:**
- Search for TBD, TODO, "to be determined," "open question," and question marks in the UX design.
- For each flow: walk through it step by step. At every branch point, is the next step unambiguous? If you have to guess, there is an unresolved decision.
- For each screen: could a developer build it from the spec alone? If they would need to ask "but what happens when...?" — that is an unresolved decision.
- Apply the Question Reflex (Cognitive Pattern 5): for every design choice, is the "why" documented?

---

### Review Scorecard

| # | Dimension | Score | Status |
|---|-----------|-------|--------|
| 1 | Information Architecture | /10 | |
| 2 | Interaction State Coverage | /10 | |
| 3 | User Journey Emotional Arc | /10 | |
| 4 | AI Slop Risk | /10 | |
| 5 | Design System Alignment | /10 | |
| 6 | Responsive and Accessibility | /10 | |
| 7 | Unresolved Design Decisions | /10 | |
| | **TOTAL** | **/70** | |

**Pass threshold:** Total >= 49/70 AND no single dimension below 5/10.

**Remediation rule:** For any dimension scoring under 7/10, the reviewer must:
1. Explain concretely what a 10/10 would look like for THIS specific UX design (not generic advice).
2. Fix the UX design to achieve at least 7/10 on that dimension.
3. Re-score after fixes.

In interactive mode: present scores and ask if user wants to address each dimension.
In auto mode: P0 fixes anything under 7 automatically and re-scores.

## What UX Design Is (And Is Not)

UX design defines the structure, flow, and behavior of the experience. It determines what screens exist, what states each screen can be in, how users navigate between them, what information matters most, and what happens when things go wrong.

**UX design does NOT define:** Colors, fonts, spacing, visual style, component libraries, design tokens, animation specifics. Those are UI design (Phase 5). If you catch yourself writing hex values, font names, or pixel measurements, stop — you have crossed into UI territory.

**The boundary:** UX says "this screen has a primary action, a list of results, and a filter panel." UI says "the primary action is a 48px filled button in brand-primary, the list uses 16px inter-line spacing, and the filter panel collapses below 768px into a bottom sheet."

## Feature Types and UX Implications

All three feature types go through UX design, but the experience they design is different:

| Type | UX Focus | Screens/Views |
|------|----------|---------------|
| Feature | End-user flows — the journey a persona takes through the UI | Application screens, modals, forms, result views |
| Enabler | Admin/monitoring UX — how operators observe and control the system | Dashboards, status views, configuration panels, log viewers |
| Integration | Configuration UX — how the integration is set up and monitored | Setup wizards, connection status, credential management, webhook logs |

**Enablers without any UX surface** (pure background services with no admin interface) can skip this phase. The gate question is: "Does any human ever look at a screen related to this?" If no, skip to design-tech.

## When To Use

- After write-spec produces a DRAFT feature spec with user stories, ACs, and journeys
- When a feature has user-facing or admin-facing screens that need flow design
- Before invoking design-ui (requires UX-REVIEWED spec)
- When Layer 3 journey analysis reveals flow gaps that need screen-level resolution

## Prerequisites

| Artifact | Where | Required? | If missing |
|----------|-------|-----------|------------|
| Feature spec (DRAFT) | `docs/specs/features/<feature>.md` | Yes — must have stories + ACs | Route to `write-spec` |
| Journey doc(s) | `docs/specs/journeys/J*.feature.md` | Yes — must reference the feature's ACs | Route to `write-spec` to trigger `write-journeys` |
| Personas | `docs/specs/personas/P*.md` | Required for Features | Enablers/Integrations use system consumers |
| Vision | `docs/specs/vision.md` | Recommended | Provides product boundaries and principles |

**Gate:** Do not start UX design without a DRAFT spec. If the spec lacks user stories and ACs, route to `write-spec` first.

## Process

### Step 1: Read The Spec, Journeys, and Personas

Read the DRAFT feature spec, all referenced journey docs, and all relevant personas. Understand:

- What user stories need screen flows
- What ACs define the experience (not just the outcome)
- What journey steps involve UI or admin interaction
- What personas use this feature (their goals, pain points, technical comfort)
- What Layer 3 findings affect the experience

```bash
# Read the feature spec
cat docs/specs/features/<feature-name>.md

# Read referenced journeys
ls docs/specs/journeys/J*.feature.md 2>/dev/null
cat docs/specs/journeys/J*-<feature-name>.feature.md 2>/dev/null

# Read personas (for Features)
ls docs/specs/personas/P*.md 2>/dev/null

# Read vision for product boundaries
cat docs/specs/vision.md 2>/dev/null | head -80
```

### Step 2: Screen Inventory

Identify every distinct screen or view the feature requires. A "screen" is any state the user perceives as a distinct place — a page, a modal, a panel, an overlay.

```markdown
## Screen Inventory

| Screen ID | Name | Type | Entry Point | Primary Action |
|-----------|------|------|-------------|----------------|
| S1 | [Name] | [Page/Modal/Panel/Overlay/Toast] | [How user gets here] | [What user does here] |
| S2 | [Name] | [Type] | [Entry point] | [Primary action] |
```

**Rules:**
- Every user story must map to at least one screen
- Every journey UI step must happen on a named screen
- Empty states, error states, and loading states are NOT separate screens — they are states of a screen (Step 3)
- Modals and overlays are screens if they require user decisions; they are components if they are pure confirmation

**For Enablers:** Screens are admin dashboards, monitoring views, configuration panels.

**For Integrations:** Screens are setup wizards, connection status views, credential management forms.

### Step 3: State Machines Per Screen

Each screen has a finite set of states. Map them as a state machine.

```markdown
## State Machines

### S1: [Screen Name]

| State | Description | Transitions To | Trigger |
|-------|-------------|---------------|---------|
| EMPTY | No data, first visit | LOADING | User opens screen |
| LOADING | Fetching data | POPULATED / ERROR | API response |
| POPULATED | Data displayed | LOADING / ACTION_PENDING | User scrolls, filters, selects |
| ACTION_PENDING | User initiated action, awaiting response | POPULATED / ERROR | API response |
| ERROR | Something failed | LOADING | User retries |
| STALE | Data older than threshold | LOADING | Auto-refresh or user refresh |
```

**Rules:**
- Every screen must have at minimum: LOADING, POPULATED, EMPTY, ERROR
- Identify what triggers each transition (user action, system event, timer)
- Name the data conditions — what makes a screen "empty" vs "populated"?
- Consider offline/degraded states if the app should work offline

**Diagram format:** Use ASCII state diagrams for clarity:

```
EMPTY ──[open]──→ LOADING ──[success]──→ POPULATED
                     │                       │
                     ├──[failure]──→ ERROR    ├──[action]──→ ACTION_PENDING
                     │                ↑      │                    │
                     │                └──────←┘──[retry]─────────←┘
                     │                       │
                     └──[empty result]──→ EMPTY (with prompt)
```

### Step 4: Flow Diagrams

Map how users navigate between screens. The flow diagram shows the paths through the feature, not just individual screens.

```markdown
## Flow Diagrams

### Primary Flow: [Journey name / Happy path]

S1 (Entry) → S2 (Selection) → S3 (Confirmation) → S4 (Result)
     ↓              ↓                ↓
  [back nav]    [cancel → S1]   [error → S3-ERROR state]

### Alternative Flow: [Edge case / Error recovery]

S1 → S2 → S2-ERROR → S2 (retry) → S3 → S4
```

**Rules:**
- One flow per journey scenario at minimum
- Show branching points (where user makes a choice)
- Show error recovery paths (where user gets back on track)
- Show exit points (where user can abandon the flow)
- Map each AC to the flow that exercises it

```markdown
### AC Coverage

| AC | Flow | Screen | State |
|----|------|--------|-------|
| MATCH-01 | Primary Flow | S3 | POPULATED |
| MATCH-02 | Primary Flow | S2 | LOADING → POPULATED |
| MATCH-03 | Error Recovery | S2 | ERROR |
```

### Step 5: Information Hierarchy

For each screen, define what information matters most. This is NOT layout — it is priority. UI design will determine how priority maps to visual weight.

```markdown
## Information Hierarchy

### S1: [Screen Name]

| Priority | Element | Content | Why |
|----------|---------|---------|-----|
| 1 (highest) | [Primary content] | [What it shows] | [Why it's most important — ties to persona goal] |
| 2 | [Secondary content] | [What it shows] | [Supports the primary task] |
| 3 | [Tertiary content] | [What it shows] | [Nice to have, not essential to the task] |
| Navigation | [Nav elements] | [What they do] | [How user moves forward/back] |
| Metadata | [Supporting info] | [What it shows] | [Context, not actionable] |
```

**Rules:**
- Priority 1 must directly serve the screen's primary action (from Step 2)
- If two things are "equally important," you have not prioritized — pick one
- Reference persona goals to justify priority decisions
- Metadata goes last unless the feature IS about metadata (e.g., analytics dashboard)

### Step 6: Error and Loading States

Define the experience for every non-happy-path state. This is where most UX fails — the happy path is designed, everything else is an afterthought.

```markdown
## Error States

| Screen | Error Type | User Sees | Recovery Action | Copy Tone |
|--------|-----------|-----------|-----------------|-----------|
| S1 | Network failure | [What message] | [What they can do] | [Empathetic / Informative / Actionable] |
| S1 | Empty result | [What message] | [Suggestion to change input] | [Helpful, not blaming] |
| S2 | Validation error | [Inline on field] | [Fix and resubmit] | [Specific, not generic] |
| S2 | Server error | [What message] | [Retry or contact support] | [Apologetic, actionable] |
| S3 | Timeout | [What message] | [Auto-retry or manual] | [Transparent about cause] |

## Loading States

| Screen | Load Type | Duration Expected | User Sees | Interaction During Load |
|--------|----------|-------------------|-----------|------------------------|
| S1 | Initial data | <1s | Skeleton/shimmer | None — block interaction |
| S2 | Search results | 1-3s | Progress indicator | Can cancel |
| S3 | Submit action | 1-5s | Button loading state | Disable submit, allow cancel |
| S3 | Heavy processing | >5s | Progress bar with status | Can navigate away, notified on complete |
```

**Rules:**
- Every screen's ERROR state (from Step 3) must have a row here
- Loading states must specify whether the user can interact during the load
- Error copy must be actionable — "Something went wrong" is never acceptable
- Define timeout thresholds (when does "loading" become "error"?)

### Step 7: Accessibility Requirements

Define accessibility requirements specific to this feature. These are not generic WCAG guidelines — they are feature-specific decisions.

```markdown
## Accessibility Requirements

### Keyboard Navigation

| Screen | Tab Order | Keyboard Shortcuts | Focus Management |
|--------|-----------|-------------------|-----------------|
| S1 | [Logical tab sequence] | [Feature-specific shortcuts] | [Where focus goes on load / after action] |

### Screen Reader

| Screen | Announcements | Live Regions | Landmark Structure |
|--------|--------------|-------------|-------------------|
| S1 | [What gets announced and when] | [Dynamic content that updates] | [Main, nav, complementary] |

### Cognitive

| Concern | Decision | Rationale |
|---------|----------|-----------|
| Reading level | [Target level] | [Persona context] |
| Animation | [Reduce motion support?] | [What changes when prefers-reduced-motion is set] |
| Time limits | [Any timed interactions?] | [How to extend / disable time limits] |
| Error prevention | [Confirmation before destructive actions?] | [Which actions are reversible vs. destructive] |
```

**Rules:**
- Keyboard navigation must cover every interactive element
- Focus management must be specified for modals, dynamic content, and route changes
- Screen reader announcements must be specified for state changes (Step 3 transitions)
- Every timed interaction must have an extension mechanism

### Step 8: Responsive Strategy

Define how the experience adapts across viewport sizes. This is behavior strategy, not pixel breakpoints — UI design handles specific measurements.

```markdown
## Responsive Strategy

### Approach: [Mobile-first / Desktop-first / Adaptive]

### Behavior by Viewport

| Screen | Small (Mobile) | Medium (Tablet) | Large (Desktop) |
|--------|---------------|-----------------|-----------------|
| S1 | [How it adapts — stack, collapse, hide, reorder] | [Behavior] | [Full layout] |
| S2 | [How it adapts] | [Behavior] | [Full layout] |

### Critical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Navigation pattern | [Bottom tabs / hamburger / sidebar / persistent] | [Why for this feature's flow] |
| Content priority on small viewport | [What hides / collapses / moves] | [Based on info hierarchy Step 5] |
| Touch targets | [Minimum size strategy] | [Based on primary actions] |
| Scroll behavior | [Infinite scroll / pagination / load more] | [Based on data volume and UX pattern] |
```

**Rules:**
- Do not specify breakpoint pixel values — that is UI design
- Do specify behavioral strategy (stack vs. hide vs. collapse)
- Small viewport must still satisfy all ACs — no features can be desktop-only unless explicitly specified in the spec
- Touch target decisions must reference primary actions from Step 2

### Step 9: Assemble The UX Design Document

Write the complete UX design to `docs/specs/ux/<feature-name>.md`:

```markdown
# UX Design: [Feature Name]

**Feature Spec:** `docs/specs/features/<feature-name>.md`
**Status:** DRAFT (pending G2 review)
**Type:** [Feature | Enabler | Integration]
**Personas:** [P1, P3 | system consumers]
**Created:** [YYYY-MM-DD]

---

## Screen Inventory

[From Step 2]

---

## State Machines

[From Step 3]

---

## Flow Diagrams

[From Step 4]

---

## Information Hierarchy

[From Step 5]

---

## Error and Loading States

[From Step 6]

---

## Accessibility Requirements

[From Step 7]

---

## Responsive Strategy

[From Step 8]

---

## AC Traceability

| AC | Screen | State | Flow | Covered? |
|----|--------|-------|------|----------|
| [AC-ID] | [Screen] | [State] | [Flow name] | Yes / Partial / No |

---

## Open Questions

[Any UX decisions that need stakeholder input before proceeding]
```

### Step 10: AC Traceability Check

Walk through every AC from the feature spec and verify the UX design addresses it.

```markdown
### AC Traceability

| AC | Screen | State | Flow | Covered? |
|----|--------|-------|------|----------|
| MATCH-01 | S3 | POPULATED | Primary Flow | Yes |
| MATCH-02 | S2 | LOADING → POPULATED | Primary Flow | Yes |
| MATCH-03 | S2 | ERROR | Error Recovery | Yes |
| MATCH-04 | S1 | EMPTY | First-time flow | Partial — needs empty state copy decision |
```

**Gate:** Every AC must be covered. If an AC cannot be covered by the UX design:
- The AC may need revision (feedback loop to `write-spec`)
- The screen flow may be missing a screen (go back to Step 2)
- The state machine may be missing a state (go back to Step 3)

### Step 11: Trigger G2 Review

The UX design artifact is ready for Gate G2 review. Invoke the Review Protocol:

**G2 checks:**
- Do flows cover all user stories?
- Are states complete for every screen?
- Is error handling specified (not hand-waved)?
- Are accessibility requirements feature-specific (not generic)?
- Does the responsive strategy preserve all ACs on all viewports?
- Is every AC traceable to a screen, state, and flow?

**Review Protocol steps:**
1. **Self-review** — review the UX design artifact for completeness and consistency
2. **Self-judgment** — accept or reject each finding with reasoning
3. **Cross-review** — fresh agent reviews artifact plus self-review findings
4. **Convergence check** — only medium/low issues remain? Pass. Critical/high? Fix and re-enter.
5. **Gate decision** — PASS (proceed to UI design) / FAIL (fix findings) / ESCALATE (human reviews)

### Step 12: Update Feature Spec Status

On G2 PASS, update the feature spec:

```markdown
**Status:** UX-REVIEWED
```

Add a UX Design reference:

```markdown
## UX Design

**Artifact:** `docs/specs/ux/<feature-name>.md`
**G2 Review:** PASS — [date]
```

### Step 13: Handoff

Present a summary:

```
UX design saved: docs/specs/ux/<feature-name>.md
Feature spec updated: docs/specs/features/<feature-name>.md
Status: UX-REVIEWED (was DRAFT)
Screens: N screens identified
States: M total states across all screens
Flows: K flows mapped
AC coverage: [all / N of M covered, gaps listed]
Accessibility: [keyboard, screen reader, cognitive, responsive — all addressed]

Ready for UI design. Next step:
  "Run design-ui against docs/specs/ux/<feature-name>.md"
```

**The terminal state is invoking design-ui.** This skill does not define visual design, choose colors, pick fonts, or specify component libraries.

## Feedback Loops

UX design often reveals problems upstream. Handle them:

| Discovery | Action |
|-----------|--------|
| Story implies a flow that is impossible or confusing | Route back to `write-spec` to revise the story |
| AC requires a screen state not in any journey | Route to `write-spec` to re-run `write-journeys` |
| Persona's goals conflict with the proposed flow | Route to `build-personas` to validate persona (then return) |
| Feature type unclear (does this need admin UX?) | Route to `write-spec` to clarify Type |
| Journey has UI steps that map to no screen | Add screen to inventory (Step 2) and re-check flows |

**Key principle:** It is cheaper to revise the spec now than to discover flow problems during UI design or implementation.

## Anti-Patterns

| Don't | Why | Instead |
|-------|-----|---------|
| Specify colors, fonts, or spacing | That is UI design (Phase 5) | Define priority and behavior, not visual treatment |
| Name specific UI components (e.g., "Material Card") | Couples UX to a component library | Describe what the element does, not what it is called |
| Skip error and loading states | These are where users lose trust | Every screen state machine must have ERROR and LOADING |
| Write generic accessibility boilerplate | WCAG compliance is a baseline, not a feature-specific UX decision | Define keyboard flow, focus management, and announcements for THIS feature |
| Design for desktop only | Mobile is often the primary viewport | Responsive strategy must preserve all ACs on all viewports |
| Skip AC traceability | Untraced ACs become unimplemented features | Every AC maps to a screen, state, and flow |
| Combine UX and UI into one document | Separate concerns, separate review gates | UX is structure and behavior; UI is visual and components |

## Routing

| Situation | Route to |
|-----------|----------|
| UX design complete, G2 passed | `design-ui` |
| Story requires flow revision | `write-spec` (feedback loop) |
| Persona gap discovered | `build-personas` (then return) |
| Journey flows don't match screen flows | `write-spec` to re-run `write-journeys` |
| No DRAFT spec exists | `write-spec` (prerequisite) |
| Feature has no user-facing screens | Skip to `design-tech` |

## Audit Mode

When invoked with `--audit` to review existing UX design:

1. Read `docs/specs/ux/<name>.md`
2. Check against current feature spec ACs: every AC has a screen that addresses it?
3. Check state coverage: every screen has LOADING, ERROR, EMPTY states defined?
4. Check flow completeness: can the user reach every screen from the entry point?
5. Check responsive strategy: defined for all screens?
6. Report: screen-by-screen PASS/WARN/FAIL

## Pipeline Continuation

### Self-Verify

Before declaring done, verify:

| # | Check | How | PASS/FAIL |
|---|-------|-----|-----------|
| 1 | UX design file exists | `test -f docs/specs/ux/<name>.md` | |
| 2 | Screen Inventory section present | grep for "## Screen Inventory" in output file | |
| 3 | State Machines section present | grep for "## State Machines" in output file | |
| 4 | Flow Diagram section present | grep for "## Flow Diagrams" in output file | |
| 5 | Loading/error/empty states defined for each screen | Every screen's state machine includes LOADING, ERROR, and EMPTY states | |
| 6 | No unresolved questions | grep for TBD, TODO, open questions in output file | |

If any check FAILs, fix before continuing. If a fix requires upstream changes, stop and report.

### Chaining

**If `--progressive` flag is present AND self-verify passed:**
- Check `--skip` list. If this skill is in the skip list, pass through to next.
- Invoke next skill: `design-ui --progressive --lane greenfield`

**If `--progressive` flag is absent:**
- Report results to user
- Suggest: "Next: consider running `design-ui`"
