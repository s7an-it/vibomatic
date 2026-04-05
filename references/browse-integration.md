# Browse Daemon Integration

vibomatic uses gstack's browse daemon (MIT) as the browser infrastructure layer.
All browser-dependent skills use it instead of Playwright MCP.

## Setup

gstack browse must be available as an installed skill. Check:
```bash
# If gstack is installed as a Claude Code plugin, /browse is available
# The daemon auto-starts on first use
```

## How Skills Use It

Skills that need a browser call it through the standard tool interface:

```
browser_navigate → go to URL
browser_snapshot → get page structure (ARIA tree)
browser_click → click an element
browser_fill_form → fill input fields
browser_take_screenshot → capture visual evidence
browser_console_messages → check for JS errors
browser_network_requests → check for failed requests
browser_resize → test responsive breakpoints
browser_evaluate → run JS in page context
```

## Which Skills Use Browse

| Skill | How |
|-------|-----|
| `test-journeys` | Navigate flows, click through scenarios, capture evidence |
| `track-visuals` | Screenshot all screens at multiple breakpoints |
| `write-e2e` | Verify selectors and behavior before writing tests |
| Post-deploy canary (future) | Periodic screenshots + error watching |
| Design-review mode (future) | Visual quality audit with before/after |

## Fallback

If gstack browse is not available, skills fall back to:
1. Playwright MCP (if installed) — functional but slower, no persistence
2. Manual browser — instruct user to perform actions and describe results
