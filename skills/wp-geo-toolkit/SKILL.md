---
name: wp-geo-toolkit
description: "WP Geo Toolkit — AI-powered WordPress platform for generating and transforming location-based content at scale. Use when: (1) building multi-location WordPress sites, (2) generating SEO-optimized location pages, (3) transforming content between locations, (4) working with local SEO. Core plugin + add-ons architecture."
metadata:
  {
    "openclaw":
      {
        "emoji": "🗺️",
        "kind": "skill-graph",
      },
  }
---

# WP Geo Toolkit Skill

> **This is a skill graph.** Start at [[index]] for the overview, then follow wikilinks to the concepts you need.

## Quick Start

Read [[index]] first — it's the hub that connects everything.

## When to Use This Skill

✅ **USE when:**
- Building multi-location WordPress sites
- Generating location-specific landing pages
- Transforming content from one location to another
- Working with local SEO optimization
- Scaling content creation for franchises/multi-location businesses

❌ **DON'T use when:**
- Single-location websites
- Generic (non-location) content
- Non-WordPress platforms
- Manual content writing is preferred

## How This Skill Is Organized

This is a **skill graph**, not a monolithic guide. Navigate through wikilinks:

### Entry Point
- [[index]] — Start here for architecture overview

### Core Services
- [[claude-ai-integration]] — AI content generation
- [[geocoding-service]] — Location → coordinates
- [[proximity-calculator]] — Distance calculations
- [[addon-manager]] — Extensibility framework

### Add-ons
- [[location-pages-generator]] — Create new location pages
- [[content-transformer]] — Transform existing content

### Key Concepts
- [[geographic-transformation]] — How AI handles location rewrites
- [[location-data-structure]] — WordPress metadata schema
- [[ai-rewrite-levels]] — Control content variation

### Practical Guides
- [[installation-setup]] — Getting started
- [[performance-costs]] — API costs, processing time
- [[troubleshooting]] — Common errors and fixes
- [[custom-addon-development]] — Building your own add-ons

## Navigation Pattern

1. **Start broad:** [[index]] gives you the landscape
2. **Follow your need:** Click wikilinks relevant to your task
3. **Dive deep:** Each node is self-contained but links to related concepts
4. **Skip irrelevant:** Don't load what you don't need

## GitHub Repositories

- **Core:** `13Guinness/wp-geo-toolkit`
- **Location Pages:** `13Guinness/wpgt-location-pages`
- **Content Transformer:** `13Guinness/wpgt-content-transformer`

## Local Development Paths

- **Repos:** `~/.openclaw/workspace/wp-geo-toolkit/`, `wpgt-location-pages/`, `wpgt-content-transformer/`
- **WordPress plugins:** `~/Local Sites/fvmoc001-wordpress/app/public/wp-content/plugins/`
- **Local by Flywheel:** `~/Local Sites/fvmoc001-wordpress/`

## Technical Requirements

- WordPress 6.0+
- PHP 7.4+ (8.0+ recommended)
- Claude API key (Anthropic)
- Google Geocoding API key (optional, recommended)

## Working with This Skill

### For New Projects

Start at [[index]] → [[installation-setup]] → choose your add-on.

### For Existing Sites

Start at [[index]] → [[content-transformer]] if adapting existing content, or [[location-pages-generator]] if creating new pages.

### For Troubleshooting

[[troubleshooting]] covers common errors. If geocoding fails, see [[geocoding-service]]. If AI output is wrong, check [[ai-rewrite-levels]].

### For Custom Development

[[custom-addon-development]] explains the platform architecture and how to build your own add-ons using core services.

## Philosophy

This skill uses **progressive disclosure** — you load only what you need:

- **YAML frontmatter** lets you scan without reading
- **Wikilinks** guide you to related concepts
- **Focused nodes** keep each file digestible
- **Cross-references** show relationships

Instead of one massive SKILL.md file, you navigate a knowledge graph.

## Support

- **Code:** See GitHub repos above
- **Concepts:** Follow wikilinks from [[index]]
- **Issues:** Check [[troubleshooting]] first

---

**Start here:** [[index]]
