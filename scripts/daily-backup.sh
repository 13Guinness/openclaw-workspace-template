#!/bin/bash
# Daily backup of critical databases and config to iCloud
# Run via cron: 0 2 * * * /Users/mattsartori/.openclaw/workspace/scripts/daily-backup.sh

set -e

BACKUP_DIR="/Users/mattsartori/Library/Mobile Documents/com~apple~CloudDocs/Backups/OpenClaw"
WORKSPACE="/Users/mattsartori/.openclaw/workspace"
DATE=$(date +%Y-%m-%d)

# Create backup directory
mkdir -p "$BACKUP_DIR/databases/$DATE"
mkdir -p "$BACKUP_DIR/secrets/$DATE"
mkdir -p "$BACKUP_DIR/memory/$DATE"

echo "[$(date)] Starting backup..."

# Find and backup all SQLite databases
find "$WORKSPACE" -name "*.db" -o -name "*.sqlite" -o -name "*.sqlite3" 2>/dev/null | while read db; do
    if [ -f "$db" ]; then
        cp "$db" "$BACKUP_DIR/databases/$DATE/"
        echo "  Backed up: $db"
    fi
done

# Backup environment files
find "$WORKSPACE" -name ".env*" -type f 2>/dev/null | while read env; do
    cp "$env" "$BACKUP_DIR/secrets/$DATE/"
    echo "  Backed up: $env"
done

# Backup memory files (knowledge graph, facts, constraints)
cp -r "$WORKSPACE/memory" "$BACKUP_DIR/memory/$DATE/" 2>/dev/null || true

# Backup claude-mem databases if they exist
if [ -d "$WORKSPACE/.claude-mem" ]; then
    mkdir -p "$BACKUP_DIR/claude-mem/$DATE"
    cp -r "$WORKSPACE/.claude-mem" "$BACKUP_DIR/claude-mem/$DATE/"
    echo "  Backed up: claude-mem"
fi

# Cleanup backups older than 30 days
find "$BACKUP_DIR" -type d -mtime +30 -exec rm -rf {} + 2>/dev/null || true

echo "[$(date)] Backup complete: $BACKUP_DIR"
