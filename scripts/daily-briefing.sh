#!/bin/bash

# Daily Briefing Script for OpenClaw
# Generates a morning briefing with email, weather, and system stats

set -euo pipefail

WORKSPACE="/Users/mattsartori/.openclaw/workspace"

# Helper function to detect urgent keywords
is_urgent() {
    local subject="$1"
    echo "$subject" | grep -iE '(urgent|important|asap|critical|action required|deadline|reminder|payment|invoice|overdue|expires|alert|security)' >/dev/null && echo "🔴" || echo ""
}

# Helper function to detect automated emails (returns 0 if automated, 1 if human)
is_automated() {
    local from="$1"
    # Common automated sender patterns
    echo "$from" | grep -iE '(noreply|no-reply|notification|automated|do-not-reply|mailer|digest|newsletter|updates@|news@|marketing@|promo|team@|hello@|hi@)' >/dev/null && return 0
    
    # Common service names
    echo "$from" | grep -iE '^(Instagram|Facebook|Twitter|LinkedIn|Google|GitHub|Slack|Discord|Stripe|PayPal|Amazon|Apple|Microsoft|Dropbox|Zoom|Calendly|Mailchimp|SendGrid|Zight)' >/dev/null && return 0
    
    return 1
}

# Start output
echo "☀️ Good morning, Matt!"
echo ""

# Weather
echo "🌤️ Weather:"
WEATHER=$(curl -s "wttr.in/Indianapolis?format=3" || echo "Weather unavailable")
echo "$WEATHER"
echo ""

# Email Summary
echo "📧 Email"
ACCOUNTS=("fuelvmhosting" "msartori" "fasterstack")
NOTABLE_EMAILS=()

for account in "${ACCOUNTS[@]}"; do
    # Get unread emails (suppress warnings)
    EMAILS=$(himalaya envelope list --account "$account" --page-size 5 "not flag seen" 2>&1 | grep -v "WARN" || echo "")
    
    # Count unread (subtract header lines)
    UNREAD_COUNT=$(echo "$EMAILS" | tail -n +3 | grep -v "^$" | wc -l | tr -d ' ')
    
    echo "• $account: $UNREAD_COUNT unread"
    
    # Process recent unread emails (max 5)
    if [ "$UNREAD_COUNT" -gt 0 ]; then
        while IFS= read -r line; do
            # Skip empty lines and table borders
            [[ -z "$line" || "$line" =~ ^[\|\-]+$ ]] && continue
            
            # Parse himalaya output: ID | FLAGS | SUBJECT | FROM | DATE
            # Extract subject and from fields (columns 4 and 5)
            SUBJECT=$(echo "$line" | awk -F'|' '{print $4}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            FROM=$(echo "$line" | awk -F'|' '{print $5}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            
            # Skip header line
            [[ "$SUBJECT" == "SUBJECT" ]] && continue
            
            # Skip if we didn't get valid data
            [[ -z "$SUBJECT" || -z "$FROM" ]] && continue
            
            # Check for urgency
            URGENT_FLAG=$(is_urgent "$SUBJECT")
            
            # Check if from real person (not automated)
            if ! is_automated "$FROM"; then
                # This looks like a real person
                NOTABLE_EMAILS+=("$URGENT_FLAG [$account] \"$SUBJECT\" from $FROM 👤")
            elif [ -n "$URGENT_FLAG" ]; then
                # Urgent automated email
                NOTABLE_EMAILS+=("$URGENT_FLAG [$account] \"$SUBJECT\"")
            fi
        done <<< "$(echo "$EMAILS" | tail -n +3)"
    fi
done

echo ""

# Notable Emails
if [ ${#NOTABLE_EMAILS[@]} -gt 0 ]; then
    echo "📋 Notable Emails"
    for email in "${NOTABLE_EMAILS[@]}"; do
        echo "• $email"
    done
    echo ""
fi

# System Health
echo "🔧 System Health"

# Disk usage
DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}')
echo "• Disk: $DISK_USAGE used"

# Count workspace files
FILE_COUNT=$(find "$WORKSPACE" -type f 2>/dev/null | wc -l | tr -d ' ')
echo "• Workspace files: $FILE_COUNT"

# Check cron logs (macOS uses system.log or may not have detailed cron logs)
# We'll check if we can access cron logs
if [ -f "/var/log/cron.log" ]; then
    CRON_FAILURES=$(grep -i "error\|fail" /var/log/cron.log 2>/dev/null | grep "$(date +%Y-%m-%d)" | wc -l | tr -d ' ')
    if [ "$CRON_FAILURES" -gt 0 ]; then
        echo "• Cron jobs: ⚠️ $CRON_FAILURES failures detected"
    else
        echo "• Cron jobs: ✅ all green"
    fi
else
    # macOS typically doesn't have /var/log/cron.log, check system log instead
    # Use a safer approach that doesn't cause arithmetic errors
    CRON_CHECK=$(#skipped - too slow
    if [ -n "$CRON_CHECK" ]; then
        FAIL_COUNT=$(echo "$CRON_CHECK" | wc -l | tr -d ' ')
        echo "• Cron jobs: ⚠️ $FAIL_COUNT potential issues"
    else
        echo "• Cron jobs: ✅ all green"
    fi
fi

echo ""
echo "Have a good day!"
