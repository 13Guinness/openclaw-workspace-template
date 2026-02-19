# OpenClaw Clone Kit

Complete, PII-free OpenClaw workspace template for deploying to new Mac minis.

## Quick Start

**Before you start:** [API_KEYS.md](API_KEYS.md) — Create accounts and get API keys

**Choose your setup method:**
- **[MANUAL_SETUP.md](MANUAL_SETUP.md)** ← **Start here if you're not technical**
  - Uses only Finder and TextEdit
  - No command line required
  - Step-by-step with screenshots implied

- **[DEPLOY.md](DEPLOY.md)** — For technical users
  - One-command automated setup
  - Requires Terminal
  - Faster if you're comfortable with command line

## What's Included

| File/Folder | Purpose |
|-------------|---------|
| `setup.sh` | Main setup script — installs OpenClaw, configures everything |
| `post-setup.sh` | **Run after setup.sh** — creates cron jobs, configures extensions |
| `config-template.json` | OpenClaw configuration template with placeholders |
| `DEPLOY.md` | Complete deployment guide (Terminal-based) |
| `MANUAL_SETUP.md` | Complete deployment guide (GUI-based, no Terminal) |
| `API_KEYS.md` | How to get all required API keys |
| `README.md` | This file — quick reference |
| `SYSTEM-GUIDE.md` | Troubleshooting guide and command reference |
| `EXTENSIONS_AND_SKILLS.md` | How to install extensions and recommended skills |

### Templates (`template/`)
- `AGENTS.md` — How the agent should behave, memory architecture
- `SOUL.md` — Personality, humor style, boundaries
- `USER.md` — Human's info (name, timezone, preferences)
- `IDENTITY.md` — Agent name, emoji, avatar
- `TOOLS.md` — Local tool notes (SSH hosts, device names)
- `HEARTBEAT.md` — Periodic check instructions
- `MEMORY.md` — Curated long-term memory index
- `BACKLOG.md` — Shelved issues and quick wins
- `SYSTEM-GUIDE.md` — Troubleshooting guide for users
- `memory/facts.md` — Atomic durable facts (infrastructure, preferences)
- `memory/constraints.md` — Hard-won rules from failures
- `memory/episodes.md` — Event log for significant happenings
- `memory/daily-log-template.md` — Template for memory/YYYY-MM-DD.md

### Scripts (`scripts/`)
- `daily-backup.sh` — Backs up databases, env files, memory to iCloud (2am daily)
- `daily-briefing.sh` — Morning briefing (weather, email, system health)
- `urgent-email-check.sh` — Scans for urgent emails every 30min

### Skill System
- `skill-template.yaml` — Template for creating new skills
- `skills-examples/` — Example skills:
  - `email-classifier.yaml` — Classification task with prompt repetition
  - `code-reviewer.yaml` — Reasoning task (no repetition)
  - `date-extractor.yaml` — Extraction task with prompt repetition

### Examples (`examples/`)
- `mission-control-launchagent.plist` — LaunchAgent for persistent dev servers

### Documentation (`docs/`)
- `IMAGE_GENERATION.md` — How to use Nano Banana Pro for AI image generation
- `AUTOMATION_AUDIT.md` — Comprehensive life audit system to identify automation opportunities

## First-Time User Onboarding

After installation, new users can onboard via:

**Option A: Bash Script (Quick)**
```bash
./scripts/first-steps-onboarding.sh
```
Interactive questionnaire → 3 simple automation suggestions → immediate setup

**Option B: Agent Conversation (Conversational)**
Just tell your agent: "Let's get started" or "Onboard me"

The agent will ask questions, suggest automations, and set everything up via chat.

See `docs/AGENT_ONBOARDING.md` for the full conversation flow.

## Before You Deploy

1. **Get API keys ready:**
   - Anthropic API key (required — primary model)
   - OpenRouter API key (required — fallback routing)
   - OpenAI API key (required — memory search embeddings)
   - Telegram bot token (required)
   - Discord bot token (optional)
   - Gemini API key (optional, for image generation)
   - Brave Search API key (optional, for web search)

2. **Prepare the Mac mini:**
   - Install Homebrew: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
   - Install Node.js: `brew install node`

3. **Copy this kit to the new Mac**

4. **Run setup:** `./setup.sh` (prompts for all keys interactively)

5. **Customize:** Edit IDENTITY.md, USER.md, SOUL.md

6. **Start:** `openclaw gateway start`

See DEPLOY.md for the full walkthrough with troubleshooting.

## Optional Post-Setup

### claude-mem Plugin (Recommended)

Persistent vector memory that stores observations across sessions and enables semantic recall:

```bash
openclaw plugin install claude-mem
openclaw plugin list  # verify it's running
```

claude-mem pairs with OpenAI memory search for a two-tier memory architecture:
- **OpenAI embeddings** — semantic search over workspace files
- **claude-mem** — structured observation log with MCP tools (`memory_search`, `get_observations`)

### Mission Control App

Personal operations dashboard with 6 modules: Tasks (kanban), Memory (file browser), Content (pipeline), Calendar (weekly view + cron tracking), Office (workspace mgmt), Team (collaboration).

```bash
# After setup, deploy Mission Control:
cd ~/.openclaw/workspace/[agent-name]/projects/mission-control
npm install
npm run dev  # runs on http://localhost:3000
```

See `docs/MISSION_CONTROL.md` for full setup and configuration.

## What's NOT Included (Intentionally)

- API keys / tokens (use your own)
- Personal memory files
- Client-specific projects
- Node pairing data

## Migrating Projects Later

Projects are portable folders. Just copy them into the workspace:
```bash
scp -r elon/projects/breakdance-generator user@new-mac:/path/to/workspace/projects/
```

## Updates to This Kit

Last updated: 2026-02-19

### Recent Changes
- **Model stack updated:** primary=anthropic/claude-sonnet-4-6 (direct), fallbacks: kimi-k2.5 → sonnet-4.6 (OpenRouter) → gemini-flash
- **Memory search:** provider=openai, model=text-embedding-3-small (enabled by default)
- **claude-mem plugin:** added as optional post-setup install (vector memory)
- **Mission Control:** added as optional post-setup app to deploy
- **setup.sh:** now prompts interactively for all keys (Anthropic, OpenRouter, OpenAI, Gemini, Brave Search, Telegram, Discord)
- **template/openclaw-template.json:** new canonical config template with full model stack + memory search config
- Updated constraints.md with latest hard-won rules (anti-loop, cost control, credential safety)
- Updated facts.md template with current model tier structure

## Scripts Included

The following scripts run locally (no LLM tokens):
- `daily-briefing.sh` — Morning briefing (email, weather, system health)
- `urgent-email-check.sh` — Scans for urgent emails via pattern matching
- `watchdog.sh` — Keeps the gateway running

After setup, run `./setup-crons.sh` for instructions on setting up automated jobs.

---

Happy clawing! 🦞
