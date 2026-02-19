#!/bin/bash
# Memory monitor for OpenClaw gateway
# Logs usage and alerts if thresholds exceeded

LOG_DIR="$HOME/.openclaw/workspace/logs"
mkdir -p "$LOG_DIR"

LOG_FILE="$LOG_DIR/memory-$(date +%Y-%m-%d).log"
ALERT_FILE="$HOME/.openclaw/workspace/memory-alert.flag"

# Get gateway PID and memory
GATEWAY_PID=$(ps aux | grep -v grep | grep "openclaw-gateway" | awk '{print $2}' | head -1)
GATEWAY_MEM_MB=0
GATEWAY_PPID="N/A"

if [ -n "$GATEWAY_PID" ]; then
    GATEWAY_MEM_MB=$(ps -o rss= -p "$GATEWAY_PID" 2>/dev/null | awk '{print int($1/1024)}')
    GATEWAY_PPID=$(ps -o ppid= -p "$GATEWAY_PID" 2>/dev/null | xargs)
fi

# System memory
TOTAL_MEM=$(vm_stat | grep "Pages free" | awk '{print $3}' | tr -d '.')
TOTAL_MB=$((TOTAL_MEM * 16384 / 1024 / 1024))

# All Node processes
NODE_PROCS=$(ps aux | grep node | grep -v grep | wc -l)

# Log entry
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo "$TIMESTAMP,gateway:$GATEWAY_MEM_MB,total_free:$TOTAL_MB,node_procs:$NODE_PROCS,pid:$GATEWAY_PID" >> "$LOG_FILE"

# Alert thresholds
# Gateway >2GB or system free <3GB
if [ "$GATEWAY_MEM_MB" -gt 2048 ] && [ ! -f "$ALERT_FILE" ]; then
    touch "$ALERT_FILE"
    echo "⚠️ MEMORY ALERT: OpenClaw gateway using ${GATEWAY_MEM_MB}MB" >> "$LOG_FILE"
fi

# Reset alert if memory recovered
if [ "$GATEWAY_MEM_MB" -lt 1536 ] && [ -f "$ALERT_FILE" ]; then
    rm "$ALERT_FILE"
fi

# Keep only last 7 days of logs
find "$LOG_DIR" -name "memory-*.log" -mtime +7 -delete 2>/dev/null
