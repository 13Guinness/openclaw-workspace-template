#!/bin/bash
# Post-Setup Configuration Script
# Run this AFTER setup.sh to configure cron jobs and install extensions
#
# Usage: ./post-setup.sh

set -e

echo "=== OpenClaw Post-Setup Configuration ==="
echo ""

# Check if gateway is running
if ! pgrep -f "openclaw" > /dev/null 2>&1; then
    echo "❌ OpenClaw gateway not running."
    echo "   Start it first: openclaw gateway start"
    exit 1
fi

echo "✅ Gateway is running"
echo ""

# Get the gateway token from config
GATEWAY_TOKEN=$(grep -o '"token": "[^"]*"' ~/.openclaw/openclaw.json | head -1 | cut -d'"' -f4)
if [ -z "$GATEWAY_TOKEN" ]; then
    echo "⚠️  Could not find gateway token in config"
    echo "   You may need to create cron jobs manually"
    exit 1
fi

echo "Setting up automated jobs..."
echo ""

# Function to create cron job
create_cron_job() {
    local name="$1"
    local schedule="$2"
    local message="$3"
    local model="${4:-openrouter/google/gemini-2.0-flash-001}"
    local delivery="${5:-announce}"
    
    curl -s -X POST http://localhost:18789/cron \
        -H "Authorization: Bearer $GATEWAY_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"name\": \"$name\",
            \"enabled\": true,
            \"schedule\": $schedule,
            \"sessionTarget\": \"isolated\",
            \"payload\": {
                \"kind\": \"agentTurn\",
                \"message\": \"$message\",
                \"model\": \"$model\",
                \"timeoutSeconds\": 120
            },
            \"delivery\": {
                \"mode\": \"$delivery\"
            }
        }" > /dev/null 2>&1 && echo "  ✅ $name" || echo "  ❌ $name (failed)"
}

# 1. Daily Self-Review
create_cron_job "Daily Self-Review" \
    '{"kind": "cron", "expr": "0 9 * * *", "tz": "America/New_York"}' \
    "Daily self-review: Read MEMORY.md, SOUL.md, IDENTITY.md, AGENTS.md, and the memory/ folder. Look for outdated information, conflicting rules, undocumented workflows, lessons from recent failures. Summarize findings. Do NOT make changes — just report." \
    "openrouter/google/gemini-2.0-flash-001" \
    "announce"

# 2. Workspace Git Sync (hourly)
create_cron_job "Workspace Git Sync" \
    '{"kind": "cron", "expr": "0 * * * *", "tz": "America/New_York"}' \
    "Run a git sync: cd ~/.openclaw/workspace && git add -A && git diff --cached --quiet || (git commit -m \"auto-sync: $(date '+%Y-%m-%d %H:%M')\" && git push). If no changes, do nothing. Do NOT report back unless error." \
    "openrouter/google/gemini-2.0-flash-001" \
    "none"

# 3. Daily Briefing
create_cron_job "Daily Briefing" \
    '{"kind": "cron", "expr": "0 7 * * *", "tz": "America/New_York"}' \
    "Generate morning briefing: Check weather, summarize important emails, report system health. Be concise." \
    "openrouter/google/gemini-2.0-flash-001" \
    "announce"

# 4. Urgent Email Check
create_cron_job "Urgent Email Check" \
    '{"kind": "cron", "expr": "*/30 8-18 * * 1-5", "tz": "America/New_York"}' \
    "Check for urgent emails. Look for keywords: urgent, critical, asap, action required, deadline, payment, security. Only alert if something truly urgent is found. Otherwise stay silent." \
    "openrouter/google/gemini-2.0-flash-001" \
    "none"

# 5. Memory Alert Check (hourly — alerts only if gateway memory > 2GB)
if [ -f "$WORKSPACE/scripts/memory-alert-check.sh" ]; then
    chmod +x "$WORKSPACE/scripts/memory-alert-check.sh"
    (crontab -l 2>/dev/null | grep -v "memory-alert-check.sh"; echo "0 * * * * $WORKSPACE/scripts/memory-alert-check.sh >> $HOME/.openclaw/logs/memory-alert.log 2>&1") | crontab -
    echo "  ✅ Memory Alert Check (hourly, alerts if gateway >2GB)"
else
    echo "  ⚠️  memory-alert-check.sh not found — skipping"
fi

# 6. API Health Check (every 30 min — alerts only on state changes)
if [ -f "$WORKSPACE/scripts/api-health-check.sh" ]; then
    chmod +x "$WORKSPACE/scripts/api-health-check.sh"
    (crontab -l 2>/dev/null | grep -v "api-health-check.sh"; echo "*/30 * * * * $WORKSPACE/scripts/api-health-check.sh >> $HOME/.openclaw/logs/api-health.log 2>&1") | crontab -
    echo "  ✅ API Health Check (every 30 min, state-change alerts only)"
else
    echo "  ⚠️  api-health-check.sh not found — skipping"
fi

# 7. Screenshot cleanup (daily 2 AM — keeps last 14 days / 250MB)
if [ -f "$WORKSPACE/scripts/screenshot-cleanup.sh" ]; then
    chmod +x "$WORKSPACE/scripts/screenshot-cleanup.sh"
    (crontab -l 2>/dev/null | grep -v "screenshot-cleanup.sh"; echo "0 2 * * * $WORKSPACE/scripts/screenshot-cleanup.sh >> $HOME/.openclaw/logs/screenshot-cleanup.log 2>&1") | crontab -
    echo "  ✅ Screenshot Cleanup (daily 2 AM, 14-day / 250MB retention)"
else
    echo "  ⚠️  screenshot-cleanup.sh not found — skipping"
fi

# 8. Screenshot sync (every minute — copies latest screenshot to latest-screenshot.png)
if [ -f "$WORKSPACE/scripts/screenshot-sync.sh" ]; then
    chmod +x "$WORKSPACE/scripts/screenshot-sync.sh"
    (crontab -l 2>/dev/null | grep -v "screenshot-sync.sh"; echo "* * * * * $WORKSPACE/scripts/screenshot-sync.sh >> /dev/null 2>&1") | crontab -
    echo "  ✅ Screenshot Sync (every minute → latest-screenshot.png)"
else
    echo "  ⚠️  screenshot-sync.sh not found — skipping"
fi

echo ""
echo "=== Extension Installation ==="
echo ""

# Check if claude-mem is already installed
if [ -d "$HOME/.openclaw/extensions/claude-mem" ]; then
    echo "✅ claude-mem extension already installed"
else
    echo "Installing claude-mem extension..."
    echo "  This requires manual steps:"
    echo ""
    echo "  1. Visit: https://claude-mem.com"
    echo "  2. Download the OpenClaw plugin"
    echo "  3. Or ask your agent: 'install the claude-mem extension'"
    echo ""
    echo "  The extension is needed for memory search to work."
fi

echo ""
echo "=== Optional: Life Audit App (local dev) ==="
echo ""
echo "The Life Audit App is deployed to Vercel at:"
echo "  https://life-audit-app.vercel.app"
echo ""
echo "To also run it locally (port 3003):"
echo ""

read -p "Set up life-audit-app locally? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    PROJECTS_DIR="$HOME/.openclaw/workspace/elon/projects"
    mkdir -p "$PROJECTS_DIR"

    if [ -d "$PROJECTS_DIR/life-audit-app" ]; then
        echo "  ✅ life-audit-app already exists — pulling latest"
        cd "$PROJECTS_DIR/life-audit-app" && git pull --quiet
    else
        echo "  Cloning life-audit-app..."
        git clone --quiet https://github.com/13Guinness/life-audit-app "$PROJECTS_DIR/life-audit-app"
    fi

    echo "  Installing dependencies..."
    cd "$PROJECTS_DIR/life-audit-app" && npm install --silent

    # Prompt for Neon DB URL
    echo ""
    echo "  You need a Neon Postgres DATABASE_URL."
    echo "  Get it from: vercel.com → life-audit-app → Settings → Environment Variables"
    echo ""
    read -p "  Paste DATABASE_URL (or press Enter to skip): " DB_URL
    read -p "  Paste DIRECT_URL (unpooled, or press Enter to skip): " DIRECT_URL_VAL

    if [ -n "$DB_URL" ]; then
        cat > "$PROJECTS_DIR/life-audit-app/.env.local" << ENV
DATABASE_URL="$DB_URL"
DIRECT_URL="${DIRECT_URL_VAL:-$DB_URL}"
NEXTAUTH_URL="http://localhost:3003"
NEXTAUTH_SECRET="$(openssl rand -hex 32)"
ANTHROPIC_API_KEY=""
RESEND_API_KEY=""
ADMIN_EMAIL="matt@fuelvm.com"
ENV
        echo "  ✅ .env.local written (add ANTHROPIC_API_KEY manually)"

        # Run migrations
        echo "  Running migrations..."
        cd "$PROJECTS_DIR/life-audit-app" && npx prisma migrate deploy 2>&1 | tail -2
    fi

    # Create LaunchAgent
    NODE_PATH=$(which node)
    PROJ="$PROJECTS_DIR/life-audit-app"
    cat > "$HOME/Library/LaunchAgents/ai.openclaw.life-audit.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key><string>ai.openclaw.life-audit</string>
    <key>RunAtLoad</key><true/>
    <key>KeepAlive</key><true/>
    <key>ProgramArguments</key>
    <array>
      <string>$NODE_PATH</string>
      <string>$PROJ/node_modules/.bin/next</string>
      <string>dev</string>
      <string>--port</string><string>3003</string>
      <string>--hostname</string><string>0.0.0.0</string>
    </array>
    <key>WorkingDirectory</key><string>$PROJ</string>
    <key>StandardOutPath</key><string>$HOME/.openclaw/logs/life-audit.log</string>
    <key>StandardErrorPath</key><string>$HOME/.openclaw/logs/life-audit.err.log</string>
    <key>EnvironmentVariables</key>
    <dict>
      <key>HOME</key><string>$HOME</string>
      <key>PATH</key><string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
      <key>NODE_OPTIONS</key><string>--max-old-space-size=2048</string>
    </dict>
  </dict>
</plist>
PLIST
    launchctl load "$HOME/Library/LaunchAgents/ai.openclaw.life-audit.plist" 2>/dev/null
    echo "  ✅ LaunchAgent created (port 3003, auto-restarts)"

    # Tailscale serve
    TS="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
    if [ -f "$TS" ]; then
        $TS serve --bg --https=3003 http://localhost:3003 2>/dev/null && \
            echo "  ✅ Tailscale serve registered (https://[hostname]:3003)" || \
            echo "  ⚠️  Tailscale serve already set for 3003 (or Tailscale not running)"
    fi
fi

echo ""
echo "=== Skills (Pre-installed) ==="
echo ""
echo "26 marketing skills are pre-installed in your workspace:"
echo "  CRO, copywriting, SEO, email sequences, A/B testing, pricing strategy,"
echo "  launch strategy, analytics, paid ads, social content, and more."
echo ""
echo "4 custom operational skills are also available:"
echo "  testing-automation, google-search-console, site-monitor, client-seo-reporting"
echo ""
echo "To install additional skills from ClawHub:"
echo "  'Install skill [name]' or visit clawhub.com"
echo ""

echo "=== Post-Setup Complete ==="
echo ""
echo "Next steps:"
echo "  1. Message your Telegram bot to pair it"
echo "  2. Run the onboarding wizard: ./scripts/first-steps-onboarding.sh"
echo "  3. Edit your workspace files (IDENTITY.md, USER.md, SOUL.md)"
echo "  4. Test: send 'what time is it?' to your bot"
echo ""
echo "Cron jobs are now active and will run on schedule."
echo "Check status anytime with: openclaw cron status"
echo ""

# Offer to run onboarding
read -p "Run first-steps onboarding now? [Y/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
    echo ""
    ./scripts/first-steps-onboarding.sh
fi
