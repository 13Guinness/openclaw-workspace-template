---
description: WP Geo Toolkit — AI-powered WordPress platform for generating and transforming location-based content at scale. Core plugin + add-ons architecture for multi-location businesses.
kind: skill-graph
topics: ["[[wordpress]]", "[[ai-content]]", "[[local-seo]]"]
---

# WP Geo Toolkit

WordPress plugin platform that uses AI (Claude Sonnet 4) to generate and transform location-based content at scale.

## Problem & Solution

**Problem:** Multi-location businesses face:
- Manual writing: 2-4 hours/page, $50-200 each
- Find/replace creates duplicate content → SEO penalties
- Content spinners produce gibberish
- Scaling to 50+ locations = months of work

**Solution:** WP Geo Toolkit
- Generates unique content: ~1 min/page
- Cost: ~$0.015/page (Claude AI)
- Natural language quality
- Scales effortlessly

**Example ROI:**
- Traditional: 100 pages × 2 hours = 200 hours + $10K
- WP Geo Toolkit: 100 pages × 1 min = 2 hours + $1.50

## Architecture

### Core + Add-ons Platform

```
wp-geo-toolkit (core)
├── Claude AI integration
├── Geocoding services
├── Proximity calculations
├── Settings management
└── WP Engine cache clearing

Add-ons (extend core)
├── wpgt-location-pages → Generate new location pages
└── wpgt-content-transformer → Transform existing content
```

**Why modular:**
- Install only what you need
- Update APIs once, all add-ons benefit
- Easy custom add-ons
- Single-purpose modules

## Core Components

### [[claude-ai-integration]]
Interface to Anthropic Claude Sonnet 4 for content generation. Handles retries, rate limits, JSON parsing, validation.

### [[geocoding-service]]
Converts "City, State" → coordinates + location data. Google API (primary), built-in fallback, 1-hour cache.

### [[proximity-calculator]]
Calculates distances using Haversine formula. For service areas, nearest location features, overlap detection.

### [[addon-manager]]
Dynamic registration, version checking, admin integration, settings management.

### [[wp-engine-cache-clearing]]
Meta box in post/page editor for one-click cache clearing. WP Engine only.

## Add-ons

### [[location-pages-generator]]
Creates new location-specific pages from template. For franchises, service providers entering new markets.

### [[content-transformer]]
Transforms existing content from one location to another. In-place updates, preserves URLs.

## Key Concepts

### [[geographic-transformation]]
Rewriting content to reference different location while maintaining natural language. AI handles nuance that find/replace can't.

### [[location-data-structure]]
Every page stores: location string, city, state, county, coordinates. Enables queries, sorting, SEO, service calculations.

### [[ai-rewrite-levels]]
- Low (10-20%): Minimal changes
- Medium (40-60%): Balanced (recommended)
- High (80-90%): Maximum uniqueness

## Technical Details

### [[installation-setup]]
Prerequisites, steps, configuration, API keys.

### [[performance-costs]]
API pricing, processing time, hosting requirements.

### [[security]]
API key storage, admin access, nonce verification, sanitization.

### [[troubleshooting]]
Common errors, fixes, debug strategies.

### [[custom-addon-development]]
How to build your own add-ons using core services.

## GitHub Repos

- Core: `13Guinness/wp-geo-toolkit`
- Location Pages: `13Guinness/wpgt-location-pages`
- Content Transformer: `13Guinness/wpgt-content-transformer`

## Local Development

- Repos cloned to: `~/.openclaw/workspace/wp-geo-toolkit`, `wpgt-location-pages`, `wpgt-content-transformer`
- Local WordPress: `~/Local Sites/fvmoc001-wordpress/app/public/wp-content/plugins/`

---

**Topics:**
- [[wordpress]]
- [[ai-content]]
- [[local-seo]]
- [[claude-api]]
