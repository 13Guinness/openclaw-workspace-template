---
description: Claude API Dashboard — WordPress plugin that displays Claude API usage statistics and costs in admin. Real-time analytics, interactive charts, API key management, cost tracking by date range.
kind: skill-graph
topics: ["[[wordpress]]", "[[claude-api]]", "[[analytics]]"]
---

# Claude API Dashboard

WordPress plugin for monitoring Claude API usage and costs.

## Purpose

**Problem:** No visibility into Claude API usage across WordPress sites.

**Solution:** Admin dashboard that shows:
- Real-time API statistics
- Usage costs by date
- Request patterns
- Token consumption
- Average latency

## Features

### Real-Time Statistics
- Total API requests
- Tokens processed (input/output)
- Average latency
- Error rate
- Cost calculations

### Interactive Charts
- Usage over time (Recharts)
- Cost trends
- Request volume patterns
- Peak usage periods

### API Key Management
- Secure storage (WordPress options)
- Multiple key support
- Key rotation
- Usage per key

### Date Range Filtering
- Custom date ranges
- Compare periods
- Export reports
- Cost forecasting

### Cost Tracking
- Per-request costs
- Daily/weekly/monthly totals
- Model-specific pricing
- Budget alerts

## Architecture

### Data Collection
```
WordPress Site
  ↓
Claude API Calls
  ↓
Usage Hook/Logger
  ↓
Dashboard Database
```

### WordPress Integration
- Admin menu page
- Custom database table (usage logs)
- AJAX for real-time updates
- Settings API for config

### Tech Stack
- React (Recharts for charts)
- Tailwind CSS
- WordPress REST API
- Custom post meta for storage

## Use Cases

### Monthly Usage Review
1. Open dashboard
2. Filter by last 30 days
3. Review total costs
4. Identify usage spikes
5. Optimize if needed

### Multi-Site Monitoring
Track Claude usage across:
- Multiple WordPress sites
- Different API keys
- Various plugins/features

### Budget Management
- Set monthly budget
- Get alerts at 80% usage
- Track actual vs. projected
- Optimize expensive features

## Installation

1. Upload to `/wp-content/plugins/claude-api-dashboard/`
2. Activate plugin
3. Go to **Tools → Claude API Dashboard**
4. Enter API key
5. View statistics

## Configuration

### API Key Setup
- Stored encrypted in wp_options
- Required: `sk-ant-...` format
- One key per site (or multi-key)

### Usage Logging
Automatically logs:
- Request timestamp
- Model used
- Tokens (input/output)
- Latency
- Success/error status
- Cost calculation

## Charts & Visualizations

### Usage Over Time
Line chart showing:
- Daily request volume
- Cost per day
- Token usage trends

### Model Breakdown
Pie chart of:
- Requests by model
- Cost by model
- Token distribution

### Cost Analysis
Bar chart comparing:
- Daily costs
- Weekly averages
- Monthly projections

## Security

- API keys encrypted at rest
- Admin-only access (`manage_options`)
- Nonce verification
- Sanitized inputs
- Escaped outputs

## Performance

- Efficient database queries
- Pagination for large datasets
- Lazy loading charts
- Cached statistics (5 min)

## Code Location

- Repo: `13Guinness/claude-api-dashboard`
- Local: `~/.openclaw/workspace/claude-api-dashboard/`
- WordPress: `/wp-content/plugins/claude-api-dashboard/`

## Related

- [[local-seo-autopilot]] — Uses Claude API
- [[wp-geo-toolkit]] — Uses Claude API
- [[analytics]] — Dashboard patterns

---

**Topics:**
- [[wordpress]]
- [[claude-api]]
- [[analytics]]
- [[cost-tracking]]
