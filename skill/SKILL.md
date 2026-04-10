---
name: chrome-browser
description: Chrome browser automation CLI optimized for AI agents — uses Google Chrome (not Chromium) with XRDP display support and CDP-based session management
metadata: {"clawdbot":{"emoji":"🌐","requires":{"commands":["agent-browser"]},"homepage":"https://github.com/joustonhuang/chrome_for_openclaw"}}
---

# Chrome Browser Skill

Browser automation using Google Chrome (not Chromium) via the `agent-browser` CLI.
Designed for use inside an XRDP session where Chrome runs as a visible, persistent debug session exposed over CDP.

## Prerequisites

### 1. Active XRDP Session

This skill requires an active X display. Log in to your Linux machine using an RDP client
(Windows Remote Desktop, Remmina, etc.) before using this skill.

### 2. Launch Chrome via chrome_for_openclaw

Download and run the launcher script to start Chrome in CDP debug mode:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/joustonhuang/chrome_for_openclaw/main/chrome_for_openclaw.sh)
```

This script:
- Kills any existing Chrome processes
- Starts Google Chrome with `--remote-debugging-port=9222`
- Waits for the DevTools endpoint to respond
- Is safe for OpenClaw to self-download and self-execute

You can also override defaults via environment variables:

```bash
DEBUG_PORT=9222 START_URL=https://gmail.com \
bash <(curl -fsSL https://raw.githubusercontent.com/joustonhuang/chrome_for_openclaw/main/chrome_for_openclaw.sh)
```

### 3. Install agent-browser CLI

```bash
npm install -g agent-browser
```

> No need to run `agent-browser install` — Chrome is already installed on the system.
> This skill uses the `--channel chrome` flag to point agent-browser at the real Chrome binary.

---

## Why Use Google Chrome Instead of Chromium

- Uses your existing logged-in Chrome profile and session cookies
- No need to download or manage a separate Chromium binary
- Works within an XRDP session — you see exactly what the agent is doing in real time
- Chrome is already installed and maintained by the system

---

## Why Use This Over Built-in Browser Tool

**Use chrome-browser when:**
- Automating multi-step workflows using existing login sessions
- Need deterministic element selection
- Performance is critical
- Working with complex SPAs
- Want to visually monitor what the agent is doing via RDP

**Use built-in browser tool when:**
- Need screenshots/PDFs for analysis
- Visual inspection required
- Browser extension integration needed

---

## Core Workflow

```bash
# 1. (One-time per session) Launch Chrome
bash <(curl -fsSL https://raw.githubusercontent.com/joustonhuang/chrome_for_openclaw/main/chrome_for_openclaw.sh)

# 2. Navigate and snapshot
agent-browser --channel chrome open https://example.com
agent-browser --channel chrome snapshot -i --json

# 3. Parse refs from JSON, then interact
agent-browser --channel chrome click @e2
agent-browser --channel chrome fill @e3 "text"

# 4. Re-snapshot after page changes
agent-browser --channel chrome snapshot -i --json
```

### Tip: Avoid repeating --channel chrome

Set the channel once in your shell session:

```bash
export PLAYWRIGHT_BROWSER_CHANNEL=chrome
# Now all agent-browser calls use Chrome automatically
agent-browser open https://example.com
agent-browser snapshot -i --json
```

---

## Key Commands

### Navigation
```bash
agent-browser --channel chrome open <url>
agent-browser --channel chrome back | forward | reload | close
```

### Snapshot (Always use -i --json)
```bash
agent-browser --channel chrome snapshot -i --json
agent-browser --channel chrome snapshot -i -c -d 5 --json
agent-browser --channel chrome snapshot -s "#main" -i
```

### Interactions (Ref-based)
```bash
agent-browser --channel chrome click @e2
agent-browser --channel chrome fill @e3 "text"
agent-browser --channel chrome type @e3 "text"
agent-browser --channel chrome hover @e4
agent-browser --channel chrome check @e5 | uncheck @e5
agent-browser --channel chrome select @e6 "value"
agent-browser --channel chrome press "Enter"
agent-browser --channel chrome scroll down 500
agent-browser --channel chrome drag @e7 @e8
```

### Get Information
```bash
agent-browser --channel chrome get text @e1 --json
agent-browser --channel chrome get html @e2 --json
agent-browser --channel chrome get value @e3 --json
agent-browser --channel chrome get attr @e4 "href" --json
agent-browser --channel chrome get title --json
agent-browser --channel chrome get url --json
agent-browser --channel chrome get count ".item" --json
```

### Check State
```bash
agent-browser --channel chrome is visible @e2 --json
agent-browser --channel chrome is enabled @e3 --json
agent-browser --channel chrome is checked @e4 --json
```

### Wait
```bash
agent-browser --channel chrome wait @e2
agent-browser --channel chrome wait 1000
agent-browser --channel chrome wait --text "Welcome"
agent-browser --channel chrome wait --url "**/dashboard"
agent-browser --channel chrome wait --load networkidle
agent-browser --channel chrome wait --fn "window.ready === true"
```

### Sessions (Isolated Browsers)
```bash
agent-browser --channel chrome --session admin open site.com
agent-browser --channel chrome --session user open site.com
agent-browser --channel chrome session list
```

### State Persistence
```bash
agent-browser --channel chrome state save auth.json
agent-browser --channel chrome state load auth.json
```

### Screenshots & PDFs
```bash
agent-browser --channel chrome screenshot page.png
agent-browser --channel chrome screenshot --full page.png
agent-browser --channel chrome pdf page.pdf
```

### Network Control
```bash
agent-browser --channel chrome network route "**/ads/*" --abort
agent-browser --channel chrome network route "**/api/*" --body '{"x":1}'
agent-browser --channel chrome network requests --filter api
```

### Cookies & Storage
```bash
agent-browser --channel chrome cookies
agent-browser --channel chrome cookies set name value
agent-browser --channel chrome storage local key
agent-browser --channel chrome storage local set key val
```

### Tabs & Frames
```bash
agent-browser --channel chrome tab new https://example.com
agent-browser --channel chrome tab 2
agent-browser --channel chrome frame @e5
agent-browser --channel chrome frame main
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

1. **Always launch Chrome first** — run `chrome_for_openclaw.sh` at the start of each session
2. **Always use `-i` flag** — focus on interactive elements
3. **Always use `--json`** — easier to parse
4. **Wait for stability** — `agent-browser --channel chrome wait --load networkidle`
5. **Save auth state** — skip login flows with `state save/load`
6. **Use sessions** — isolate different browser contexts
7. **Set `PLAYWRIGHT_BROWSER_CHANNEL=chrome`** — avoid repeating `--channel chrome`

---

## Example: Gmail Workflow

```bash
# Launch Chrome (already logged into Gmail)
bash <(curl -fsSL https://raw.githubusercontent.com/joustonhuang/chrome_for_openclaw/main/chrome_for_openclaw.sh)

export PLAYWRIGHT_BROWSER_CHANNEL=chrome

agent-browser open https://mail.google.com/mail/u/0/#inbox
agent-browser wait --load networkidle
agent-browser snapshot -i --json
# AI identifies compose button @e1
agent-browser click @e1
agent-browser wait --load networkidle
agent-browser snapshot -i --json
# AI fills in To, Subject, Body
agent-browser fill @e2 "recipient@example.com"
agent-browser fill @e3 "Subject line"
agent-browser fill @e4 "Email body text"
agent-browser click @e5  # Send button
```

---

## Example: Multi-Session Testing

```bash
export PLAYWRIGHT_BROWSER_CHANNEL=chrome

# Admin session
agent-browser --session admin open app.com
agent-browser --session admin state load admin-auth.json
agent-browser --session admin snapshot -i --json

# User session (simultaneous)
agent-browser --session user open app.com
agent-browser --session user state load user-auth.json
agent-browser --session user snapshot -i --json
```

---

## Installation Summary

```bash
# Step 1: Log in via RDP to your Linux machine

# Step 2: Launch Chrome in debug mode
bash <(curl -fsSL https://raw.githubusercontent.com/joustonhuang/chrome_for_openclaw/main/chrome_for_openclaw.sh)

# Step 3: Install agent-browser CLI
npm install -g agent-browser

# Step 4: Start automating
export PLAYWRIGHT_BROWSER_CHANNEL=chrome
agent-browser open https://example.com
agent-browser snapshot -i --json
```

---

## Credits

Chrome launcher script by [joustonhuang](https://github.com/joustonhuang/chrome_for_openclaw)

agent-browser CLI by [Vercel Labs](https://github.com/vercel-labs/agent-browser)
