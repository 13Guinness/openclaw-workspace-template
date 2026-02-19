#!/usr/bin/env bash
# Urgent Email Detection System for OpenClaw
# Scans recent unread emails and classifies by urgency
#
# Usage: ./urgent-email-check.sh
# Output: Telegram-formatted alert (stdout), progress to stderr

set -euo pipefail

# --- Config ---
ACCOUNTS=("fuelvmhosting" "msartori" "fasterstack")
LIMIT=10          # Max unread emails to check per account
FETCH_SIZE=20     # Fetch extra to filter for unseen client-side

# --- Temp files ---
TMPDIR_RUN="/tmp/urgent-email-$$"
mkdir -p "$TMPDIR_RUN"
trap "rm -rf $TMPDIR_RUN" EXIT

URGENT_FILE="$TMPDIR_RUN/urgent"
IMPORTANT_FILE="$TMPDIR_RUN/important"
touch "$URGENT_FILE" "$IMPORTANT_FILE"

# --- Classification patterns (case-insensitive grep -iE) ---

# URGENT: alert immediately
URGENT_SUBJECT="urgent|asap|action required|deadline today|payment overdue|account suspended|security breach|server down|site down|domain expir|ssl expir|billing issue|immediate attention|failed to renew"

# IMPORTANT: include in next briefing
IMPORTANT_COMBINED="receipt|invoice|payment confirmation|meeting invite|calendar invite|password reset|unusual sign-in|security alert|web form|contact form|wilco web form|google ads|customer request|new lead|wordfence|new call from a potential customer|new request"

# IGNORE: skip entirely
IGNORE_COMBINED="newsletter|digest|weekly roundup|monthly roundup|unsubscribe|instagram|facebook notification|twitter|linkedin|nextdoor|pinterest|tiktok|plugin.*updated|some plugins were automatically|discount|% off|promo code|webinar|limited time|don.t miss|last chance|cold email|let.s connect|quick question|see .* in your feed|friend suggestion"

# Important senders (if they send billing/security emails, treat as urgent)
IMPORTANT_SENDERS="stripe|paypal|square|quickbooks|google workspace|godaddy|namecheap|cloudflare|aws|digitalocean|wpengine|kinsta|wordfence|wilco"

# --- Functions ---

classify_email() {
    local subject="$1"
    local from_name="$2"
    local from_addr="$3"
    local date="$4"
    local account="$5"

    local combined="$subject $from_name $from_addr"

    # 1. Check IGNORE first
    if echo "$combined" | grep -iEq "$IGNORE_COMBINED" 2>/dev/null; then
        return 0
    fi

    # 2. Check URGENT subject patterns
    if echo "$subject" | grep -iEq "$URGENT_SUBJECT" 2>/dev/null; then
        printf '🚨 URGENT [%s]\nFrom: %s <%s>\nSubject: %s\nDate: %s\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n' \
            "$account" "$from_name" "$from_addr" "$subject" "$date" >> "$URGENT_FILE"
        return 0
    fi

    # 3. Important sender + billing/security → urgent
    if echo "$from_addr $from_name" | grep -iEq "$IMPORTANT_SENDERS" 2>/dev/null; then
        if echo "$subject" | grep -iEq "payment|invoice|receipt|bill|expired|renew|security|alert|suspend" 2>/dev/null; then
            printf '⚠️  IMPORTANT SENDER [%s]\nFrom: %s <%s>\nSubject: %s\nDate: %s\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n' \
                "$account" "$from_name" "$from_addr" "$subject" "$date" >> "$URGENT_FILE"
            return 0
        fi
    fi

    # 4. Check IMPORTANT patterns
    if echo "$combined" | grep -iEq "$IMPORTANT_COMBINED" 2>/dev/null; then
        printf '📋 [%s] %s: %s\n' "$account" "$from_name" "$subject" >> "$IMPORTANT_FILE"
        return 0
    fi
}

# --- Phase 1: Fetch all accounts in parallel ---

echo "🔍 Scanning emails across ${#ACCOUNTS[@]} accounts..." >&2

pids=()
for account in "${ACCOUNTS[@]}"; do
    raw_file="$TMPDIR_RUN/raw-$account.json"
    (
        himalaya envelope list -a "$account" -s "$FETCH_SIZE" -o json "order by date desc" 2>/dev/null > "$raw_file" || echo "[]" > "$raw_file"
    ) &
    pids+=($!)
done

# Wait for all fetches to complete
for pid in "${pids[@]}"; do
    wait "$pid" 2>/dev/null || true
done

echo "  ✓ All accounts fetched" >&2

# --- Phase 2: Process results sequentially ---

for account in "${ACCOUNTS[@]}"; do
    raw_file="$TMPDIR_RUN/raw-$account.json"

    # Validate JSON
    if ! jq -e . "$raw_file" >/dev/null 2>&1; then
        echo "  ⚠️  Invalid JSON from $account" >&2
        continue
    fi

    # Filter unseen, extract fields as TSV
    tsv_file="$TMPDIR_RUN/tsv-$account.tsv"
    jq -r --argjson limit "$LIMIT" '
        [.[] | select(.flags | contains(["Seen"]) | not)] | .[:$limit] |
        .[] |
        [
            (.subject // "No Subject"),
            (.from.name // .from.addr // "Unknown"),
            (.from.addr // "unknown@unknown.com"),
            (.date // "Unknown date")
        ] | @tsv
    ' "$raw_file" > "$tsv_file" 2>/dev/null

    count=$(wc -l < "$tsv_file" | tr -d ' ')
    echo "  → $account: $count unread" >&2

    # Classify each email
    while IFS=$'\t' read -r subject from_name from_addr date; do
        [ -z "$subject" ] && continue
        classify_email "$subject" "$from_name" "$from_addr" "$date" "$account"
    done < "$tsv_file"
done

echo "" >&2

# --- Output ---

if [ -s "$URGENT_FILE" ]; then
    echo "🚨 URGENT EMAILS DETECTED"
    echo ""
    cat "$URGENT_FILE"
    if [ -s "$IMPORTANT_FILE" ]; then
        echo ""
        echo "📋 Also important (non-urgent):"
        cat "$IMPORTANT_FILE"
    fi
    exit 0
fi

if [ -s "$IMPORTANT_FILE" ]; then
    echo "📋 Important emails (non-urgent):"
    echo ""
    cat "$IMPORTANT_FILE"
    exit 0
fi

echo "✅ No urgent emails"
exit 0
