#!/bin/bash
# OpenClaw Clone Setup Script
# Run on a fresh Mac mini to set up a new OpenClaw instance
#
# Usage: ./setup.sh
# (Prompts interactively for all required values)
#
# Prerequisites:
# - macOS with Homebrew installed (brew install node)
# - Node.js 20+ installed

set -e

WORKSPACE="$HOME/.openclaw/workspace"
CLONE_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== OpenClaw Clone Setup ==="
echo ""
echo "You'll need the following API keys and tokens."
echo "Press Enter to skip optional items."
echo ""

# --- Prompt for API keys ---

prompt_required() {
    local var_name="$1"
    local prompt_text="$2"
    local value=""
    while [ -z "$value" ]; do
        read -rp "$prompt_text: " value
        if [ -z "$value" ]; then
            echo "    ⚠️  This field is required."
        fi
    done
    eval "$var_name=\"$value\""
}

prompt_optional() {
    local var_name="$1"
    local prompt_text="$2"
    local default_val="${3:-}"
    read -rp "$prompt_text [optional]: " value
    eval "$var_name=\"${value:-$default_val}\""
}

echo "--- Required ---"
prompt_required ANTHROPIC_KEY    "Anthropic API key       (console.anthropic.com)"
prompt_required OPENROUTER_KEY   "OpenRouter API key      (openrouter.ai/keys)"
prompt_required OPENAI_KEY       "OpenAI API key          (platform.openai.com — for memory search)"
prompt_required TELEGRAM_TOKEN   "Telegram bot token      (@BotFather → /newbot)"

echo ""
echo "--- Optional ---"
prompt_optional DISCORD_TOKEN    "Discord bot token       (discord.com/developers)"
prompt_optional GEMINI_KEY       "Gemini API key          (aistudio.google.com)"
prompt_optional BRAVE_KEY        "Brave Search API key    (search API dashboard)"

echo ""
echo "=== Starting installation... ==="
echo ""

# 1. Install OpenClaw
echo "1/9 Installing OpenClaw..."
if ! command -v openclaw &> /dev/null; then
    npm install -g openclaw
    echo "    ✅ OpenClaw installed"
else
    echo "    ✅ OpenClaw already installed ($(openclaw --version 2>/dev/null || echo 'unknown version'))"
fi

# 2. Create workspace
echo "2/9 Setting up workspace..."
mkdir -p "$WORKSPACE/memory"
mkdir -p "$WORKSPACE/scripts"
mkdir -p "$HOME/.openclaw/logs"
echo "    ✅ Directories created"

# 3. Copy template files
echo "3/9 Copying workspace template..."
cp "$CLONE_DIR/template/AGENTS.md"   "$WORKSPACE/"
cp "$CLONE_DIR/template/SOUL.md"     "$WORKSPACE/"
cp "$CLONE_DIR/template/USER.md"     "$WORKSPACE/"
cp "$CLONE_DIR/template/TOOLS.md"    "$WORKSPACE/"
cp "$CLONE_DIR/template/HEARTBEAT.md" "$WORKSPACE/"
cp "$CLONE_DIR/template/MEMORY.md"   "$WORKSPACE/"
cp "$CLONE_DIR/template/memory/facts.md"       "$WORKSPACE/memory/"
cp "$CLONE_DIR/template/memory/constraints.md" "$WORKSPACE/memory/"

# Copy IDENTITY.md only if it exists in template
[ -f "$CLONE_DIR/template/IDENTITY.md" ] && cp "$CLONE_DIR/template/IDENTITY.md" "$WORKSPACE/"

# Copy optional memory files
[ -f "$CLONE_DIR/template/memory/episodes.md" ] && cp "$CLONE_DIR/template/memory/episodes.md" "$WORKSPACE/memory/"
[ -f "$CLONE_DIR/template/memory/claude-code-exec-pattern.md" ] && cp "$CLONE_DIR/template/memory/claude-code-exec-pattern.md" "$WORKSPACE/memory/"

echo "    ✅ Workspace files copied"

# 4. Copy scripts
echo "4/9 Installing scripts..."
cp "$CLONE_DIR/scripts/"*.sh "$WORKSPACE/scripts/" 2>/dev/null || echo "    (no scripts to copy)"
chmod +x "$WORKSPACE/scripts/"*.sh 2>/dev/null || true
echo "    ✅ Scripts installed"

# 5. Generate config from template
echo "5/9 Generating config..."
GATEWAY_TOKEN=$(openssl rand -hex 32)
GATEWAY_PASSWORD=$(openssl rand -hex 16)

TEMPLATE_FILE="$CLONE_DIR/template/openclaw-template.json"
if [ ! -f "$TEMPLATE_FILE" ]; then
    # Fallback to legacy template location
    TEMPLATE_FILE="$CLONE_DIR/config-template.json"
fi

sed -e "s|__ANTHROPIC_API_KEY__|$ANTHROPIC_KEY|g" \
    -e "s|__OPENROUTER_API_KEY__|$OPENROUTER_KEY|g" \
    -e "s|__OPENAI_API_KEY__|$OPENAI_KEY|g" \
    -e "s|__TELEGRAM_BOT_TOKEN__|$TELEGRAM_TOKEN|g" \
    -e "s|__DISCORD_BOT_TOKEN__|${DISCORD_TOKEN:-__DISCORD_BOT_TOKEN__}|g" \
    -e "s|__GATEWAY_TOKEN__|$GATEWAY_TOKEN|g" \
    -e "s|__GATEWAY_PASSWORD__|$GATEWAY_PASSWORD|g" \
    -e "s|__BRAVE_SEARCH_API_KEY__|${BRAVE_KEY:-}|g" \
    -e "s|__GEMINI_API_KEY__|${GEMINI_KEY:-}|g" \
    -e "s|~/.openclaw/workspace|$WORKSPACE|g" \
    "$TEMPLATE_FILE" > "$HOME/.openclaw/openclaw.json"

# Remove _comments section from final config (not valid JSON in some parsers)
# (keep it — it's valid JSON and helpful for reference)

echo "    ✅ Config generated → $HOME/.openclaw/openclaw.json"

# 6. Add Anthropic key to .zshrc
echo "6/9 Configuring shell environment..."
if ! grep -q "ANTHROPIC_API_KEY" "$HOME/.zshrc" 2>/dev/null; then
    echo "" >> "$HOME/.zshrc"
    echo "# OpenClaw — Anthropic direct API key" >> "$HOME/.zshrc"
    echo "export ANTHROPIC_API_KEY=\"$ANTHROPIC_KEY\"" >> "$HOME/.zshrc"
    echo "    ✅ ANTHROPIC_API_KEY added to ~/.zshrc"
else
    echo "    ✅ ANTHROPIC_API_KEY already in ~/.zshrc (not modified)"
fi

# 7. Install LaunchAgent (proper macOS service — survives reboots + terminal death)
echo "7/9 Installing LaunchAgent..."
NODE_PATH=$(which node)
# Find OpenClaw JS entry point (macOS-compatible)
OPENCLAW_JS=$(npm root -g)/openclaw/dist/index.js
if [ ! -f "$OPENCLAW_JS" ]; then
    # Fallback: try resolving from symlink
    OPENCLAW_PATH=$(which openclaw)
    OPENCLAW_DIR=$(dirname "$OPENCLAW_PATH")
    OPENCLAW_JS="$OPENCLAW_DIR/../lib/node_modules/openclaw/dist/index.js"
fi

mkdir -p "$HOME/Library/LaunchAgents"
cat > "$HOME/Library/LaunchAgents/ai.openclaw.gateway.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>ai.openclaw.gateway</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>ProgramArguments</key>
    <array>
      <string>$NODE_PATH</string>
      <string>$OPENCLAW_JS</string>
      <string>gateway</string>
      <string>--port</string>
      <string>18789</string>
    </array>
    <key>StandardOutPath</key>
    <string>$HOME/.openclaw/logs/gateway.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/.openclaw/logs/gateway.err.log</string>
    <key>EnvironmentVariables</key>
    <dict>
      <key>HOME</key>
      <string>$HOME</string>
      <key>PATH</key>
      <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
      <key>ANTHROPIC_API_KEY</key>
      <string>$ANTHROPIC_KEY</string>
      <key>OPENROUTER_API_KEY</key>
      <string>$OPENROUTER_KEY</string>
      <key>OPENCLAW_GATEWAY_PORT</key>
      <string>18789</string>
      <key>OPENCLAW_GATEWAY_TOKEN</key>
      <string>$GATEWAY_TOKEN</string>
      <key>OPENCLAW_LAUNCHD_LABEL</key>
      <string>ai.openclaw.gateway</string>
      <key>OPENCLAW_SERVICE_MARKER</key>
      <string>openclaw</string>
      <key>OPENCLAW_SERVICE_KIND</key>
      <string>gateway</string>
      <key>NODE_OPTIONS</key>
      <string>--max-old-space-size=2048</string>
    </dict>
  </dict>
</plist>
PLIST

launchctl load "$HOME/Library/LaunchAgents/ai.openclaw.gateway.plist" 2>/dev/null || true
echo "    ✅ LaunchAgent installed (auto-starts on login + survives terminal death)"

# 8. Install iCloud backup cron
echo "8/9 Setting up daily backup..."
if [ -f "$WORKSPACE/scripts/daily-backup.sh" ]; then
    (crontab -l 2>/dev/null | grep -v "daily-backup.sh"; echo "0 2 * * * $WORKSPACE/scripts/daily-backup.sh >> /tmp/openclaw-backup.log 2>&1") | crontab -
    echo "    ✅ Daily backup cron (2:00 AM, backs up to iCloud)"
else
    echo "    ⚠️  daily-backup.sh not found — skipping backup cron"
fi

# 9. Configure screenshots → workspace (so agent can see them)
echo "9/10 Configuring screenshot destination..."
defaults write com.apple.screencapture location "$WORKSPACE/screenshots" 2>/dev/null && \
    mkdir -p "$WORKSPACE/screenshots" && \
    echo "    ✅ Screenshots will save to workspace/screenshots/" || \
    echo "    ⚠️  Could not set screenshot location (non-fatal)"

# 10. Done
echo "10/10 Setup complete!"
echo ""
echo "=== Credentials (SAVE THESE — won't be shown again) ==="
echo "Gateway token:    $GATEWAY_TOKEN"
echo "Gateway password: $GATEWAY_PASSWORD"
echo "Dashboard:        http://localhost:18789/"
echo ""
echo "=== Post-Setup Steps ==="
echo "1. Run ./post-setup.sh — sets up cron jobs and extensions"
echo "2. Edit $WORKSPACE/IDENTITY.md — give your agent a name"
echo "3. Edit $WORKSPACE/USER.md — tell it about yourself"
echo "4. Edit $WORKSPACE/SOUL.md — customize the personality"
echo "5. Open Telegram → message your bot → pair it"
echo ""
echo "=== Optional: Install claude-mem plugin ==="
echo "   openclaw plugin install claude-mem"
echo "   (Adds persistent vector memory — recommended for long-running agents)"
echo ""
echo "=== Optional: Deploy Mission Control app ==="
echo "   cd $WORKSPACE/[agent]/projects/mission-control"
echo "   npm install && npm run dev"
echo "   (Personal dashboard: tasks, memory, calendar, content pipeline)"
echo ""
echo "Important: Don't skip step 1! post-setup.sh configures automated jobs."
echo ""
echo "Happy clawing! 🦞"
