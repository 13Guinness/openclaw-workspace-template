#!/bin/bash
# Platform Health Council - OpenClaw System Health Check
# Reports system health metrics in Telegram-friendly format

set -euo pipefail

# Colors/Emojis
GOOD="💚"
WARN="⚠️"
CHECK="✅"
ISSUE="❌"

# Track issues
ISSUES=()

echo "🏥 Platform Health Report"
echo ""

# ============================================================================
# 1. CRON JOB HEALTH
# ============================================================================
CRON_STATUS="$GOOD All healthy"
CRON_ERRORS=0

if [[ -d "$HOME/.openclaw/logs" ]]; then
    # Check gateway logs for recent cron errors (last 24h)
    CUTOFF=$(date -v-24H +%s 2>/dev/null || date -d '24 hours ago' +%s 2>/dev/null || echo 0)
    
    # Look for error patterns in recent logs
    if compgen -G "$HOME/.openclaw/logs/gateway-*.log" > /dev/null; then
        while IFS= read -r logfile; do
            # Skip if file is older than 24h
            if [[ -f "$logfile" ]]; then
                FILE_TIME=$(stat -f %m "$logfile" 2>/dev/null || stat -c %Y "$logfile" 2>/dev/null || echo 0)
                if [[ $FILE_TIME -gt $CUTOFF ]]; then
                    # Count error lines
                    ERRORS=$(grep -ci "error\|failed\|exception" "$logfile" 2>/dev/null || echo 0)
                    CRON_ERRORS=$((CRON_ERRORS + ERRORS))
                fi
            fi
        done < <(find "$HOME/.openclaw/logs" -name "gateway-*.log" -mtime -1 2>/dev/null || true)
    fi
    
    if [[ $CRON_ERRORS -gt 0 ]]; then
        CRON_STATUS="$WARN $CRON_ERRORS errors in last 24h"
        ISSUES+=("Cron logs show $CRON_ERRORS errors")
    fi
else
    CRON_STATUS="$WARN No logs directory"
fi

echo "💚 Cron Jobs: $CRON_STATUS"

# ============================================================================
# 2. DISK SPACE
# ============================================================================
# Root disk usage
ROOT_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
ROOT_FREE=$(df -h / | awk 'NR==2 {print $4}')
DISK_STATUS="$ROOT_USAGE% used ($ROOT_FREE free)"

if [[ $ROOT_USAGE -gt 80 ]]; then
    DISK_STATUS="$WARN $DISK_STATUS"
    ISSUES+=("Root disk usage over 80%")
else
    DISK_STATUS="$GOOD $DISK_STATUS"
fi

echo "💾 Disk: $DISK_STATUS"

# OpenClaw directory size
if [[ -d "$HOME/.openclaw" ]]; then
    OPENCLAW_SIZE=$(du -sh "$HOME/.openclaw" 2>/dev/null | awk '{print $1}')
    echo "📂 OpenClaw: $OPENCLAW_SIZE"
fi

# Workspace size
WORKSPACE_SIZE=$(du -sh "$HOME/.openclaw/workspace" 2>/dev/null | awk '{print $1}')
echo "📂 Workspace: $WORKSPACE_SIZE"

# Check for large directories (>1GB) in workspace
if [[ -d "$HOME/.openclaw/workspace" ]]; then
    while IFS= read -r line; do
        SIZE=$(echo "$line" | awk '{print $1}')
        DIR=$(echo "$line" | awk '{print $2}')
        # Convert to MB for comparison (rough)
        if [[ "$SIZE" =~ ^[0-9.]+G$ ]]; then
            ISSUES+=("Large directory: $(basename "$DIR") is $SIZE")
        fi
    done < <(du -sh "$HOME/.openclaw/workspace"/*/ 2>/dev/null | grep -E "^[0-9.]+G" || true)
fi

# ============================================================================
# 3. PROCESS HEALTH
# ============================================================================
# Gateway process
GATEWAY_PID=$(ps aux | grep "openclaw-gateway" | grep -v grep | awk "{print \$2}" | head -1 || echo "")
if [[ -n "$GATEWAY_PID" ]]; then
    GATEWAY_STATUS="Running (PID $GATEWAY_PID)"
else
    GATEWAY_STATUS="$WARN Not running"
    ISSUES+=("OpenClaw gateway is not running")
fi
echo "⚙️  Gateway: $GATEWAY_STATUS"

# Check for zombie processes
ZOMBIE_COUNT=$(ps aux | grep -i "openclaw\|exec" | grep "<defunct>" | grep -v grep | wc -l 2>/dev/null || true)
ZOMBIES=${ZOMBIE_COUNT:-0}
ZOMBIES=$(echo "$ZOMBIES" | tr -d ' \n')
if [[ $ZOMBIES -gt 0 ]]; then
    ISSUES+=("$ZOMBIES zombie processes detected")
fi

# Memory usage (macOS)
if command -v vm_stat &>/dev/null; then
    # macOS memory calculation
    PAGE_SIZE=$(pagesize)
    VM_STAT=$(vm_stat)
    
    PAGES_FREE=$(echo "$VM_STAT" | awk '/Pages free/ {print $3}' | tr -d '.')
    PAGES_ACTIVE=$(echo "$VM_STAT" | awk '/Pages active/ {print $3}' | tr -d '.')
    PAGES_INACTIVE=$(echo "$VM_STAT" | awk '/Pages inactive/ {print $3}' | tr -d '.')
    PAGES_WIRED=$(echo "$VM_STAT" | awk '/Pages wired down/ {print $4}' | tr -d '.')
    
    USED_PAGES=$((PAGES_ACTIVE + PAGES_INACTIVE + PAGES_WIRED))
    TOTAL_PAGES=$((USED_PAGES + PAGES_FREE))
    
    USED_GB=$(echo "scale=1; $USED_PAGES * $PAGE_SIZE / 1073741824" | bc)
    TOTAL_GB=$(echo "scale=1; $TOTAL_PAGES * $PAGE_SIZE / 1073741824" | bc)
    
    echo "🧠 Memory: ${USED_GB}GB / ${TOTAL_GB}GB used"
else
    # Linux fallback
    if command -v free &>/dev/null; then
        MEM_INFO=$(free -g | awk '/Mem:/ {printf "%sGB / %sGB used", $3, $2}')
        echo "🧠 Memory: $MEM_INFO"
    fi
fi

# ============================================================================
# 4. GIT STATUS
# ============================================================================
cd "$HOME/.openclaw/workspace" 2>/dev/null || {
    echo "🔄 Git: $WARN Workspace not found"
    ISSUES+=("Workspace directory not accessible")
    exit 1
}

if [[ -d .git ]]; then
    # Check uncommitted changes
    UNCOMMITTED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    
    # Check if behind remote (safely)
    git fetch --quiet 2>/dev/null || true
    BEHIND=$(git rev-list HEAD..@{u} 2>/dev/null | wc -l | tr -d ' ' || echo 0)
    
    GIT_STATUS="Clean"
    GIT_ISSUES=()
    
    if [[ $UNCOMMITTED -gt 0 ]]; then
        GIT_ISSUES+=("$UNCOMMITTED uncommitted files")
    fi
    
    if [[ $BEHIND -gt 0 ]]; then
        GIT_ISSUES+=("$BEHIND commits behind")
    fi
    
    if [[ ${#GIT_ISSUES[@]} -gt 0 ]]; then
        GIT_STATUS="$WARN ${GIT_ISSUES[*]}"
        ISSUES+=("Git: ${GIT_ISSUES[*]}")
    else
        GIT_STATUS="$GOOD Clean"
    fi
    
    echo "🔄 Git: $GIT_STATUS"
else
    echo "🔄 Git: $WARN Not a git repository"
fi

# ============================================================================
# 5. SCRIPT INTEGRITY
# ============================================================================
SCRIPT_ISSUES=()

# Check scripts are executable
if [[ -d "$HOME/.openclaw/workspace/scripts" ]]; then
    while IFS= read -r script; do
        if [[ ! -x "$script" ]]; then
            SCRIPT_ISSUES+=("$(basename "$script") not executable")
            ISSUES+=("Script not executable: $(basename "$script")")
        fi
    done < <(find "$HOME/.openclaw/workspace/scripts" -type f -name "*.sh" 2>/dev/null || true)
fi

# Check himalaya config
if [[ -f "$HOME/.config/himalaya/config.toml" ]]; then
    # Basic validation - check if it's readable and has accounts section
    if ! grep -q "\[accounts\]" "$HOME/.config/himalaya/config.toml" 2>/dev/null; then
        SCRIPT_ISSUES+=("himalaya config invalid")
        ISSUES+=("Himalaya config missing [accounts] section")
    fi
else
    SCRIPT_ISSUES+=("himalaya config missing")
    ISSUES+=("Himalaya config not found")
fi

if [[ ${#SCRIPT_ISSUES[@]} -eq 0 ]]; then
    echo "🔧 Scripts: $GOOD All valid"
else
    echo "🔧 Scripts: $WARN ${#SCRIPT_ISSUES[@]} issues"
fi

# ============================================================================
# SUMMARY
# ============================================================================
echo ""

if [[ ${#ISSUES[@]} -gt 0 ]]; then
    echo "Issues Found:"
    for issue in "${ISSUES[@]}"; do
        echo "• $issue"
    done
else
    echo "$CHECK All systems healthy"
fi
