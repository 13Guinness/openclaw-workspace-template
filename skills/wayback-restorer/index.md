---
description: Wayback Rehydrator — Restore archived websites from the Wayback Machine. Enter URL + snapshot date, get clean working copy with shareable public link. Next.js + Vercel + Inngest background jobs.
kind: skill-graph
topics: ["[[nextjs]]", "[[web-archiving]]", "[[scraping]]"]
---

# Wayback Rehydrator

Restore archived websites from the Wayback Machine with shareable links.

## Purpose

**Problem:** Wayback Machine archives are:
- Hard to browse (broken navigation)
- Missing assets (CSS, JS, images)
- Not shareable as working sites

**Solution:** Restore archived sites as:
- Fully working copies
- Fixed navigation
- Hosted assets
- Shareable public links

## How It Works

### User Flow
1. Enter archived URL
2. Select snapshot date
3. Click "Restore"
4. Background job crawls archive
5. Get shareable link to restored site

### Technical Process
```
User submits URL + date
  ↓
Inngest background job starts
  ↓
Crawl Wayback Machine snapshots
  ↓
Download HTML, CSS, JS, images
  ↓
Rewrite URLs (archive → restored)
  ↓
Upload to Vercel Blob storage
  ↓
Generate public link
```

## Architecture

### Tech Stack
- **Frontend:** Next.js 14 (App Router)
- **Database:** Vercel Postgres
- **Storage:** Vercel Blob
- **Jobs:** Inngest (background processing)
- **Hosting:** Vercel

### Background Jobs
Inngest handles:
- Long-running crawls
- Parallel asset downloads
- Retry logic
- Progress tracking

## Features

### Snapshot Selection
- Browse available dates
- Preview snapshots
- Select best version
- Auto-detect latest

### Asset Recovery
Downloads and hosts:
- HTML pages
- CSS stylesheets
- JavaScript files
- Images (JPG, PNG, GIF, SVG)
- Fonts
- Other media

### URL Rewriting
Converts archive URLs:
```
Before: https://web.archive.org/web/20200101120000/example.com/page
After:  https://restored.example.com/page
```

### Public Links
Shareable URLs:
- Custom subdomain
- Fast CDN delivery
- No Wayback branding
- Working navigation

## Use Cases

### Archive Old Site
**Scenario:** Website taken down, need to preserve it

1. Find last snapshot on Wayback
2. Enter URL in Rehydrator
3. Select snapshot date
4. Get restored copy
5. Share link with stakeholders

### Research/Reference
**Scenario:** Need to cite old website version

1. Restore specific snapshot
2. Get permanent link
3. Use in citations
4. More reliable than Wayback

### Portfolio Preservation
**Scenario:** Old project sites are offline

1. Restore each project
2. Host on custom domain
3. Add to portfolio
4. Clients can browse

## Configuration

### Environment Variables
```env
DATABASE_URL=          # Vercel Postgres
BLOB_READ_WRITE_TOKEN= # Vercel Blob
INNGEST_EVENT_KEY=     # Inngest
INNGEST_SIGNING_KEY=   # Inngest
```

### Vercel Setup
1. Create Vercel project
2. Add Postgres database
3. Enable Blob storage
4. Deploy

### Inngest Setup
1. Create Inngest account (free tier)
2. Create app
3. Add signing/event keys
4. Configure webhook

## Development

### Local Setup
```bash
npm install
npm run dev
```

### Test Restoration
```bash
# Navigate to localhost:3000
# Enter URL: example.com
# Select date from calendar
# Click "Restore"
# Monitor Inngest dashboard
```

## Limitations

### What Works
- Static HTML sites
- Modern CSS/JS (post-2010)
- Common image formats
- Public archives

### What Doesn't
- Dynamic backends (PHP, databases)
- User authentication
- Forms/submissions
- Real-time features
- Private/paywalled content

## Performance

- Small sites (10-50 pages): ~2-5 min
- Medium sites (100-500 pages): ~10-30 min
- Large sites (1000+ pages): ~1-3 hours

Factors:
- Page count
- Asset count
- Wayback response time
- Inngest concurrency

## Cost Estimate

**Vercel (Hobby tier limits):**
- Postgres: Free up to 256 MB
- Blob storage: Free up to 1 GB
- Bandwidth: Free up to 100 GB/month

**Inngest (Free tier):**
- 25,000 events/month
- Unlimited jobs

Small sites fit free tier. Large sites may need Pro ($20/month).

## Code Location

- Repo: `13Guinness/wayback-restorer`
- Local: `~/.openclaw/workspace/wayback-restorer/`

## Related

- [[web-archiving]] — Archive strategies
- [[inngest-patterns]] — Background job patterns
- [[vercel-deployment]] — Deployment setup

---

**Topics:**
- [[nextjs]]
- [[web-archiving]]
- [[scraping]]
- [[inngest]]
