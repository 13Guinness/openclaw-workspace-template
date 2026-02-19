---
name: wayback-restorer
description: "Wayback Rehydrator — Restore archived websites from Wayback Machine with shareable links. Use when: (1) restoring old websites, (2) preserving deleted sites, (3) creating shareable archive copies, (4) working on rehydrator features."
metadata:
  {
    "openclaw":
      {
        "emoji": "🕰️",
        "kind": "skill-graph",
      },
  }
---

# Wayback Rehydrator Skill

> **This is a skill graph.** Start at [[index]].

## Quick Start

Read [[index]] — explains restoration process and architecture.

## When to Use

✅ **USE when:**
- Restoring archived websites
- Creating shareable archive copies
- Preserving deleted sites
- Research/citation needs
- Portfolio preservation

❌ **DON'T use when:**
- Sites with backends (PHP, databases)
- Private/paywalled content
- Real-time/dynamic features

## Process

1. Enter URL + snapshot date
2. Inngest background job crawls
3. Downloads HTML + assets
4. Rewrites URLs
5. Uploads to Vercel Blob
6. Returns shareable link

## Tech Stack

- Next.js 14
- Vercel (Postgres, Blob)
- Inngest (background jobs)

## Development Paths

- **Repo:** `13Guinness/wayback-restorer`
- **Local:** `~/.openclaw/workspace/wayback-restorer/`

---

**Start here:** [[index]]
