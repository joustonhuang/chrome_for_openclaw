# chrome_for_openclaw
This is not a traditional OpenClaw “Skill.” It enables agents to control a real browser via Chrome DevTools Protocol (CDP), operating through live sessions and AJAX flows. This approach minimizes token usage, removes the need for API integrations, and allows agents to perform most browser-based tasks just like a human user.

It's only for Debian/Ubuntu for now. (Welcome if someone wants to port to Windows / macOS.)

---

## How It Works (Typical Setup)

This script is designed to be used alongside **XRDP**. The intended workflow is:

1. You log in to your Linux machine via an **RDP client** (e.g., Windows Remote Desktop, Remmina). This gives you an active X display session.
2. Inside that RDP session, OpenClaw is running and has shell access to the machine.
3. You instruct OpenClaw to **download and run this script** — it will fetch it directly from GitHub via `curl` and launch Chrome in debug mode within your RDP display.
4. Chrome exposes the **DevTools Protocol** on `localhost:9222`, which OpenClaw then uses to control the browser.

> This script is safe for OpenClaw to self-install and self-execute. No manual setup is required beyond having Chrome and XRDP in place.

---

## Required: Install the OpenClaw Skill

This script alone is not enough. OpenClaw also needs to know **how to operate the browser**.
Install the companion skill so your agent understands the full command set:

**[openclaw-agent-browser-clawdbot](https://clawhub.ai/hsyhph/openclaw-agent-browser-clawdbot)**

The skill teaches OpenClaw to:
- Connect to Chrome via CDP (`agent-browser --cdp 9222`)
- Take accessibility tree snapshots and interact with elements by ref
- Handle authentication, sessions, tabs, screenshots, and more

The two components work together:

| Component | Role |
|---|---|
| `chrome_for_openclaw.sh` | Launches and manages the Chrome process |
| `openclaw-agent-browser-clawdbot` skill | Teaches the agent how to control the browser |

Additional workflow-specific CDP skills live here:
- https://github.com/joustonhuang/openclaw-cdp-skills
- First example: `cdp-gmail-delivery`

---

## Quick Start (via curl)

### Run directly (one-shot)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/joustonhuang/chrome_for_openclaw/main/chrome_for_openclaw.sh)
```

### Download, then run

```bash
curl -fsSL https://raw.githubusercontent.com/joustonhuang/chrome_for_openclaw/main/chrome_for_openclaw.sh -o chrome_for_openclaw.sh
chmod +x chrome_for_openclaw.sh
./chrome_for_openclaw.sh
```

### Override defaults via environment variables

All settings are configurable without editing the script:

```bash
CHROME_BIN=/usr/bin/chromium \
DEBUG_PORT=9223 \
USER_DATA_DIR=/tmp/my-chrome-profile \
START_URL=https://github.com \
WAIT_SECS=8 \
bash <(curl -fsSL https://raw.githubusercontent.com/joustonhuang/chrome_for_openclaw/main/chrome_for_openclaw.sh)
```

| Variable | Default | Description |
|---|---|---|
| `CHROME_BIN` | `/opt/google/chrome/chrome` | Path to Chrome binary |
| `DEBUG_PORT` | `9222` | Chrome remote debugging port |
| `USER_DATA_DIR` | `/tmp/chrome4openclaw` | Chrome user profile directory |
| `START_URL` | `https://mail.google.com/mail/u/0/#inbox` | Initial page to open |
| `WAIT_SECS` | `5` | Seconds to wait for DevTools to come up |
| `KILL_WAIT_SECS` | `3` | Seconds to wait after killing existing Chrome |
| `DEBUG_LOG` | `/tmp/chrome4openclaw-debug.log` | Chrome stdout/stderr log |
| `DEVTOOLS_INFO` | `/tmp/chrome4openclaw-devtools.json` | Saved DevTools version JSON |

### Requirements

- Debian / Ubuntu
- Google Chrome installed at `/opt/google/chrome/chrome` (or set `CHROME_BIN`)
- An active X display (XRDP, local desktop, or set `DISPLAY` explicitly)
- `curl` and `xdpyinfo` available
- `agent-browser` CLI installed via npm: `npm install -g agent-browser`

> **WARNING:** Do NOT install `agent-browser` by cloning or building from
> [https://github.com/vercel-labs/agent-browser](https://github.com/vercel-labs/agent-browser).
> This is known to **break XRDP on Debian/Ubuntu**.
> Always install via npm: `npm install -g agent-browser`

---

## Why Browser Control (Instead of Skills / APIs)

This tool is **not a “Skill”** in the traditional OpenClaw / Claude Cowork fashion. 
Instead, it enables OpenClaw (or similar agent systems) to interact with a REAL BROWSER through the **Chrome DevTools Protocol (CDP)** — effectively allowing the agent to operate at the same layer as a human user.

---

## Key Idea

Rather than calling platform APIs (e.g., Gmail API, GitHub API, etc.), the agent:

- Observes and interacts with live browser sessions  
- Leverages existing authenticated user context  
- Operates through frontend AJAX / network flows  

---

## Advantages

### 1. Extremely Low Token Usage

- No need to translate intent into API calls and bear with costly pricing
- No need to construct structured payloads  
- Minimal reasoning overhead once patterns are learned  

This makes it significantly more efficient than API-driven automation.

---

### 2. Universal Interface

Anything a human can do in a browser becomes accessible:

- Gmail (read/send/search emails)  
- GitHub (issues, PRs, repo navigation)  
- Amazon / e-commerce  
- Calendar systems  
- Internal dashboards
- Best of all, you literally see what your agent is doing

No need for:

- Platform-specific SDKs  
- API integrations  
- Custom “skills” per service  

---

### 3. Reduced Integration Overhead

**Traditional approach:**

    Agent → Skill → API → Platform

**This approach:**

    Agent → Browser (CDP) → Platform

**Result:**

- Fewer moving parts  
- Less maintenance  
- Faster iteration  

---

### 4. Act like a human

Because actions occur within a real browser session:

- Existing login/session state is reused  
- UI flows are preserved  
- No need to reverse-engineer APIs  

---

## Trade-offs

This approach is very powerful, but not free:

- Fragile to UI changes  
- Harder to debug than API, you need to see the same screen and figure out what is wrong then tell your agent
- Lacks formal contracts (unlike APIs)  
- Depends on browser stability and session state
- Your agent might act too fast, ask it slow down a little bit. Such as pause 3 seconds for each text field 

---

## Design Position

This project intentionally treats the browser as:

> A universal execution surface, not a UI.

---

## Practical Implication

With a stable browser control layer:

- Many existing OpenClaw skills become redundant  
- Integration cost drops dramatically  
- Agent capability expands without additional connectors  

---

## A blunt observation

If you can control the browser reliably,  
You already control most of the internet.

---

## Third-Party Components

The reference documentation in `skill/references/` is copied from
[vercel-labs/agent-browser](https://github.com/vercel-labs/agent-browser) by Vercel Labs,
licensed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).
No modifications have been made to those files.
