#!/bin/bash
# bootstrap.sh — Full Mac setup for OpenClaw (idempotent, safe to re-run)
set -euo pipefail

echo "🚀 OpenClaw Mac Bootstrap"
echo "========================="

# --- Xcode CLI Tools ---
if ! xcode-select -p &>/dev/null; then
  echo "📦 Installing Xcode CLI tools..."
  xcode-select --install
  echo "⏳ Waiting for Xcode CLI tools (press Enter when done)..."
  read -r
else
  echo "✅ Xcode CLI tools already installed"
fi

# --- Homebrew ---
if ! command -v brew &>/dev/null; then
  echo "🍺 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "✅ Homebrew already installed"
fi

# --- Node.js 22 ---
if ! command -v node &>/dev/null || [[ "$(node -v)" != v22* ]]; then
  echo "📦 Installing Node.js 22..."
  brew install node@22
  brew link --overwrite node@22 2>/dev/null || true
else
  echo "✅ Node.js $(node -v) already installed"
fi

# --- pnpm ---
if ! command -v pnpm &>/dev/null; then
  echo "📦 Installing pnpm..."
  npm install -g pnpm
else
  echo "✅ pnpm already installed"
fi

# --- OpenClaw ---
if ! command -v openclaw &>/dev/null; then
  echo "📦 Installing OpenClaw..."
  npm install -g openclaw
else
  echo "✅ OpenClaw already installed ($(openclaw --version 2>/dev/null || echo 'unknown'))"
  echo "   Run 'npm update -g openclaw' to update"
fi

# --- Energy Settings (always-on) ---
echo "⚡ Setting energy preferences (always-on, no sleep)..."
sudo pmset -c displaysleep 15      # Display sleeps after 15 min on power
sudo pmset -c sleep 0              # Never system sleep on power
sudo pmset -c disksleep 0          # Never disk sleep
sudo pmset -c womp 1               # Wake on LAN
sudo pmset -c autorestart 1        # Auto restart after power failure
echo "✅ Energy settings configured"

# --- Workspace directory ---
WORKSPACE="$HOME/.openclaw/workspace"
mkdir -p "$WORKSPACE/memory" "$WORKSPACE/scripts" "$WORKSPACE/skills"
echo "✅ Workspace directory ready: $WORKSPACE"

# --- Elon-Inbox symlink ---
INBOX_LINK="$HOME/Desktop/Elon-Inbox"
INBOX_TARGET="$HOME/.openclaw/media/inbound"
mkdir -p "$INBOX_TARGET"
if [ ! -L "$INBOX_LINK" ]; then
  ln -s "$INBOX_TARGET" "$INBOX_LINK"
  echo "✅ Created Elon-Inbox symlink on Desktop"
else
  echo "✅ Elon-Inbox symlink already exists"
fi

# --- Companion App ---
echo ""
echo "📱 Downloading OpenClaw Companion App..."
DMG_URL="https://download.openclaw.com/OpenClaw.dmg"
DMG_PATH="/tmp/OpenClaw.dmg"
if [ ! -d "/Applications/OpenClaw.app" ]; then
  curl -fSL -o "$DMG_PATH" "$DMG_URL" 2>/dev/null && {
    echo "   DMG downloaded to $DMG_PATH"
    echo "   Mount it and drag to Applications."
  } || {
    echo "⚠️  Could not download DMG. Get it manually from https://openclaw.com/download"
  }
else
  echo "✅ OpenClaw Companion App already installed"
fi

# --- File permissions ---
chmod 700 "$HOME/.openclaw"
[ -f "$HOME/.openclaw/openclaw.json" ] && chmod 600 "$HOME/.openclaw/openclaw.json"
echo "✅ File permissions locked"

echo ""
echo "========================================="
echo "✅ Bootstrap complete!"
echo "========================================="
echo ""
echo "📋 Manual steps remaining:"
echo ""
echo "  1. AMPHETAMINE — Install from Mac App Store"
echo "     Keep-awake app to prevent sleep. Configure:"
echo "     - Start at login"
echo "     - Default session: Infinite"
echo ""
echo "  2. FIREWALL — System Settings > Network > Firewall"
echo "     - Enable firewall"
echo "     - Enable stealth mode"
echo ""
echo "  3. TAILSCALE — https://tailscale.com/download/mac"
echo "     - Install and sign in"
echo "     - Enable MagicDNS for remote access"
echo ""
echo "  4. COMPANION APP PERMISSIONS"
echo "     Grant in System Settings > Privacy & Security:"
echo "     - Notifications"
echo "     - Accessibility"
echo "     - Microphone"
echo "     - Screen Recording (if needed)"
echo ""
echo "Next step: Run scripts/setup-secrets.sh to configure API keys"
