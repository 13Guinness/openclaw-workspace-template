#!/bin/bash
# Graceful restart of OpenClaw gateway on memory pressure

GATEWAY_PID=$(ps aux | grep -v grep | grep "openclaw-gateway" | awk '{print $2}' | head -1)
LOG_FILE="$HOME/.openclaw/workspace/logs/memory-restart.log"

if [ -z "$GATEWAY_PID" ]; then
    echo "$(date): Gateway not running" >> "$LOG_FILE"
    exit 1
fi

echo "$(date): Restarting gateway (PID: $GATEWAY_PID) due to memory pressure" >> "$LOG_FILE"

# Use SIGUSR1 for graceful restart
kill -USR1 "$GATEWAY_PID"

# Wait up to 30s for restart
for i in {1..30}; do
    sleep 1
    NEW_PID=$(pgrep -f "openclaw-gateway" | head -1)
    if [ -n "$NEW_PID" ] && [ "$NEW_PID" != "$GATEWAY_PID" ]; then
        echo "$(date): Gateway restarted (new PID: $NEW_PID)" >> "$LOG_FILE"
        exit 0
    fi
done

echo "$(date): Graceful restart failed, attempting force restart" >> "$LOG_FILE"
kill -9 "$GATEWAY_PID" 2>/dev/null
sleep 2
openclaw gateway start 2>/dev/null || true
