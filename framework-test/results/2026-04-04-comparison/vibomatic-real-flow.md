# Vibomatic Real Flow: What Actually Happens When You Say "Build Me X"

## The Honest Answer

**Vibomatic is NOT an automated pipeline.** There is no orchestrator that chains skills together. Each skill must be manually invoked by the user (or by an operator playing the user). The "pipeline" is a documented sequence — a recipe, not a machine.

```
User says: "Build me a todo app"
                │
                ▼
        ┌───────────────┐
        │ Claude reads   │ ← vibomatic SKILL.md files are in .claude/
        │ skill preambles│   and loaded into every conversation
        └───────┬───────┘
                │
                ▼
        Does Claude auto-invoke a skill?
                │
           ┌────┴────┐
           │  MAYBE  │ ← Some skills say "proactively invoke"
           └────┬────┘   but there's no hard routing
                │
                ▼
        In practice: Claude says
        "I'll use the writing-spec skill..."
        or "Let me start with vision-sync..."
        │
        ▼
        USER must approve or redirect
```

### What "proactively invoke" means in practice

Several skills have `description` fields that say things like:
- vision-sync: "Triggers on 'set the vision', 'product direction'..."  
- feature-discovery: "Triggers on 'I have an idea', 'what should we build'..."
- workflow-compass: "Triggers on 'what should I do next', 'which skill'..."

Claude Code's skill matching reads these descriptions and MAY auto-select a skill. But:
1. It picks ONE skill per turn, not a chain
2. The user must approve or the skill fires based on the description match
3. After a skill completes, the user must say something to trigger the next one

### The Three Ways a Skill Gets Invoked

```
1. USER EXPLICITLY ASKS
   User: "/writing-spec" or "write the spec for this feature"
   → Claude invokes the skill directly

2. CLAUDE MATCHES DESCRIPTION
   User: "I have an idea for a feature"
   → Claude's skill routing matches feature-discovery description
   → Claude says "I'll use feature-discovery..." and invokes it

3. PREVIOUS SKILL SUGGESTS NEXT
   writing-spec finishes → output says "Next: run spec-ac-sync"
   → But Claude doesn't auto-invoke it
   → User must say "ok do that" or "what's next?"
   → Then Claude invokes spec-ac-sync
```

**No skill auto-chains to the next.** Every transition requires a user turn.

---

## Step-by-Step: "Build me a todo app"

### What the user experiences

```
USER: "Build me a todo app with tasks, due dates, and categories"

TURN 1 — Claude routes to feature-discovery or vision-sync
┌─────────────────────────────────────────────────────┐
│ Claude: "I'll use the vision-sync skill to          │
│ establish the product direction."                    │
│                                                      │
│ [Creates docs/specs/vision.md]                       │
│                                                      │
│ "Vision doc created. Next I'd recommend running      │
│ persona-builder to define who uses this."             │
└─────────────────────────────────────────────────────┘
                    │
                    │ USER MUST RESPOND
                    ▼
USER: "Ok, do that"

TURN 2 — persona-builder
┌─────────────────────────────────────────────────────┐
│ Claude: "I'll use the persona-builder skill."        │
│                                                      │
│ [Discovers 2 personas from vision]                   │
│ [Creates P1-task-manager.md, P2-team-lead.md]        │
│                                                      │
│ "2 personas created. Next: feature-discovery to      │
│ validate the feature scope, or writing-spec to       │
│ start specifying."                                   │
└─────────────────────────────────────────────────────┘
                    │
                    │ USER MUST RESPOND
                    ▼
USER: "Write the spec"

TURN 3 — writing-spec
┌─────────────────────────────────────────────────────┐
│ Claude: "I'll use the writing-spec skill."           │
│                                                      │
│ [Reads vision + personas]                            │
│ [Writes feature spec with 4 user stories, 15 ACs]   │
│ [Identifies cascade deps: none for a simple todo]    │
│                                                      │
│ "Feature spec created (DRAFT). Next: writing-ux-     │
│ design to define screen flows, or spec-ac-sync to    │
│ audit the ACs first."                                │
└─────────────────────────────────────────────────────┘
                    │
                    │ USER MUST RESPOND
                    ▼
USER: "Do the UX design"

TURN 4 — writing-ux-design
┌─────────────────────────────────────────────────────┐
│ Claude: "I'll use the writing-ux-design skill."      │
│                                                      │
│ MAY ASK: "Should the todo list be a single-page      │
│ app or multi-page?" → User answers                   │
│                                                      │
│ [Creates docs/specs/ux/todo-management.md]           │
│ [Screen inventory, state machines, flows]            │
│                                                      │
│ "UX design complete. Next: writing-ui-design."       │
└─────────────────────────────────────────────────────┘
                    │
                    │ ... pattern continues for each skill ...
                    ▼

TURNS 5-11 — ui-design → tech-design → review → change-set → promote → verify
Each requires a user turn to invoke.
```

### Minimum user turns for full pipeline

| Phase | Skill | User says | Skill asks questions? |
|-------|-------|-----------|----------------------|
| 1 | vision-sync | "Build me a todo app" | Maybe (new vs existing?) |
| 2 | persona-builder | "Ok, define personas" | Maybe (approve discoveries?) |
| 3 | writing-spec | "Write the spec" | Maybe (scope clarifications) |
| 4 | writing-ux-design | "Do UX design" | Yes (UX choices) |
| 5 | writing-ui-design | "Do UI design" | Maybe (design preferences) |
| 6 | writing-technical-design | "Do tech design" | Maybe (architecture choices) |
| 7 | review-protocol | "Review it" | No (runs autonomously) |
| 8 | writing-change-set | "Write the code" | Maybe (scope confirmation) |
| 9 | promoting-change-set | "Promote it" | No |
| 10 | verifying-promotion | "Verify it" | No |
| | _Start the server_ | `npm start` | — |
| 11 | spec-code-sync | "Sync specs to code" | No |
| 12 | journey-qa-ac-testing | "Run QA" | No (needs running server) |
| 13 | agentic-e2e-playwright | "Write E2E tests" | No |

**Minimum turns: 13 user messages** to go from "build me X" to verified code with tests.

In practice: **15-25 turns** because skills ask clarifying questions and the user gives feedback.

---

## What IS Automated vs What ISN'T

### Automated (happens without user intervention)
- ✅ Skill reads prior artifacts (vision, personas, specs) from disk
- ✅ Skill outputs artifacts to the correct path
- ✅ Skill suggests what to run next (in its closing message)
- ✅ Review protocol runs self-review + self-judgment without user input
- ✅ spec-code-sync scans code without user input
- ✅ writing-change-set writes all code parts in one skill invocation
- ✅ Each skill maintains the spec lifecycle state (DRAFT → BASELINED etc.)

### NOT Automated (requires user action)
- ❌ No skill auto-invokes the next skill in the pipeline
- ❌ No orchestrator chains skills together
- ❌ User must approve or trigger each phase transition
- ❌ workflow-compass is advisory (tells you what to do next, doesn't do it)
- ❌ If the user doesn't know the pipeline order, they must ask workflow-compass
- ❌ Review gate decisions require user acknowledgment
- ❌ Server must be started manually before QA/E2E skills

### Could Be Automated But Isn't Yet
- ⚠️ An "autopilot" mode that chains skills 1-13 automatically
- ⚠️ Auto-starting the server after writing-change-set
- ⚠️ Auto-running spec-code-sync after promoting-change-set
- ⚠️ Pipeline state tracking ("you're at Phase 4, 5 phases to go")

---

## The Real Bottleneck

The pipeline's value is in the ARTIFACTS it produces, not in the automation. Each skill adds a layer of constraint:

```
Turn 1: vision-sync        → "What product?"         (bounds the space)
Turn 2: persona-builder    → "For whom?"             (bounds the users)
Turn 3: writing-spec       → "What exactly?"         (bounds the features)
Turn 4: writing-ux-design  → "What experience?"      (bounds the flows)
Turn 5: writing-ui-design  → "What look?"            (bounds the visuals)
Turn 6: writing-tech-design → "What architecture?"   (bounds the code)
Turn 7: writing-change-set → "What code, exactly?"   (produces the code)
```

Each turn narrows the output space. By Turn 7, the code is highly constrained by everything above it. This is the doctrine's "progressive narrowing" — but it requires the USER to drive each transition.

### Comparison: How Other Frameworks Handle This

| Framework | Automation level | How transitions work |
|-----------|-----------------|---------------------|
| **Vibomatic** | Manual chaining | User invokes each skill, gets suggestion for next |
| **gstack** | Manual chaining | User invokes `/office-hours`, then `/autoplan` chains 3 reviews automatically, then user codes |
| **obra/superpowers** | Semi-auto | `brainstorming` explicitly says "invoke writing-plans next"; `executing-plans` auto-batches tasks |
| **Raw** | N/A | Single prompt, single response |

**gstack's `/autoplan` is the closest to real automation** — it chains CEO → design → eng review in one skill invocation with auto-decisions. Vibomatic has no equivalent.

---

## What a "Build Me X" Autopilot Would Look Like

If vibomatic had a true autopilot for simple "build X" requests:

```
USER: "Build me a todo app with tasks, due dates, and categories"

AUTOPILOT:
  1. Detect: greenfield, simple scope, no existing artifacts
  2. Run vision-sync (auto-approve if greenfield)
  3. Run persona-builder Mode 7 (auto-approve discoveries)
  4. Run writing-spec (stop and ask if cascade deps > 2)
  5. Run writing-ux-design (auto-choose defaults for simple apps)
  6. Run writing-ui-design (auto-choose from design system if exists)
  7. Run writing-technical-design (auto-approve if no feasibility conflicts)
  8. Run review-protocol (auto-pass if no critical/high findings)
  9. Run writing-change-set (all parts)
  10. Run promoting-change-set
  11. Start server
  12. Run spec-code-sync
  13. Run journey-qa-ac-testing
  14. Run agentic-e2e-playwright
  15. Report results

STOP POINTS (require user):
  - Cascade deps > 2 (scope exploded — confirm)
  - Review protocol finds critical issues
  - Server fails to start (fix needed)
  - QA finds failures (fix or accept)
```

**This autopilot does not exist today.** The framework-test/autopilot-protocol.md describes something similar for TESTING purposes, but there is no production autopilot for building features.

---

## Summary

| Question | Answer |
|----------|--------|
| Is vibomatic fully automated? | **No.** Each skill is manual. |
| Does it chain skills automatically? | **No.** User drives each transition. |
| Does it know what comes next? | **Yes.** Each skill suggests the next step. workflow-compass knows the graph. |
| How many user turns for a full build? | **13 minimum, 15-25 typical** |
| What IS automated within each skill? | Artifact reading, output writing, spec state tracking, code generation |
| What's the biggest automation gap? | No orchestrator to chain the 13 skills into one "build me X" flow |
| Does `/autoplan` (gstack) solve this? | Partially — it chains 3 review skills, but not the whole pipeline |
