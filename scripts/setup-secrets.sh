#!/bin/bash
# setup-secrets.sh — Interactive secret configuration for OpenClaw
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE="$SCRIPT_DIR/openclaw-template.json"
CONFIG="$HOME/.openclaw/openclaw.json"
WORKSPACE="$HOME/.openclaw/workspace"

echo "🔐 OpenClaw Secrets Setup"
echo "========================="
echo ""

if [ ! -f "$TEMPLATE" ]; then
  echo "❌ Template not found: $TEMPLATE"
  exit 1
fi

if [ -f "$CONFIG" ]; then
  echo "⚠️  Config already exists at $CONFIG"
  read -rp "   Overwrite? (y/N): " confirm
  [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
  cp "$CONFIG" "${CONFIG}.bak.$(date +%s)"
  echo "   Backup saved."
fi

# --- Prompt for secrets ---
echo ""
read -rp "Anthropic API key: " ANTHROPIC_KEY
read -rp "Brave Search API key: " BRAVE_KEY
read -rp "Telegram bot token: " TELEGRAM_TOKEN
read -rp "Discord bot token: " DISCORD_TOKEN
read -rp "OpenAI API key (for image gen, or press Enter to skip): " OPENAI_KEY

# --- Generate config ---
echo ""
echo "📝 Generating openclaw.json..."

mkdir -p "$HOME/.openclaw"

sed \
  -e "s|__WORKSPACE_PATH__|$WORKSPACE|g" \
  -e "s|__BRAVE_SEARCH_API_KEY__|$BRAVE_KEY|g" \
  -e "s|__TELEGRAM_BOT_TOKEN__|$TELEGRAM_TOKEN|g" \
  -e "s|__DISCORD_BOT_TOKEN__|$DISCORD_TOKEN|g" \
  -e "s|__OPENAI_API_KEY__|${OPENAI_KEY:-__OPENAI_API_KEY__}|g" \
  "$TEMPLATE" > "$CONFIG"

chmod 600 "$CONFIG"
echo "✅ Config written to $CONFIG"

# --- Set Anthropic key via environment ---
echo ""
echo "📝 Setting Anthropic API key..."
CRED_DIR="$HOME/.openclaw/credentials"
mkdir -p "$CRED_DIR"
chmod 700 "$CRED_DIR"

# Write the key for openclaw to pick up
export ANTHROPIC_API_KEY="$ANTHROPIC_KEY"

# Add to shell profile if not already there
SHELL_RC="$HOME/.zshrc"
if ! grep -q "ANTHROPIC_API_KEY" "$SHELL_RC" 2>/dev/null; then
  echo "" >> "$SHELL_RC"
  echo "# OpenClaw - Anthropic API Key" >> "$SHELL_RC"
  echo "export ANTHROPIC_API_KEY=\"$ANTHROPIC_KEY\"" >> "$SHELL_RC"
  echo "✅ Added ANTHROPIC_API_KEY to $SHELL_RC"
else
  echo "⚠️  ANTHROPIC_API_KEY already in $SHELL_RC — update manually if needed"
fi

# --- Install gateway LaunchAgent ---
echo ""
echo "🚀 Installing gateway service..."
if command -v openclaw &>/dev/null; then
  openclaw gateway install && echo "✅ Gateway LaunchAgent installed" || echo "⚠️  Gateway install failed — run 'openclaw gateway install' manually"
else
  echo "⚠️  openclaw not found. Install it first, then run: openclaw gateway install"
fi

echo ""
echo "========================================="
echo "✅ Secrets setup complete!"
echo "========================================="
echo ""
echo "Next steps:"
echo "  1. Source your shell:  source ~/.zshrc"
echo "  2. Start gateway:     openclaw gateway start"
echo "  3. Verify:            openclaw gateway status"
echo "  4. Test Telegram:     Send a message to your bot"
