# Daily Briefing System

## Overview
The daily briefing script generates a consolidated morning report including email summary, weather, and system health stats.

## Location
`/Users/mattsartori/.openclaw/workspace/scripts/daily-briefing.sh`

## What It Does

### 📧 Email Summary
- Checks 3 himalaya email accounts: `fuelvmhosting`, `msartori`, `fasterstack`
- Counts unread emails per account
- Lists up to 5 recent unread emails per account
- Detects and flags:
  - 🔴 Urgent emails (security alerts, payments, deadlines, etc.)
  - 👤 Emails from real people (not automated/marketing)

### 🌤️ Weather
- Gets current weather for Indianapolis from wttr.in

### 🔧 System Health
- Disk usage (%)
- Total file count in workspace
- Cron job status (checks for recent failures)

## Output Format
Plain text, optimized for Telegram (no markdown tables, uses bullet lists)

## Usage

### Manual Test
```bash
/Users/mattsartori/.openclaw/workspace/scripts/daily-briefing.sh
```

### Scheduled via Cron
To run daily at 7:00 AM Eastern, add to crontab:
```bash
0 7 * * * /Users/mattsartori/.openclaw/workspace/scripts/daily-briefing.sh
```

To deliver to Telegram via OpenClaw, wrap it:
```bash
0 7 * * * /path/to/openclaw message send --target telegram-channel "$(
/Users/mattsartori/.openclaw/workspace/scripts/daily-briefing.sh)"
```

## Performance
- Completes in ~10-20 seconds
- No API calls (uses local himalaya CLI + curl)
- Token-efficient (no LLM calls in the script itself)

## Dependencies
- `himalaya` CLI (configured with 3 accounts)
- `curl` (for weather)
- Standard Unix tools: `df`, `find`, `awk`, `grep`

## Email Detection Logic

### Urgent Keywords
Flags emails containing: urgent, important, asap, critical, action required, deadline, reminder, payment, invoice, overdue, expires, alert, security

### Automated Sender Patterns
Filters out common automated senders:
- Pattern-based: noreply, notifications, mailers, digests, newsletters
- Service-based: Instagram, Facebook, Google, GitHub, Slack, etc.

Emails that pass both filters appear as "Notable Emails" with 👤 icon.
