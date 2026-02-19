---
description: FVM AI Meta Assistant — WordPress Gutenberg sidebar plugin for AI-powered meta title and description generation. Works with Rank Math, Yoast, All in One SEO. One-click SEO optimization via Claude API.
kind: skill-graph
topics: ["[[wordpress]]", "[[seo]]", "[[gutenberg]]", "[[claude-api]]"]
---

# FVM AI Meta Assistant

Gutenberg sidebar plugin for AI-powered SEO meta generation.

## Purpose

**Problem:** Writing unique meta titles and descriptions for every page is:
- Time-consuming
- Repetitive
- Often an afterthought
- Inconsistent quality

**Solution:** AI-generated meta tags:
- One click in Gutenberg editor
- SEO-optimized automatically
- Character limits respected
- Natural, compelling copy

## How It Works

### User Experience
1. Edit post/page in Gutenberg
2. Open sidebar (FVM AI Meta)
3. Click "Generate Meta Tags"
4. AI analyzes page content
5. Generates title + description
6. One-click to apply
7. Compatible SEO plugin auto-updates

### AI Analysis

Claude Sonnet 4 analyzes:
- Page heading
- Main content
- Existing keywords
- Post type/category
- Target audience

Generates:
- **Meta title:** 50-60 characters
- **Meta description:** 150-160 characters
- Both optimized for CTR + SEO

## Plugin Compatibility

Works with:
- **Rank Math** (primary support)
- **Yoast SEO**
- **All in One SEO**
- Any plugin using `_yoast_wpseo_title` / `_yoast_wpseo_metadesc` meta keys

Auto-detects active SEO plugin and updates correct fields.

## Features

### Gutenberg Sidebar
- Clean, minimal UI
- Generate button
- Preview before applying
- Edit after generation
- Character count indicators

### Smart Generation
AI considers:
- Page content and context
- Target keywords
- User intent
- SEO best practices
- Character limits

### One-Click Apply
- Automatically populates SEO plugin fields
- No copy-paste needed
- Instant preview in SEO plugin
- Undo/regenerate option

### Bulk Generation (future)
- Generate for multiple posts
- Queue processing
- Batch updates
- Progress tracking

## Settings

**WP Admin → Settings → AI Meta Assistant**

- Claude API key
- Default generation style (compelling/professional/casual)
- Character limit preferences
- Enable/disable auto-save

## Use Cases

### New Content Workflow
1. Write blog post
2. Click "Generate Meta Tags"
3. Review AI suggestions
4. Apply or edit
5. Publish

### Existing Content Optimization
1. Open old post
2. Generate fresh meta tags
3. Replace outdated ones
4. Improve SEO

### Bulk Optimization
1. Queue 50 old posts
2. Generate meta for all
3. Review batch
4. Apply updates
5. Boost SEO site-wide

## API Usage

**Cost per generation:**
- ~500 tokens per page
- ~$0.0015 per meta generation
- 1000 pages = ~$1.50

**Response time:**
- ~2-5 seconds per generation
- Fast enough for real-time UI

## Security

- API key encrypted storage
- Admin-only access
- Nonce verification
- Input sanitization
- Output escaping

## Technical Details

### Gutenberg Integration
- React sidebar component
- WordPress block editor APIs
- Meta field management
- Real-time updates

### SEO Plugin Detection
```php
// Auto-detect active SEO plugin
if (defined('RANK_MATH_VERSION')) {
    update_post_meta($post_id, 'rank_math_title', $title);
    update_post_meta($post_id, 'rank_math_description', $desc);
} elseif (defined('WPSEO_VERSION')) {
    update_post_meta($post_id, '_yoast_wpseo_title', $title);
    update_post_meta($post_id, '_yoast_wpseo_metadesc', $desc);
}
```

### API Integration
Uses [[claude-api-integration]] patterns:
- Retry logic
- Rate limiting
- Error handling
- Response validation

## Code Location

- Repo: `13Guinness/fvm-ai-meta-assistant`
- Local: `~/.openclaw/workspace/fvm-ai-meta-assistant/`
- WordPress: `/wp-content/plugins/fvm-ai-meta-assistant/`

## Related

- [[fvm-ai-editor-assistant]] — Content editing AI
- [[local-seo-autopilot]] — Full SEO suite
- [[claude-api-integration]] — AI patterns
- [[gutenberg-plugins]] — Block editor extensions

---

**Topics:**
- [[wordpress]]
- [[seo]]
- [[gutenberg]]
- [[claude-api]]
- [[meta-optimization]]
