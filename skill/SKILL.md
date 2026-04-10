---
name: chrome-browser
description: Chrome browser automation CLI optimized for AI agents — connects to a running Google Chrome instance via CDP (Chrome DevTools Protocol) using agent-browser. Requires an XRDP session with Chrome launched via chrome_for_openclaw.sh.
metadata: {"clawdbot":{"emoji":"🌐","requires":{"commands":["agent-browser"]},"homepage":"https://github.com/joustonhuang/chrome_for_openclaw"}}
---

# Chrome Browser Skill (CDP Mode)

Automate a real, running Google Chrome instance via CDP using `agent-browser --cdp 9222`.

Unlike the default Chromium mode, this skill connects to an **existing Chrome session** that is already
open inside your XRDP desktop — with your existing login cookies, history, and open tabs intact.

## Prerequisites

### 1. Active XRDP Session

Log in to your Linux machine via an RDP client (Windows Remote Desktop, Remmina, etc.).
This gives Chrome a real X display to render on, and lets you see exactly what the agent is doing.

### 2. Launch Chrome via chrome_for_openclaw

OpenClaw can run this step itself. It downloads and executes the launcher script directly:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/joustonhuang/chrome_for_openclaw/main/chrome_for_openclaw.sh)
```

This script starts Google Chrome with `--remote-debugging-port=9222` and waits for the CDP endpoint
to respond. Once it prints `==> Done`, Chrome is ready to accept connections.

Optional overrides:

```bash
DEBUG_PORT=9222 START_URL=https://gmail.com \
bash <(curl -fsSL https://raw.githubusercontent.com/joustonhuang/chrome_for_openclaw/main/chrome_for_openclaw.sh)
```

### 3. Install agent-browser CLI

```bash
npm install -g agent-browser
```

> Do **not** run `agent-browser install`. There is no need to download a separate Chromium binary —
> we connect directly to the Chrome instance started above.

---

## Core Concept: CDP Connection

After Chrome is running with `--remote-debugging-port=9222`, connect to it with:

```bash
# Explicit CDP port (recommended)
agent-browser --cdp 9222 <command>

# Auto-discover any running Chrome with remote debugging enabled
agent-browser --auto-connect <command>
```

All subsequent commands in this skill use `--cdp 9222`. You can also export it once to avoid
repeating it:

```bash
export AGENT_BROWSER_CDP_URL=http://127.0.0.1:9222
# Now all agent-browser commands connect to the running Chrome automatically
agent-browser open https://example.com
agent-browser snapshot -i
```

---

## Core Workflow

```bash
# Step 1: (Once per session) Launch Chrome
bash <(curl -fsSL https://raw.githubusercontent.com/joustonhuang/chrome_for_openclaw/main/chrome_for_openclaw.sh)

# Step 2: Connect and navigate
agent-browser --cdp 9222 open https://example.com

# Step 3: Snapshot to discover interactive elements
agent-browser --cdp 9222 snapshot -i

# Step 4: Interact using refs from snapshot
agent-browser --cdp 9222 click @e2
agent-browser --cdp 9222 fill @e3 "text"

# Step 5: Re-snapshot after page changes
agent-browser --cdp 9222 snapshot -i
```

### Use batch for 2+ sequential commands

```bash
agent-browser --cdp 9222 batch "open https://example.com" "snapshot -i"
agent-browser --cdp 9222 batch "click @e1" "wait 1000" "snapshot -i"
```

---

## Why CDP Instead of --channel chrome

| | `--channel chrome` | `--cdp 9222` (this skill) |
|---|---|---|
| Browser instance | Launches a new one | Connects to running Chrome |
| Login state | Empty profile | Your existing session |
| Visible in XRDP | Maybe | Always |
| Setup | None | Requires `chrome_for_openclaw.sh` |

CDP mode is the right choice when you want to automate a site you are already logged into,
without re-authenticating.

---

## Why Use This Over Built-in Browser Tool

**Use chrome-browser when:**
- Automating multi-step workflows using your existing login sessions
- Need deterministic, ref-based element selection
- Performance is critical
- Working with complex SPAs
- Want to visually monitor the agent via RDP

**Use built-in browser tool when:**
- Need screenshots/PDFs for offline analysis
- Visual inspection is the primary goal
- Browser extension integration is needed

---

## Key Commands

### Navigation
```bash
agent-browser --cdp 9222 open <url>
agent-browser --cdp 9222 back
agent-browser --cdp 9222 forward
agent-browser --cdp 9222 reload
agent-browser --cdp 9222 close
```

### Snapshot (always use -i)
```bash
agent-browser --cdp 9222 snapshot -i
agent-browser --cdp 9222 snapshot -i --urls
agent-browser --cdp 9222 snapshot -i --json
agent-browser --cdp 9222 snapshot -i -c -d 5 --json
agent-browser --cdp 9222 snapshot -s "#main" -i
```

### Interactions (ref-based)
```bash
agent-browser --cdp 9222 click @e2
agent-browser --cdp 9222 fill @e3 "text"
agent-browser --cdp 9222 type @e3 "text"
agent-browser --cdp 9222 hover @e4
agent-browser --cdp 9222 check @e5
agent-browser --cdp 9222 uncheck @e5
agent-browser --cdp 9222 select @e6 "value"
agent-browser --cdp 9222 press "Enter"
agent-browser --cdp 9222 scroll down 500
agent-browser --cdp 9222 drag @e7 @e8
```

### Get Information
```bash
agent-browser --cdp 9222 get text @e1
agent-browser --cdp 9222 get html @e2 --json
agent-browser --cdp 9222 get value @e3 --json
agent-browser --cdp 9222 get attr @e4 "href" --json
agent-browser --cdp 9222 get title --json
agent-browser --cdp 9222 get url --json
agent-browser --cdp 9222 get cdp-url
```

### Wait
```bash
agent-browser --cdp 9222 wait @e2
agent-browser --cdp 9222 wait 1000
agent-browser --cdp 9222 wait --text "Welcome"
agent-browser --cdp 9222 wait --url "**/dashboard"
agent-browser --cdp 9222 wait --fn "window.ready === true"
```

### Sessions
```bash
agent-browser --cdp 9222 --session admin open site.com
agent-browser --cdp 9222 session list
```

### State Persistence
```bash
agent-browser --cdp 9222 state save auth.json
agent-browser --cdp 9222 state load auth.json
```

### Screenshots & PDFs
```bash
agent-browser --cdp 9222 screenshot page.png
agent-browser --cdp 9222 screenshot --full page.png
agent-browser --cdp 9222 screenshot --annotate
agent-browser --cdp 9222 pdf page.pdf
```

### Network
```bash
agent-browser --cdp 9222 network requests
agent-browser --cdp 9222 network requests --type xhr,fetch
agent-browser --cdp 9222 network route "**/ads/*" --abort
```

### Tabs
```bash
agent-browser --cdp 9222 tab list
agent-browser --cdp 9222 tab new https://example.com
agent-browser --cdp 9222 tab 2
agent-browser --cdp 9222 tab close
```

### JavaScript Evaluation
```bash
agent-browser --cdp 9222 eval 'document.title'

agent-browser --cdp 9222 eval --stdin <<'EVALEOF'
JSON.stringify(Array.from(document.querySelectorAll("a")).map(a => a.href))
EVALEOF
```

---

## Snapshot Output Format

```json
{
  "success": true,
  "data": {
    "snapshot": "...",
    "refs": {
      "e1": {"role": "heading", "name": "Example Domain"},
      "e2": {"role": "button", "name": "Submit"},
      "e3": {"role": "textbox", "name": "Email"}
    }
  }
}
```

---

## Best Practices

1. **Launch Chrome first** — run `chrome_for_openclaw.sh` once per session
2. **Always use `-i` flag** — focus on interactive elements only
3. **Always use `--json`** — easier for the agent to parse
4. **Use `batch` for 2+ steps** — avoids repeated round-trips
5. **Re-snapshot after navigation** — refs are invalidated on page change
6. **Export `AGENT_BROWSER_CDP_URL`** — avoid repeating `--cdp 9222` on every command
7. **Use `--auto-connect`** if you are unsure which port Chrome is on

---

## Example: Gmail Compose

```bash
# Step 1: Launch Chrome (already logged in to Gmail)
bash <(curl -fsSL https://raw.githubusercontent.com/joustonhuang/chrome_for_openclaw/main/chrome_for_openclaw.sh)

export AGENT_BROWSER_CDP_URL=http://127.0.0.1:9222

agent-browser batch "open https://mail.google.com/mail/u/0/#inbox" "wait 2000" "snapshot -i"
# Agent identifies Compose button ref, e.g. @e4
agent-browser batch "click @e4" "wait 1000" "snapshot -i"
# Agent identifies To/Subject/Body refs
agent-browser batch \
  "fill @e5 \"recipient@example.com\"" \
  "fill @e6 \"Subject line\"" \
  "fill @e7 \"Email body\"" \
  "click @e8"
```

---

## Example: Import Existing Login Session

If Chrome is already logged into a site, save the auth state for future sessions:

```bash
agent-browser --cdp 9222 --auto-connect state save ./auth.json
# Reuse it later (even in a fresh agent-browser session without --cdp)
agent-browser state load ./auth.json
agent-browser open https://app.example.com/dashboard
```

---

## Installation Summary

```bash
# Step 1: Log in to your Linux machine via RDP

# Step 2: Launch Chrome in CDP debug mode
bash <(curl -fsSL https://raw.githubusercontent.com/joustonhuang/chrome_for_openclaw/main/chrome_for_openclaw.sh)

# Step 3: Install agent-browser (skip `agent-browser install` — no Chromium needed)
npm install -g agent-browser

# Step 4: Connect and automate
export AGENT_BROWSER_CDP_URL=http://127.0.0.1:9222
agent-browser batch "open https://example.com" "snapshot -i"
```

---

## Credits

Chrome launcher script by [joustonhuang](https://github.com/joustonhuang/chrome_for_openclaw)

agent-browser CLI by [Vercel Labs](https://github.com/vercel-labs/agent-browser)
