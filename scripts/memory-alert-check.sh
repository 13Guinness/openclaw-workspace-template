#!/bin/bash
# Check for memory alert flags and generate system event if found

ALERT_FILE="$HOME/.openclaw/workspace/memory-alert.flag"
LOG_DIR="$HOME/.openclaw/workspace/logs"

if [ -f "$ALERT_FILE" ]; then
    # Get current stats for the message
    GATEWAY_PID=$(ps aux | grep -v grep | grep "openclaw-gateway" | awk '{print $2}' | head -1)
    GATEWAY_MEM=$(ps -o rss= -p "$GATEWAY_PID" 2>/dev/null | awk '{print int($1/1024)}')
    
    # Find top memory consumers
    TOP_MEM=$(ps aux | sort -nk +4 | tail -5 | awk '{print $11, $4"%", int($6/1024)"MB"}')
    
    cat <<EOF
🚨 MEMORY ALERT — OpenClaw Gateway

Gateway PID: $GATEWAY_PID
Gateway Memory: ${GATEWAY_MEM}MB

Top memory consumers:
$TOP_MEM

Recommendation: Run "/Users/mattsartori/.openclaw/workspace/scripts/memory-restart.sh" to restart gateway gracefully.
EOF
    
    # Clear alert after reporting
    rm "$ALERT_FILE"
fi
