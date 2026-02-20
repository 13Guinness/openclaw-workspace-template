#!/bin/bash
# Screenshot cleanup script
# Deletes screenshots older than 7 days to prevent folder bloat

SCREENSHOT_DIR="$HOME/.openclaw/workspace/screenshots"
LOG_FILE="$HOME/.openclaw/workspace/logs/screenshot-cleanup.log"

# Create log directory if needed
mkdir -p "$(dirname "$LOG_FILE")"

# Count files before cleanup
BEFORE_COUNT=$(find "$SCREENSHOT_DIR" -type f -name "*.png" 2>/dev/null | wc -l)

# Delete screenshots older than 14 days
find "$SCREENSHOT_DIR" -type f -name "*.png" -mtime +14 -delete 2>/dev/null

# Count files after cleanup
AFTER_COUNT=$(find "$SCREENSHOT_DIR" -type f -name "*.png" 2>/dev/null | wc -l)
DELETED=$((BEFORE_COUNT - AFTER_COUNT))

# Log the cleanup
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
if [ $DELETED -gt 0 ]; then
    echo "$TIMESTAMP: Cleaned up $DELETED screenshots ($AFTER_COUNT remaining)" >> "$LOG_FILE"
else
    echo "$TIMESTAMP: No old screenshots to clean ($AFTER_COUNT total)" >> "$LOG_FILE"
fi

# Also enforce a max size limit (250MB) - delete oldest if exceeded
MAX_SIZE=$((250 * 1024 * 1024))  # 250MB in bytes
CURRENT_SIZE=$(du -sb "$SCREENSHOT_DIR" 2>/dev/null | cut -f1)

if [ "$CURRENT_SIZE" -gt "$MAX_SIZE" ]; then
    echo "$TIMESTAMP: Size limit exceeded ($CURRENT_SIZE bytes), deleting oldest files..." >> "$LOG_FILE"
    # Delete oldest files until under limit
    while [ "$CURRENT_SIZE" -gt "$MAX_SIZE" ]; do
        OLDEST=$(find "$SCREENSHOT_DIR" -type f -name "*.png" -printf '%T@ %p\n' 2>/dev/null | sort -n | head -1 | cut -d' ' -f2-)
        if [ -z "$OLDEST" ]; then
            break
        fi
        rm "$OLDEST"
        CURRENT_SIZE=$(du -sb "$SCREENSHOT_DIR" 2>/dev/null | cut -f1)
    done
    echo "$TIMESTAMP: Cleanup complete, new size: $CURRENT_SIZE bytes" >> "$LOG_FILE"
fi
