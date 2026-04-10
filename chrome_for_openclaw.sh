#!/usr/bin/env bash
# chrome_for_openclaw.sh
#
# Usage:
#   bash chrome_for_openclaw.sh              # Launch Chrome in CDP debug mode (default)
#   bash chrome_for_openclaw.sh --install    # One-time system setup (Chrome + XRDP + XFCE)
#   bash chrome_for_openclaw.sh --reinstall  # Uninstall everything, then run --install
#   bash chrome_for_openclaw.sh --uninstall  # Undo all changes made by --install
#
# Environment variable overrides (for default launch mode):
#   CHROME_BIN, DEBUG_PORT, USER_DATA_DIR, START_URL,
#   WAIT_SECS, KILL_WAIT_SECS, DEBUG_LOG, DEVTOOLS_INFO
set -euo pipefail

CHROME_BIN="${CHROME_BIN:-/opt/google/chrome/chrome}"
DEBUG_PORT="${DEBUG_PORT:-9222}"
USER_DATA_DIR="${USER_DATA_DIR:-/tmp/chrome4openclaw}"
START_URL="${START_URL:-https://mail.google.com/mail/u/0/#inbox}"
WAIT_SECS="${WAIT_SECS:-5}"
KILL_WAIT_SECS="${KILL_WAIT_SECS:-3}"
DEBUG_LOG="${DEBUG_LOG:-/tmp/chrome4openclaw-debug.log}"
DEVTOOLS_INFO="${DEVTOOLS_INFO:-/tmp/chrome4openclaw-devtools.json}"

# ─── System setup helpers ─────────────────────────────────────────────────────

chrome_is_installed() {
  [ -x "$CHROME_BIN" ]
}

do_install_chrome() {
  echo "==> Installing Google Chrome"
  sudo install -m 0755 -d /etc/apt/keyrings

  echo "    Adding Google signing key"
  curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
    | sudo gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg
  sudo chmod 644 /etc/apt/keyrings/google-chrome.gpg

  echo "    Adding apt repository"
  echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
    | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null

  sudo apt update
  sudo apt install -y google-chrome-stable

  if chrome_is_installed; then
    echo "    Chrome installed: $(google-chrome --version)"
  else
    echo "ERROR: Chrome installation failed — $CHROME_BIN not found" >&2
    exit 1
  fi
}

do_uninstall_chrome() {
  echo "==> Removing Google Chrome"
  sudo apt remove -y google-chrome-stable 2>/dev/null || true
  sudo rm -f /etc/apt/sources.list.d/google-chrome.list
  sudo rm -f /etc/apt/keyrings/google-chrome.gpg
  sudo apt update
}

confirm_setup() {
  echo ""
  echo "┌─────────────────────────────────────────────────────────────────┐"
  echo "│           chrome_for_openclaw — System Setup                    │"
  echo "├─────────────────────────────────────────────────────────────────┤"
  echo "│  The following changes will be made to this system:             │"
  echo "│                                                                 │"
  echo "│  • /etc/lightdm/lightdm.conf.d/50-xfce.conf                    │"
  echo "│      Set default desktop session to XFCE                       │"
  echo "│                                                                 │"
  echo "│  • /etc/X11/Xwrapper.config                                     │"
  echo "│      Allow XRDP to start X sessions (allowed_users=anybody)    │"
  echo "│                                                                 │"
  echo "│  • ~/.config/xfce4/helpers.rc                                   │"
  echo "│      Set xfce4-terminal as default terminal emulator           │"
  echo "│                                                                 │"
  echo "│  • ~/.xsession                                                  │"
  echo "│      Launch XFCE on RDP login via dbus-launch                  │"
  echo "│                                                                 │"
  echo "│  • ~/.cache/sessions/*, ~/.Xauthority, ~/.xsession-errors       │"
  echo "│      Cleared (stale session files removed)                     │"
  echo "│                                                                 │"
  echo "│  • sudo adduser xrdp ssl-cert                                   │"
  echo "│      Grant xrdp access to SSL certificates                     │"
  echo "│                                                                 │"
  echo "│  After setup you will need to log out and reconnect via RDP.   │"
  echo "├─────────────────────────────────────────────────────────────────┤"
  echo "│  Proceed?  Type OK to continue, or anything else to cancel.    │"
  echo "└─────────────────────────────────────────────────────────────────┘"
  echo ""
  read -r -p "  Your choice [OK/Cancel]: " answer
  case "$answer" in
    OK|ok|Ok)
      echo ""
      ;;
    *)
      echo "Cancelled. No changes were made."
      exit 0
      ;;
  esac
}

do_setup_xrdp_xfce() {
  confirm_setup
  echo "==> Configuring LightDM to use XFCE session"
  sudo mkdir -p /etc/lightdm/lightdm.conf.d
  sudo bash -c 'cat > /etc/lightdm/lightdm.conf.d/50-xfce.conf <<EOF
[Seat:*]
user-session=xfce
EOF'

  echo "==> Configuring X11 Xwrapper for XRDP access"
  echo -e "allowed_users=anybody\nneeds_root_rights=yes" | sudo tee /etc/X11/Xwrapper.config

  echo "==> Setting up XFCE4 helpers"
  mkdir -p ~/.config/xfce4
  cat > ~/.config/xfce4/helpers.rc <<EOF
TerminalEmulator=xfce4-terminal
EOF

  echo "==> Writing ~/.xsession"
  echo "dbus-launch --exit-with-session startxfce4" > ~/.xsession
  chmod 644 ~/.xsession

  echo "==> Clearing stale session cache and auth files"
  rm -rf ~/.cache/sessions/*
  rm -f ~/.Xauthority ~/.xsession-errors ~/.xsession-errors.old

  echo "==> Adding xrdp to ssl-cert group"
  sudo adduser xrdp ssl-cert
}

do_uninstall_xrdp_xfce() {
  echo "==> Removing XRDP/XFCE configuration"
  sudo rm -f /etc/lightdm/lightdm.conf.d/50-xfce.conf
  sudo rm -f /etc/X11/Xwrapper.config
  rm -f ~/.config/xfce4/helpers.rc
  rm -f ~/.xsession
}

# ─── Chrome launch helpers ────────────────────────────────────────────────────

pick_display() {
  local candidates=()
  local d

  if [ -n "${DISPLAY:-}" ]; then
    candidates+=("$DISPLAY")
  fi

  if [ -S /tmp/.X11-unix/X10 ]; then
    candidates+=(":10.0" ":10")
  fi

  if [ -S /tmp/.X11-unix/X0 ]; then
    candidates+=(":0.0" ":0")
  fi

  while IFS= read -r d; do
    candidates+=(":${d}.0" ":${d}")
  done < <(find /tmp/.X11-unix -maxdepth 1 -type s -name 'X*' 2>/dev/null | sed 's#.*/X##' | sort -u)

  local seen="|"
  for d in "${candidates[@]}"; do
    [ -n "$d" ] || continue
    case "$seen" in
      *"|$d|"*) continue ;;
    esac
    seen="${seen}${d}|"
    if DISPLAY="$d" xdpyinfo >/dev/null 2>&1; then
      echo "$d"
      return 0
    fi
  done

  return 1
}

do_launch_chrome() {
  if ! chrome_is_installed; then
    echo "ERROR: Chrome binary not found or not executable: $CHROME_BIN" >&2
    echo "Hint: run '$0 --install' to install Chrome and configure XRDP." >&2
    exit 1
  fi

  local selected_display="${DISPLAY:-}"
  if ! DISPLAY="$selected_display" xdpyinfo >/dev/null 2>&1; then
    if ! selected_display="$(pick_display)"; then
      echo "ERROR: Could not find a usable X display." >&2
      echo "Hint: run this from an XRDP/local desktop session, or set DISPLAY explicitly, e.g." >&2
      echo "  DISPLAY=:10.0 $0" >&2
      exit 3
    fi
  fi

  echo "==> Restarting Chrome debug session"
  echo "    CHROME_BIN=$CHROME_BIN"
  echo "    DEBUG_PORT=$DEBUG_PORT"
  echo "    USER_DATA_DIR=$USER_DATA_DIR"
  echo "    START_URL=$START_URL"
  echo "    DISPLAY=$selected_display"

  echo "==> Stopping existing Chrome processes"
  local patterns=(
    '^/opt/google/chrome/chrome($| )'
    '^/opt/google/chrome/chrome_crashpad_handler($| )'
  )
  for pattern in "${patterns[@]}"; do
    pkill -f "$pattern" 2>/dev/null || true
  done
  sleep "$KILL_WAIT_SECS"

  local leftover=0
  for pattern in "${patterns[@]}"; do
    if pgrep -f "$pattern" >/dev/null 2>&1; then
      leftover=1
      break
    fi
  done
  if [ "$leftover" -eq 1 ]; then
    echo "==> Some Chrome processes still alive; sending SIGKILL"
    for pattern in "${patterns[@]}"; do
      pkill -9 -f "$pattern" 2>/dev/null || true
    done
    sleep 1
  fi

  mkdir -p "$USER_DATA_DIR"

  echo "==> Starting Chrome in debug mode"
  DISPLAY="$selected_display" nohup "$CHROME_BIN" \
    --remote-debugging-port="$DEBUG_PORT" \
    --user-data-dir="$USER_DATA_DIR" \
    --no-first-run \
    --no-default-browser-check \
    "$START_URL" \
    >"$DEBUG_LOG" 2>&1 &

  local chrome_pid=$!
  echo "==> Chrome launched with PID $chrome_pid"

  echo "==> Waiting ${WAIT_SECS}s for DevTools endpoint"
  sleep "$WAIT_SECS"

  if command -v curl >/dev/null 2>&1; then
    if curl -fsS "http://127.0.0.1:${DEBUG_PORT}/json/version" >"$DEVTOOLS_INFO" 2>/dev/null; then
      echo "==> DevTools is up"
      echo "    Endpoint: http://127.0.0.1:${DEBUG_PORT}/json/version"
      echo "    Browser URL: http://127.0.0.1:${DEBUG_PORT}"
      echo "    Saved version info: $DEVTOOLS_INFO"
    else
      echo "WARNING: DevTools endpoint did not answer yet on port ${DEBUG_PORT}" >&2
      echo "         Check: $DEBUG_LOG" >&2
      exit 2
    fi
  else
    echo "WARNING: curl not found; skipped endpoint verification"
  fi

  echo "==> Done"
}

# ─── Main ─────────────────────────────────────────────────────────────────────

MODE="${1:-launch}"

case "$MODE" in
  --install)
    echo "==> chrome_for_openclaw: one-time system setup"
    if chrome_is_installed; then
      echo "==> Google Chrome already installed: $(google-chrome --version)"
    else
      do_install_chrome
    fi
    do_setup_xrdp_xfce
    echo ""
    echo "==> Setup complete."
    echo "    Please log out and reconnect via RDP, then run this script again to start Chrome."
    ;;

  --uninstall)
    echo "==> chrome_for_openclaw: uninstalling"
    do_uninstall_chrome
    do_uninstall_xrdp_xfce
    echo "==> Uninstall complete."
    ;;

  --reinstall)
    echo "==> chrome_for_openclaw: reinstalling"
    do_uninstall_chrome
    do_uninstall_xrdp_xfce
    do_install_chrome
    do_setup_xrdp_xfce
    echo ""
    echo "==> Reinstall complete."
    echo "    Please log out and reconnect via RDP, then run this script again to start Chrome."
    ;;

  launch|*)
    do_launch_chrome
    ;;
esac
