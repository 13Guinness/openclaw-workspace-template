#!/bin/bash
# First Steps Onboarding - Runs after OpenClaw setup completes
# Interactive questionnaire to personalize the system and suggest automations

echo ""
echo "═══════════════════════════════════════════════════"
echo "  Welcome to OpenClaw! Let's set up your system"
echo "═══════════════════════════════════════════════════"
echo ""
echo "I'll ask a few quick questions to personalize your experience"
echo "and suggest some simple automations to get you started."
echo ""

# Collect basic info
echo "1. What should I call you?"
read -r USER_NAME
echo ""

echo "2. What do you do for work? (brief description)"
read -r USER_WORK
echo ""

echo "3. What's your biggest daily time sink?"
echo "   (emails, scheduling, research, social media, etc.)"
read -r TIME_SINK
echo ""

echo "4. What repetitive task do you do most often?"
echo "   (checking email, updating spreadsheets, booking meetings, etc.)"
read -r REPETITIVE_TASK
echo ""

echo "5. What would you automate first if you could?"
read -r FIRST_AUTOMATION
echo ""

echo "═══════════════════════════════════════════════════"
echo "  Based on your answers, here are 3 simple starters:"
echo "═══════════════════════════════════════════════════"
echo ""

cat << 'EOF'
1. DAILY BRIEFING (5 min setup)
   • Morning weather + email summary
   • Runs automatically at 7 AM
   • Delivers to your phone

2. URGENT EMAIL WATCHDOG (2 min setup)
   • Scans emails every 30 minutes
   • Alerts you if something is marked URGENT
   • Ignores newsletters and noise

3. SMART EMAIL CLEANUP (3 min setup)
   • Auto-deletes WordPress notifications
   • Clears marketing emails
   • Runs daily at 8 AM

EOF

echo ""

# Present options and collect responses
echo "Enable the Daily Briefing? [Y/n]"
read -r ENABLE_BRIEFING
if [[ -z "$ENABLE_BRIEFING" ]] || [[ "$ENABLE_BRIEFING" =~ ^[Yy] ]]; then
    echo "Setting up Daily Briefing..."
    # Add cron job for daily briefing
    (crontab -l 2>/dev/null; echo "0 7 * * * /Users/$USER/.openclaw/workspace/scripts/daily-briefing.sh") | crontab -
    echo "✓ Daily Briefing enabled (7 AM daily)"
else
    echo "✗ Daily Briefing skipped"
fi
echo ""

echo "Enable Urgent Email Watchdog? [Y/n]"
read -r ENABLE_WATCHDOG
if [[ -z "$ENABLE_WATCHDOG" ]] || [[ "$ENABLE_WATCHDOG" =~ ^[Yy] ]]; then
    echo "Setting up Urgent Email Watchdog..."
    # Add cron job for urgent email check
    (crontab -l 2>/dev/null; echo "*/30 * * * * /Users/$USER/.openclaw/workspace/scripts/urgent-email-check.sh") | crontab -
    echo "✓ Urgent Email Watchdog enabled (every 30 min)"
else
    echo "✗ Urgent Email Watchdog skipped"
fi
echo ""

echo "Enable Smart Email Cleanup? [Y/n]"
read -r ENABLE_CLEANUP
if [[ -z "$ENABLE_CLEANUP" ]] || [[ "$ENABLE_CLEANUP" =~ ^[Yy] ]]; then
    echo "Setting up Smart Email Cleanup..."
    echo "✓ Smart Email Cleanup enabled (8 AM daily)"
    echo "   (This is already configured by post-setup.sh)"
else
    echo "✗ Smart Email Cleanup skipped"
fi
echo ""

# Save user preferences
echo "Saving your preferences..."
mkdir -p "$HOME/.openclaw/workspace/memory"
cat > "$HOME/.openclaw/workspace/memory/onboarding-answers.md" << EOF
# Onboarding Answers — $(date +%Y-%m-%d)

**Name:** $USER_NAME  
**Work:** $USER_WORK  
**Biggest Time Sink:** $TIME_SINK  
**Most Repetitive Task:** $REPETITIVE_TASK  
**First Automation Desire:** $FIRST_AUTOMATION  

## Enabled Automations
EOF

# Track what was enabled
if [[ -z "$ENABLE_BRIEFING" ]] || [[ "$ENABLE_BRIEFING" =~ ^[Yy] ]]; then
    echo "- [x] Daily Briefing (7 AM)" >> "$HOME/.openclaw/workspace/memory/onboarding-answers.md"
else
    echo "- [ ] Daily Briefing (7 AM)" >> "$HOME/.openclaw/workspace/memory/onboarding-answers.md"
fi

if [[ -z "$ENABLE_WATCHDOG" ]] || [[ "$ENABLE_WATCHDOG" =~ ^[Yy] ]]; then
    echo "- [x] Urgent Email Watchdog (every 30 min)" >> "$HOME/.openclaw/workspace/memory/onboarding-answers.md"
else
    echo "- [ ] Urgent Email Watchdog (every 30 min)" >> "$HOME/.openclaw/workspace/memory/onboarding-answers.md"
fi

if [[ -z "$ENABLE_CLEANUP" ]] || [[ "$ENABLE_CLEANUP" =~ ^[Yy] ]]; then
    echo "- [x] Smart Email Cleanup (8 AM daily)" >> "$HOME/.openclaw/workspace/memory/onboarding-answers.md"
else
    echo "- [ ] Smart Email Cleanup (8 AM daily)" >> "$HOME/.openclaw/workspace/memory/onboarding-answers.md"
fi

# Add contextual next steps
cat >> "$HOME/.openclaw/workspace/memory/onboarding-answers.md" << 'EOF'

## Next Steps (Suggested)
EOF

if echo "$TIME_SINK" | grep -qi "email"; then
    echo "- [ ] Try the 'urgent email' command to test watchdog" >> "$HOME/.openclaw/workspace/memory/onboarding-answers.md"
    echo "- [ ] Review email rules in memory/email-rules.md" >> "$HOME/.openclaw/workspace/memory/onboarding-answers.md"
fi

if echo "$TIME_SINK" | grep -qi "schedule\|calendar\|meeting"; then
    echo "- [ ] Connect calendar: ask your agent 'check my calendar today'" >> "$HOME/.openclaw/workspace/memory/onboarding-answers.md"
fi

if echo "$REPETITIVE_TASK" | grep -qi "research\|search\|read"; then
    echo "- [ ] Try web search: 'search for [topic]'" >> "$HOME/.openclaw/workspace/memory/onboarding-answers.md"
    echo "- [ ] Try summarize: 'summarize this article [URL]'" >> "$HOME/.openclaw/workspace/memory/onboarding-answers.md"
fi

# Default suggestions
cat >> "$HOME/.openclaw/workspace/memory/onboarding-answers.md" << 'EOF'
- [ ] Send a test message to verify everything works
- [ ] Try asking a question: "What's on my schedule today?"
- [ ] Explore: type 'help' to see what your agent can do

## Advanced Options (Later)
Run the full automation audit when ready:
Ask your agent to run the automation audit from docs/AUTOMATION_AUDIT.md
EOF

echo "✓ Preferences saved to memory/onboarding-answers.md"
echo ""

# Final message
echo "═══════════════════════════════════════════════════"
echo "  You're all set! Here's how to use your system:"
echo "═══════════════════════════════════════════════════"
echo ""
echo "• Message me anytime via Telegram, Discord, or the web interface"
echo "• I'll remember your preferences and context across sessions"
echo "• Try asking: 'what's my daily briefing?' or 'check my email'"
echo ""
echo "Want more automation ideas?"
echo "Just ask: 'what else can you automate for me?'"
echo ""
echo "Happy clawing!"
echo ""
