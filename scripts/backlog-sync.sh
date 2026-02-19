#!/bin/bash
# Syncs BACKLOG.md into Mission Control tasks.jsonl
# Parses markdown sections into structured tasks

BACKLOG="$HOME/.openclaw/workspace/BACKLOG.md"
TASKS_FILE="$HOME/.openclaw/mission-control-sessions/tasks.jsonl"
LOG="$HOME/.openclaw/workspace/logs/backlog-sync.log"
mkdir -p "$(dirname "$TASKS_FILE")" "$(dirname "$LOG")"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Read BACKLOG.md and parse sections
if [ ! -f "$BACKLOG" ]; then
    echo "$TIMESTAMP: BACKLOG.md not found, skipping" >> "$LOG"
    exit 0
fi

# Build JSON tasks from BACKLOG.md
python3 - << 'PYEOF'
import json, re, os, uuid
from datetime import datetime, timezone

backlog_path = os.path.expanduser("~/.openclaw/workspace/BACKLOG.md")
tasks_path = os.path.expanduser("~/.openclaw/mission-control-sessions/tasks.jsonl")

with open(backlog_path, "r") as f:
    content = f.read()

# Load existing non-backlog tasks (preserve kanban cards not from BACKLOG.md)
existing_tasks = []
if os.path.exists(tasks_path):
    with open(tasks_path, "r") as f:
        seen_ids = set()
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                task = json.loads(line)
                # Only keep tasks NOT sourced from backlog sync (no source field or source != "backlog")
                if task.get("source") != "backlog" and task["id"] not in seen_ids:
                    existing_tasks.append(task)
                    seen_ids.add(task["id"])
            except:
                pass

now = datetime.now(timezone.utc).isoformat()
new_tasks = []

# Section → status mapping
status_map = {
    "Active": "in_progress",
    "Blocked/Issues": "backlog",
    "Queued": "backlog",
    "Done": "done",
}

# Priority detection from keywords
def get_priority(text):
    text_lower = text.lower()
    if any(w in text_lower for w in ["critical", "urgent", "broken", "blocked", "auth"]):
        return "urgent"
    if any(w in text_lower for w in ["high", "important", "fix", "bug"]):
        return "high"
    if any(w in text_lower for w in ["medium", "moderate"]):
        return "medium"
    return "low"

# Parse sections
current_section = None
current_title = None
current_desc_lines = []
current_project = None

lines = content.split("\n")
i = 0
while i < len(lines):
    line = lines[i]

    # Section header (##)
    if line.startswith("## "):
        # Save previous task if any
        if current_title and current_section:
            status = status_map.get(current_section, "backlog")
            desc = " ".join(current_desc_lines).strip()
            task = {
                "id": str(uuid.uuid5(uuid.NAMESPACE_DNS, f"backlog:{current_title}")),
                "title": current_title,
                "description": desc[:500] if desc else "",
                "assigned_to": "Matt",
                "priority": get_priority(current_title + " " + desc),
                "status": status,
                "project": current_project or "Backlog",
                "source": "backlog",
                "created_at": now,
                "updated_at": now,
            }
            new_tasks.append(task)
        current_section = line[3:].strip().split("—")[0].strip()
        current_title = None
        current_desc_lines = []
        current_project = None

    # Task header (###)
    elif line.startswith("### "):
        # Save previous task
        if current_title and current_section:
            status = status_map.get(current_section, "backlog")
            desc = " ".join(current_desc_lines).strip()
            task = {
                "id": str(uuid.uuid5(uuid.NAMESPACE_DNS, f"backlog:{current_title}")),
                "title": current_title,
                "description": desc[:500] if desc else "",
                "assigned_to": "Matt",
                "priority": get_priority(current_title + " " + desc),
                "status": status,
                "project": current_project or "Backlog",
                "source": "backlog",
                "created_at": now,
                "updated_at": now,
            }
            new_tasks.append(task)

        parts = line[4:].strip().split(" — ")
        current_title = parts[0].strip()
        current_project = current_title.split(" - ")[0].split(" —")[0]
        current_desc_lines = []

    # Status line
    elif line.startswith("**Status:**"):
        pass  # Skip, we derive status from section

    # Content lines
    elif current_title and line.strip() and not line.startswith("- ["):
        clean = re.sub(r'\*\*|`', '', line).strip()
        if clean and not clean.startswith("#"):
            current_desc_lines.append(clean)

    i += 1

# Save final task
if current_title and current_section:
    status = status_map.get(current_section, "backlog")
    desc = " ".join(current_desc_lines).strip()
    task = {
        "id": str(uuid.uuid5(uuid.NAMESPACE_DNS, f"backlog:{current_title}")),
        "title": current_title,
        "description": desc[:500] if desc else "",
        "assigned_to": "Matt",
        "priority": get_priority(current_title + " " + desc),
        "status": status,
        "project": current_project or "Backlog",
        "source": "backlog",
        "created_at": now,
        "updated_at": now,
    }
    new_tasks.append(task)

# Write combined tasks (existing non-backlog + new backlog tasks)
all_tasks = existing_tasks + new_tasks
with open(tasks_path, "w") as f:
    for task in all_tasks:
        f.write(json.dumps(task) + "\n")

print(f"Synced {len(new_tasks)} backlog tasks ({len(existing_tasks)} existing tasks preserved)")
PYEOF

echo "$TIMESTAMP: Backlog sync complete" >> "$LOG"
