---
description: Local SEO Autopilot — WordPress plugin for comprehensive SEO auditing and optimization. 5 AI-powered modules analyze competitors, schema markup, GBP posts, content gaps, and local keywords. Uses Claude Sonnet 4.
kind: skill-graph
topics: ["[[wordpress]]", "[[seo]]", "[[local-seo]]", "[[claude-api]]"]
---

# Local SEO Autopilot

WordPress plugin for AI-powered local SEO auditing and content generation.

## Purpose

**Problem:** Local SEO audits are manual, time-consuming, and require expensive tools or consultants.

**Solution:** All-in-one WordPress plugin that:
- Audits your site vs. competitors
- Analyzes and generates schema markup
- Creates Google Business Profile posts
- Identifies content gaps
- Discovers local keywords

## The 5 Modules

### 1. [[competitive-intelligence]]
**Analyze your site vs. 3 competitors**

Compare:
- Content quality and depth
- Schema markup implementation
- Local keyword usage
- On-page SEO factors
- Technical SEO scores

Output: Detailed competitive analysis report with AI recommendations.

### 2. [[schema-audit]]
**Detect, grade, and generate schema markup**

Features:
- Scan existing schema on your site
- Grade schema quality (A-F)
- Identify missing schema types
- Generate LocalBusiness, Service, FAQ schema
- One-click implementation

Why: Schema markup improves local search visibility and rich snippets.

### 3. [[gbp-post-generator]]
**AI-powered Google Business Profile posts**

Create optimized GBP posts:
- Event announcements
- Offer/promotion posts
- What's New updates
- Product showcases

Claude AI writes natural, engaging posts with:
- Local keywords
- Call-to-actions
- Optimal length (100-300 words)
- Hashtag suggestions

### 4. [[content-gap-analyzer]]
**Find missing topics and content opportunities**

Discovers:
- Questions competitors answer (you don't)
- Missing service pages
- Untapped long-tail keywords
- Location-specific content gaps

Output: Prioritized list of content to create for competitive advantage.

### 5. [[local-keyword-hunter]]
**Discover high-intent local keywords**

Finds:
- "[service] near me" variations
- "[service] in [city]" opportunities
- Long-tail local queries
- Question-based keywords

Includes:
- Search volume estimates
- Difficulty scores
- Priority rankings

## Architecture

### WordPress Integration
- Admin dashboard pages (7 total)
- Settings page for API key + business info
- Results storage in custom database table
- AJAX for real-time analysis

### [[claude-integration]]
Uses Anthropic Claude Sonnet 4 for:
- Competitive analysis
- Schema generation
- GBP post writing
- Content gap identification
- Keyword research

API cost: ~$0.01-0.05 per analysis.

### Security
- [[security-features]] — Enterprise-grade hardening
- API key encryption (AES-256-CBC)
- Rate limiting on all operations
- Nonce verification (CSRF protection)
- SQL injection prevention
- XSS protection
- Capability checks (`manage_options`)

## Key Features

### Real-Time Analysis
- AJAX-powered UI
- Progress indicators
- Streaming results
- Error handling

### Results Storage
Custom database table stores:
- Analysis results
- Generated schema
- GBP posts
- Historical data

Query results later without re-running analysis.

### Settings Management
Configure once:
- Claude API key (encrypted)
- Business name
- Business address
- Primary service area
- Target keywords

## Use Cases

### Monthly SEO Audit
1. Run Competitive Intelligence
2. Review competitor advantages
3. Run Schema Audit
4. Fix missing schema
5. Check Content Gaps
6. Plan content calendar

### GBP Content Creation
1. Open GBP Post Generator
2. Select post type (event/offer/update)
3. AI generates 3-5 options
4. Edit and publish to GBP

### New Site Setup
1. Configure settings (business info)
2. Run all 5 modules
3. Get comprehensive baseline
4. Implement recommendations
5. Track improvements monthly

## Installation & Setup

### Requirements
- WordPress 5.8+
- PHP 7.4+
- Claude API key (Anthropic)

### Setup Steps
1. Upload plugin to `/wp-content/plugins/local-seo-autopilot/`
2. Activate plugin
3. Navigate to **Local SEO → Settings**
4. Enter Claude API key
5. Fill business information
6. Save settings
7. Run first audit

### API Key Setup
1. Get key from [console.anthropic.com](https://console.anthropic.com)
2. Must start with `sk-ant-`
3. Plugin encrypts before storage
4. Never stored in plain text

## Version History

### v1.0.2 (2026-01-31) — CRITICAL UPDATE
**Fixed:** API key encryption bug
- Keys entered in v1.0.0-1.0.1 were NOT encrypted
- v1.0.2 fixes encryption
- Re-enter API key after updating

### v1.0.1 (2026-01-31)
- Updated author information

### v1.0.0 (2026-01-31)
- Initial release
- All 5 modules
- Enterprise security hardening

## Technical Stack

- **WordPress:** 5.8+ compatible
- **PHP:** 7.4+ required
- **AI:** Claude Sonnet 4 API
- **Database:** Custom table for results
- **Security:** OWASP Top 10 protection
- **UI:** WordPress admin standards

## Code Location

- Repo: `13Guinness/local-seo-autopilot`
- Local: `~/.openclaw/workspace/local-seo-autopilot/`
- WordPress: `~/Local Sites/fvmoc001-wordpress/app/public/wp-content/plugins/`

## Related

- [[wp-geo-toolkit]] — Location content generation
- [[claude-integration]] — AI API patterns
- [[wordpress-security]] — Security best practices
- [[local-seo]] — SEO strategies

---

**Topics:**
- [[wordpress]]
- [[seo]]
- [[local-seo]]
- [[claude-api]]
- [[ai-content]]
