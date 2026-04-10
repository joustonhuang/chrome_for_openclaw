#!/usr/bin/env bash
# One-time system setup: Google Chrome + XRDP + XFCE for OpenClaw browser control
#
# Usage:
#   bash setup_xrdp_xfce.sh             # Install / configure everything
#   bash setup_xrdp_xfce.sh --uninstall # Undo all changes made by this script
#   bash setup_xrdp_xfce.sh --reinstall # Uninstall then reinstall from scratch
#
# Run once as a user with sudo privileges.
# After setup completes, log out and reconnect via RDP.
set -euo pipefail

CHROME_BIN="${CHROME_BIN:-/opt/google/chrome/chrome}"

# ─── Helpers ──────────────────────────────────────────────────────────────────

chrome_is_installed() {
  [ -x "$CHROME_BIN" ]
}

install_chrome() {
  echo "==> Google Chrome not found — installing"
  sudo install -m 0755 -d /etc/apt/keyrings

  echo "    Adding Google signing key"
  curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
    | sudo gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg
  sudo chmod 644 /etc/apt/keyrings/google-chrome.gpg

  echo "    Adding Google Chrome apt repository"
  echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
    | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null

  echo "    Running apt update + install"
  sudo apt update
  sudo apt install -y google-chrome-stable

  if chrome_is_installed; then
    echo "    Chrome installed: $(google-chrome --version)"
  else
    echo "ERROR: Chrome installation failed — $CHROME_BIN not found" >&2
    exit 1
  fi
}

uninstall_chrome() {
  echo "==> Removing Google Chrome"
  sudo apt remove -y google-chrome-stable 2>/dev/null || true
  sudo rm -f /etc/apt/sources.list.d/google-chrome.list
  sudo rm -f /etc/apt/keyrings/google-chrome.gpg
  sudo apt update
}

setup_xrdp_xfce() {
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

  echo "==> Adding xrdp user to ssl-cert group"
  sudo adduser xrdp ssl-cert
}

uninstall_xrdp_xfce() {
  echo "==> Removing XRDP/XFCE configuration"
  sudo rm -f /etc/lightdm/lightdm.conf.d/50-xfce.conf
  sudo rm -f /etc/X11/Xwrapper.config
  rm -f ~/.config/xfce4/helpers.rc
  rm -f ~/.xsession
}

# ─── Main ─────────────────────────────────────────────────────────────────────

MODE="${1:-install}"

case "$MODE" in
  --uninstall)
    echo "==> Uninstalling chrome_for_openclaw setup"
    uninstall_chrome
    uninstall_xrdp_xfce
    echo "==> Uninstall complete."
    ;;

  --reinstall)
    echo "==> Reinstalling chrome_for_openclaw setup"
    uninstall_chrome
    uninstall_xrdp_xfce
    install_chrome
    setup_xrdp_xfce
    echo ""
    echo "==> Reinstall complete. Please log out and reconnect via RDP."
    echo "    Then run chrome_for_openclaw.sh to start Chrome."
    ;;

  install|*)
    echo "==> chrome_for_openclaw system setup"

    if chrome_is_installed; then
      echo "==> Google Chrome already installed: $(google-chrome --version)"
    else
      install_chrome
    fi

    setup_xrdp_xfce

    echo ""
    echo "==> Setup complete. Please log out and reconnect via RDP."
    echo "    Then run chrome_for_openclaw.sh to start Chrome."
    ;;
esac
