#!/bin/bash
# Daily briefing script - generates morning summary
# Called by cron or agent

set -e

WORKSPACE="$HOME/.openclaw/workspace"

echo "☀️ Good morning!"
echo ""

# Weather
echo "🌤️ Weather:"
curl -s "wttr.in/?format=3" 2>/dev/null || echo "Weather unavailable"
echo ""

# System Health
echo "🔧 System:"
echo "• Disk: $(df -h / | tail -1 | awk '{print $5}') used"
echo "• Files: $(find "$WORKSPACE" -type f 2>/dev/null | wc -l | tr -d ' ') in workspace"
echo ""

echo "Have a good day!"
