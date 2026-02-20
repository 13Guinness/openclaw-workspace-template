#!/bin/bash
# Email cleanup script - applies rules from memory/email-rules.md
# Run daily via cron to auto-delete noise emails

LOG_FILE="$HOME/.openclaw/workspace/logs/email-cleanup-$(date +%Y-%m-%d).log"
mkdir -p "$(dirname "$LOG_FILE")"

echo "=== Email Cleanup: $(date) ===" >> "$LOG_FILE"

# Accounts to process
ACCOUNTS="fuelvmhosting msartori fasterstack"

# Counters (simple variables since bash 3.2 doesn't have associative arrays)
deleted_fuel=0
deleted_msartori=0
deleted_faster=0

for account in $ACCOUNTS; do
    echo "Processing account: $account" >> "$LOG_FILE"
    
    # Get last 50 emails
    emails=$(himalaya --account "$account" envelope list --page-size 50 --output json 2>/dev/null)
    
    if [ -z "$emails" ] || [ "$emails" = "[]" ]; then
        echo "  No emails found" >> "$LOG_FILE"
        continue
    fi
    
    account_deleted=0
    
    # Process each email
    while IFS= read -r email; do
        [ -z "$email" ] && continue
        
        id=$(echo "$email" | jq -r '.id // empty')
        subject=$(echo "$email" | jq -r '.subject // empty')
        from=$(echo "$email" | jq -r '.from.addr // empty')
        
        [ -z "$id" ] && continue
        
        should_delete=false
        reason=""
        
        # Rule 1: WordPress success notifications
        if echo "$subject" | grep -qi "Some plugins were automatically updated"; then
            should_delete=true
            reason="WP success notification"
        elif echo "$subject" | grep -qiE "[0-9]+ plugin.*was updated" && ! echo "$subject" | grep -qiE "(not updated|failed|could not|consistently)"; then
            should_delete=true
            reason="WP plugin update success"
        fi
        
        # Rule 2: Marketing / bulk senders
        if [ "$should_delete" = false ]; then
            if echo "$from" | grep -qiE "(noreply|newsletter|marketing|hello|info|support|team|updates)@"; then
                should_delete=true
                reason="bulk sender"
            fi
        fi
        
        # Rule 3: Newsletters / digests
        if [ "$should_delete" = false ]; then
            if echo "$subject" | grep -qiE "(newsletter|digest|weekly|monthly|roundup|update from|what you missed)"; then
                should_delete=true
                reason="newsletter/digest"
            fi
        fi
        
        # Rule 4: Social notifications
        if [ "$should_delete" = false ]; then
            if echo "$from" | grep -qiE "(linkedin|facebook|twitter|nextdoor|instagram|youtube)" || \
               echo "$subject" | grep -qiE "(liked your|commented on|started following|connection request|invited you)"; then
                should_delete=true
                reason="social notification"
            fi
        fi
        
        # Execute deletion
        if [ "$should_delete" = true ]; then
            echo "  Deleting [$id]: $subject (from: $from) — $reason" >> "$LOG_FILE"
            himalaya --account "$account" message move "$id" "[Gmail]/Trash" 2>/dev/null
            if [ $? -eq 0 ]; then
                account_deleted=$((account_deleted + 1))
            fi
        fi
    done < <(echo "$emails" | jq -c '.[]' 2>/dev/null)
    
    # Update per-account counters
    case "$account" in
        fuelvmhosting) deleted_fuel=$account_deleted ;;
        msartori) deleted_msartori=$account_deleted ;;
        fasterstack) deleted_faster=$account_deleted ;;
    esac
    
    echo "  Deleted: $account_deleted" >> "$LOG_FILE"
done

# Summary
echo "" >> "$LOG_FILE"
echo "=== Summary ===" >> "$LOG_FILE"
echo "fuelvmhosting: $deleted_fuel deleted" >> "$LOG_FILE"
echo "msartori: $deleted_msartori deleted" >> "$LOG_FILE"
echo "fasterstack: $deleted_faster deleted" >> "$LOG_FILE"

# Output for cron
TOTAL_DELETED=$((deleted_fuel + deleted_msartori + deleted_faster))

if [ $TOTAL_DELETED -gt 0 ]; then
    echo "Email cleanup complete: $TOTAL_DELETED emails moved to trash (fuelvmhosting: $deleted_fuel, msartori: $deleted_msartori, fasterstack: $deleted_faster)"
else
    echo "Email cleanup complete: No emails matched deletion rules."
fi