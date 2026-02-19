---
description: Cache Warmer — WordPress plugin that automatically warms page cache by crawling sitemaps or all published content. Ensures fresh cache for faster page loads.
kind: skill-graph
topics: ["[[wordpress]]", "[[performance]]", "[[caching]]"]
---

# Cache Warmer

WordPress plugin that automatically warms your page cache.

## Purpose

**Problem:** After cache purge (deploy, updates), first visitors get slow loads while cache rebuilds.

**Solution:** Automatically crawl and warm cache:
- After deployments
- On schedule (cron)
- On-demand trigger
- Ensures fast loads for all visitors

## How It Works

### Cache Warming Process
```
Trigger (manual/cron/deploy)
  ↓
Fetch sitemap.xml
  ↓
Extract all URLs
  ↓
Crawl each URL (HTTP request)
  ↓
Cache populated by hosting layer
  ↓
Pages load fast for visitors
```

### Crawl Sources

**Sitemap mode:**
- Parse XML sitemap
- Crawl all listed URLs
- Respects priority tags
- Most efficient

**All content mode:**
- Query all published posts/pages
- Generate URLs dynamically
- Includes custom post types
- Slower but comprehensive

## Features

### Scheduled Warming
- WordPress cron integration
- Daily/weekly/hourly schedules
- Off-peak scheduling
- Automatic execution

### Manual Trigger
- Admin page button
- One-click warming
- Progress display
- Completion notification

### Post-Deploy Hooks
- Trigger after plugin updates
- After theme changes
- After content publishes
- Configurable conditions

### Progress Tracking
- Real-time UI updates
- Pages crawled count
- Success/error status
- Estimated completion

### Throttling
- Rate limiting (avoid server overload)
- Configurable delay between requests
- Batch processing
- Server-friendly

## Settings

**WP Admin → Settings → Cache Warmer**

- Enable/disable automatic warming
- Crawl schedule (hourly/daily/weekly)
- Source (sitemap vs all content)
- Rate limit (requests/second)
- Post-deploy triggers

## Use Cases

### After Site Deploy
1. Push code changes
2. Cache gets purged
3. Cache Warmer auto-triggers
4. All pages re-cached
5. Fast loads resume

### Scheduled Maintenance
- Run nightly at 3 AM
- Warm entire cache
- Ensures morning traffic gets fast loads
- Set and forget

### After Content Updates
- Publish 50 new blog posts
- Cache Warmer crawls all
- New pages cached immediately
- No slow first-visit penalty

## Performance

### Crawl Speed
- ~5-10 pages/second (throttled)
- 100 pages = ~10-20 seconds
- 1000 pages = ~2-3 minutes

### Server Impact
- Minimal (throttled requests)
- Configurable delay
- Can run in background
- No user-facing impact

## Hosting Compatibility

**Works with:**
- WP Engine
- Kinsta
- Cloudflare APO
- Any page cache plugin
- Server-level caching

**How:** HTTP requests trigger cache generation automatically.

## Troubleshooting

### Cache Not Warming

**Check:**
- Sitemap accessible
- URLs returning 200
- Cache plugin active
- Cron running

### Server Timeout

**Fix:**
- Lower rate limit
- Increase PHP timeout
- Use sitemap mode (faster)
- Schedule during off-peak

## Code Location

- Repo: `13Guinness/cache-warmer`
- Local: `~/.openclaw/workspace/cache-warmer/`
- WordPress: `/wp-content/plugins/cache-warmer/`

## Related

- [[wp-engine-dashboard]] — WP Engine management
- [[wordpress-performance]] — Performance optimization
- [[caching-strategies]] — Cache layer patterns

---

**Topics:**
- [[wordpress]]
- [[performance]]
- [[caching]]
- [[automation]]
