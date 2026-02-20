#!/bin/bash
# Checks preferred API providers and reports if anything is degraded
# Runs every 30 minutes. Only alerts on state CHANGES (not every check).

STATE_FILE="$HOME/.openclaw/workspace/memory/api-health-state.json"
LOG="$HOME/.openclaw/workspace/logs/api-health.log"
mkdir -p "$(dirname "$LOG")" "$(dirname "$STATE_FILE")"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Load previous state
if [ -f "$STATE_FILE" ]; then
    PREV_ANTHROPIC=$(python3 -c "import json; d=json.load(open('$STATE_FILE')); print(d.get('anthropic','unknown'))" 2>/dev/null)
    PREV_OPENROUTER=$(python3 -c "import json; d=json.load(open('$STATE_FILE')); print(d.get('openrouter','unknown'))" 2>/dev/null)
else
    PREV_ANTHROPIC="unknown"
    PREV_OPENROUTER="unknown"
fi

ANTHROPIC_KEY=$(python3 -c "import json; d=json.load(open('$HOME/.openclaw/openclaw.json')); print(d['env']['ANTHROPIC_API_KEY'])" 2>/dev/null)
OPENROUTER_KEY=$(python3 -c "import json; d=json.load(open('$HOME/.openclaw/openclaw.json')); print(d['env']['OPENROUTER_API_KEY'])" 2>/dev/null)

# Test Anthropic API with minimal request
ANTHROPIC_STATUS="ok"
ANTHROPIC_RESP=$(curl -s -o /dev/null -w "%{http_code}" \
    --max-time 10 \
    -X POST "https://api.anthropic.com/v1/messages" \
    -H "x-api-key: $ANTHROPIC_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d '{"model":"claude-haiku-4-5","max_tokens":1,"messages":[{"role":"user","content":"hi"}]}' 2>/dev/null)

if [ "$ANTHROPIC_RESP" = "429" ]; then
    ANTHROPIC_STATUS="rate_limited"
elif [ "$ANTHROPIC_RESP" = "401" ] || [ "$ANTHROPIC_RESP" = "403" ]; then
    ANTHROPIC_STATUS="auth_error"
elif [ "$ANTHROPIC_RESP" != "200" ]; then
    ANTHROPIC_STATUS="error_$ANTHROPIC_RESP"
fi

# Test OpenRouter API
OPENROUTER_STATUS="ok"
OPENROUTER_RESP=$(curl -s -o /dev/null -w "%{http_code}" \
    --max-time 10 \
    -X POST "https://openrouter.ai/api/v1/chat/completions" \
    -H "Authorization: Bearer $OPENROUTER_KEY" \
    -H "Content-Type: application/json" \
    -d '{"model":"google/gemini-2.0-flash-001","messages":[{"role":"user","content":"hi"}],"max_tokens":1}' 2>/dev/null)

if [ "$OPENROUTER_RESP" = "429" ]; then
    OPENROUTER_STATUS="rate_limited"
elif [ "$OPENROUTER_RESP" = "401" ] || [ "$OPENROUTER_RESP" = "403" ]; then
    OPENROUTER_STATUS="auth_error"
elif [ "$OPENROUTER_RESP" != "200" ]; then
    OPENROUTER_STATUS="error_$OPENROUTER_RESP"
fi

# Save current state
python3 -c "
import json
state = {'anthropic': '$ANTHROPIC_STATUS', 'openrouter': '$OPENROUTER_STATUS', 'last_check': '$TIMESTAMP'}
json.dump(state, open('$STATE_FILE', 'w'), indent=2)
"

echo "$TIMESTAMP: anthropic=$ANTHROPIC_STATUS openrouter=$OPENROUTER_STATUS" >> "$LOG"

# Alert only on state CHANGES
ALERTS=""

if [ "$ANTHROPIC_STATUS" != "$PREV_ANTHROPIC" ]; then
    if [ "$ANTHROPIC_STATUS" = "ok" ] && [ "$PREV_ANTHROPIC" != "ok" ] && [ "$PREV_ANTHROPIC" != "unknown" ]; then
        ALERTS="${ALERTS}✅ Anthropic API is back online (was: $PREV_ANTHROPIC)\n"
    elif [ "$ANTHROPIC_STATUS" != "ok" ]; then
        ALERTS="${ALERTS}⚠️ Anthropic API is $ANTHROPIC_STATUS\n"
    fi
fi

if [ "$OPENROUTER_STATUS" != "$PREV_OPENROUTER" ]; then
    if [ "$OPENROUTER_STATUS" = "ok" ] && [ "$PREV_OPENROUTER" != "ok" ] && [ "$PREV_OPENROUTER" != "unknown" ]; then
        ALERTS="${ALERTS}✅ OpenRouter API is back online (was: $PREV_OPENROUTER)\n"
    elif [ "$OPENROUTER_STATUS" != "ok" ]; then
        ALERTS="${ALERTS}⚠️ OpenRouter API is $OPENROUTER_STATUS\n"
    fi
fi

if [ -n "$ALERTS" ]; then
    echo -e "$ALERTS"
fi
