#!/bin/bash
# recovery-kit-update.sh — Daily snapshot of system state for disaster recovery
set -euo pipefail

WORKSPACE="$HOME/.openclaw/workspace"
RECOVERY="$WORKSPACE/recovery-kit"

mkdir -p "$RECOVERY"

# Snapshot installed packages
brew list --formula > "$RECOVERY/brew-packages.txt" 2>/dev/null || true
brew list --cask > "$RECOVERY/brew-casks.txt" 2>/dev/null || true
npm list -g --depth=0 > "$RECOVERY/npm-global.txt" 2>/dev/null || true
openclaw --version > "$RECOVERY/openclaw-version.txt" 2>/dev/null || true

# Snapshot system info
sw_vers > "$RECOVERY/macos-version.txt" 2>/dev/null || true
node -v > "$RECOVERY/node-version.txt" 2>/dev/null || true

# Snapshot LaunchAgents
ls ~/Library/LaunchAgents/ > "$RECOVERY/launchagents.txt" 2>/dev/null || true

# Timestamp
date -u > "$RECOVERY/last-updated.txt"

echo "Recovery kit updated at $(date)"
