---
description: WP Engine Dashboard — Web dashboard for managing WP Engine hosting. View server stats, create backups, monitor sites, control hosting via WP Engine API integration.
kind: skill-graph
topics: ["[[wordpress]]", "[[wp-engine]]", "[[hosting-management]]"]
---

# WP Engine Dashboard

Custom dashboard for managing WP Engine hosting accounts via API.

## Purpose

**Problem:** WP Engine's portal is slow and feature-limited for power users managing multiple sites.

**Solution:** Custom dashboard that:
- Shows real-time server stats
- Creates/manages backups on demand
- Monitors site health
- Provides faster, cleaner interface

## Features

### [[server-stats]]
Real-time hosting metrics:
- Disk usage
- Bandwidth
- Site count
- PHP memory limits
- Cache status

### [[backup-management]]
Automated and on-demand backups:
- Create backup with one click
- Scheduled backup configuration
- Restore from backup
- Download backup files
- Backup history and status

### [[site-monitoring]]
Multi-site dashboard:
- Site health checks
- Uptime monitoring
- Performance metrics
- SSL certificate status
- WordPress version tracking

### [[cache-control]]
WP Engine cache management:
- Clear cache for specific sites
- Clear all caches
- Purge CDN cache
- Cache status indicators

## Architecture

### [[wp-engine-api]]
Integration with WP Engine REST API:
- Authentication (OAuth 2.0)
- Rate limiting
- Error handling
- Response caching

### API Endpoints
```
/api/sites          # List all sites
/api/sites/:id      # Site details
/api/backups        # Backup operations
/api/stats          # Server statistics
/api/cache          # Cache operations
```

### Data Flow
```
Dashboard UI
  ↓
Next.js API Routes
  ↓
WP Engine API Client
  ↓
WP Engine REST API
```

## Key Integrations

### [[wp-engine-api]]
Official WP Engine API v2:
- Sites management
- Backups
- Installs
- Domains
- Users

### Authentication
- WP Engine API credentials
- OAuth 2.0 flow
- Token refresh
- Secure storage

## Use Cases

### Daily Backup Creation
1. Open dashboard
2. Select site
3. Click "Create Backup"
4. Monitor progress
5. Confirmation + download link

### Multi-Site Health Check
1. Dashboard shows all sites
2. Scan for issues:
   - Outdated WP versions
   - Expiring SSL certs
   - High disk usage
3. Take action on flagged sites

### Emergency Cache Clear
1. Site having issues
2. Navigate to site in dashboard
3. Click "Clear All Caches"
4. Verify cache cleared
5. Test site

## Technical Stack

- **Frontend:** Next.js + React
- **Backend:** Next.js API routes
- **Database:** PostgreSQL (site metadata, cache)
- **API Client:** WP Engine official SDK
- **Auth:** OAuth 2.0

## Configuration

### Environment Variables
```env
WP_ENGINE_API_KEY=
WP_ENGINE_API_SECRET=
WP_ENGINE_ACCOUNT_ID=
DATABASE_URL=
```

### WP Engine Setup
1. Get API credentials from WP Engine portal
2. Add credentials to `.env`
3. Configure OAuth callback URL
4. Test connection

## Development

### Setup
```bash
npm install
npm run dev
```

### API Testing
```bash
# Test WP Engine connection
curl localhost:3000/api/test-connection

# List sites
curl localhost:3000/api/sites
```

## Security

- [[api-security]] — Credential storage, HTTPS only
- [[rate-limiting]] — Prevent API abuse
- [[authentication]] — Admin-only access

## Performance

- Response caching (5 min)
- Lazy loading for large site lists
- Optimistic UI updates
- Background data refresh

## Code Location

- Repo: `13Guinness/wp-engine-dashboard`
- Local: `~/.openclaw/workspace/wp-engine-dashboard/`

## Related

- [[fuel-vm-configurator]] — Another Fuel VM tool
- [[wp-geo-toolkit]] — WordPress plugin suite
- [[hosting-management]] — Server management patterns

---

**Topics:**
- [[wordpress]]
- [[wp-engine]]
- [[hosting-management]]
- [[api-integration]]
