---
name: google-search-console
description: Pull keyword rankings, clicks, impressions, and CTR from Google Search Console API. Use when auditing SEO performance, tracking keyword rankings, analyzing click-through rates, or generating traffic reports for a website.
version: 1.0
category: seo
---

# Google Search Console Skill

Pull keyword rankings, clicks, impressions, and CTR data from Google Search Console (GSC) using the Search Analytics API. Supports both personal Google accounts (OAuth2) and service accounts for automated/server use.

## Prerequisites

- macOS with bash, curl, and python3 (all standard on macOS)
- A Google account with sites verified in GSC: https://search.google.com/search-console
- A Google Cloud project with the Search Console API enabled
- Credentials stored in `~/.openclaw/gsc-credentials/` (never in the workspace)

---

## Quick Start

```bash
# 1. Authenticate (first time only)
bash scripts/gsc-auth.sh

# 2. List your verified sites
bash scripts/gsc-query.sh --list-sites

# 3. Query top keywords for a site (last 28 days)
bash scripts/gsc-query.sh --site "https://example.com/" --type queries

# 4. Export to CSV
bash scripts/gsc-export.sh --site "https://example.com/" --output rankings.csv
```

---

## Authentication Setup

GSC supports two auth methods. Choose the one that fits your use case.

### Method A: Personal Google Account (OAuth2 — recommended for individuals)

This flow opens a browser URL, you authorize, then paste the code back.

**Step 1: Create OAuth2 credentials in Google Cloud Console**

1. Go to https://console.cloud.google.com/
2. Create a new project (or select existing)
3. Enable the **Google Search Console API**:
   - APIs & Services → Library → search "Search Console API" → Enable
4. Create credentials:
   - APIs & Services → Credentials → Create Credentials → OAuth 2.0 Client ID
   - Application type: **Desktop app**
   - Download the JSON file
5. Save it to: `~/.openclaw/gsc-credentials/oauth-client.json`
6. Configure the OAuth consent screen (External is fine for personal use)

**Step 2: Run the auth script**

```bash
bash scripts/gsc-auth.sh --method oauth
```

The script will:
- Print an authorization URL
- Open it in your browser automatically (or you can copy-paste it)
- Ask you to paste the authorization code
- Exchange it for tokens and store them in `~/.openclaw/gsc-credentials/tokens.json`

Tokens auto-refresh — you only need to do this once.

---

### Method B: Service Account (recommended for automation/CI)

Service accounts work without user interaction. The GSC property must grant the service account access.

**Step 1: Create a service account**

1. Go to https://console.cloud.google.com/iam-admin/serviceaccounts
2. Create a new service account
3. Enable the **Google Search Console API** (if not already)
4. Create a JSON key: Actions → Manage Keys → Add Key → JSON
5. Save it to: `~/.openclaw/gsc-credentials/service-account.json`

**Step 2: Grant GSC access to the service account**

1. Open GSC: https://search.google.com/search-console
2. Select your property → Settings → Users and permissions
3. Add the service account email (found in the JSON: `"client_email"`) as a **Restricted** or **Full** user

**Step 3: Authenticate**

```bash
bash scripts/gsc-auth.sh --method service-account
```

The script validates the JSON and tests API access. No tokens to refresh — the service account JWT is generated fresh each time.

---

## Listing Verified Sites

```bash
bash scripts/gsc-query.sh --list-sites
```

Output:
```
🌐 Verified GSC Properties
─────────────────────────────────────────
  https://example.com/
  https://www.example.com/
  sc-domain:example.com
```

Use the exact URL shown (including trailing slash) as the `--site` argument in all queries.

**Domain vs URL properties:** GSC has two property types:
- `https://example.com/` — URL-prefix property (specific to protocol/subdomain)
- `sc-domain:example.com` — Domain property (covers all subdomains and protocols, requires DNS verification)

---

## Querying Data

### Basic Syntax

```bash
bash scripts/gsc-query.sh \
  --site "https://example.com/" \
  --type queries \
  --start-date 2024-01-01 \
  --end-date 2024-01-31 \
  [--dimension page|device|country|date] \
  [--filter-query "keyword"] \
  [--filter-page "/blog/"] \
  [--filter-device mobile|desktop|tablet] \
  [--filter-country usa] \
  [--limit 100] \
  [--sort clicks|impressions|ctr|position]
```

### Query Types

| `--type`     | What it shows                                  |
|--------------|------------------------------------------------|
| `queries`    | Keywords driving traffic (default)             |
| `pages`      | Which pages get the most clicks/impressions    |
| `devices`    | Performance split by device type               |
| `countries`  | Performance split by country                   |
| `dates`      | Daily trend of clicks/impressions              |

### Date Ranges

GSC data is available from ~16 months ago up to 2–3 days ago (data is not real-time).

```bash
# Last 7 days
bash scripts/gsc-query.sh --site "https://example.com/" --days 7

# Last 28 days (GSC default)
bash scripts/gsc-query.sh --site "https://example.com/" --days 28

# Specific date range
bash scripts/gsc-query.sh --site "https://example.com/" \
  --start-date 2024-01-01 --end-date 2024-01-31

# Last 3 months
bash scripts/gsc-query.sh --site "https://example.com/" --days 90
```

### Top Keywords by Impressions

```bash
bash scripts/gsc-query.sh \
  --site "https://example.com/" \
  --type queries \
  --days 28 \
  --sort impressions \
  --limit 50
```

### Top Keywords by Clicks

```bash
bash scripts/gsc-query.sh \
  --site "https://example.com/" \
  --type queries \
  --days 28 \
  --sort clicks \
  --limit 100
```

### Keywords for a Specific Page

```bash
bash scripts/gsc-query.sh \
  --site "https://example.com/" \
  --type queries \
  --filter-page "/blog/my-article/" \
  --days 28
```

### Pages Ranking for a Specific Keyword

```bash
bash scripts/gsc-query.sh \
  --site "https://example.com/" \
  --type pages \
  --filter-query "best seo tools" \
  --days 90
```

### Mobile vs Desktop Performance

```bash
# Mobile only
bash scripts/gsc-query.sh --site "https://example.com/" --filter-device mobile --days 28

# Desktop only
bash scripts/gsc-query.sh --site "https://example.com/" --filter-device desktop --days 28

# Split by device
bash scripts/gsc-query.sh --site "https://example.com/" --type devices --days 28
```

### Country Breakdown

Country codes follow ISO 3166-1 alpha-3 (e.g., `usa`, `gbr`, `can`, `aus`).

```bash
# Traffic from USA only
bash scripts/gsc-query.sh --site "https://example.com/" --filter-country usa --days 28

# Country breakdown
bash scripts/gsc-query.sh --site "https://example.com/" --type countries --days 28 --limit 20
```

### Daily Trends

```bash
bash scripts/gsc-query.sh \
  --site "https://example.com/" \
  --type dates \
  --days 90
```

---

## Period Comparison (MoM, YoY)

Use `gsc-export.sh` with the `--compare` flag to run two queries and diff them.

### Month-over-Month

```bash
bash scripts/gsc-export.sh \
  --site "https://example.com/" \
  --compare mom \
  --output mom-comparison.csv
```

This queries the current month vs the same period last month, then outputs a CSV with delta columns for clicks, impressions, CTR, and position.

### Year-over-Year

```bash
bash scripts/gsc-export.sh \
  --site "https://example.com/" \
  --compare yoy \
  --output yoy-comparison.csv
```

### Custom Period Comparison

```bash
bash scripts/gsc-export.sh \
  --site "https://example.com/" \
  --period-a-start 2024-01-01 --period-a-end 2024-01-31 \
  --period-b-start 2023-01-01 --period-b-end 2023-01-31 \
  --output jan-yoy.csv
```

Output columns: `keyword, clicks_a, clicks_b, clicks_delta, impressions_a, impressions_b, impressions_delta, ctr_a, ctr_b, position_a, position_b, position_delta`

---

## Filtering to Top N Keywords

```bash
# Top 10 keywords by impressions
bash scripts/gsc-query.sh --site "https://example.com/" --sort impressions --limit 10

# Top 25 keywords by clicks
bash scripts/gsc-query.sh --site "https://example.com/" --sort clicks --limit 25

# Top keywords with low CTR (position < 10 but CTR < 2%)
bash scripts/gsc-query.sh \
  --site "https://example.com/" \
  --days 28 \
  --sort impressions \
  --limit 500 \
  --filter-max-ctr 0.02 \
  --filter-max-position 10
```

---

## Exporting to CSV

### Basic Export

```bash
bash scripts/gsc-export.sh \
  --site "https://example.com/" \
  --output rankings.csv
```

### Full Export (all dimensions)

```bash
bash scripts/gsc-export.sh \
  --site "https://example.com/" \
  --type queries \
  --days 28 \
  --sort impressions \
  --limit 1000 \
  --output full-export.csv
```

### Export with All Dimensions (query + page + device + country)

```bash
bash scripts/gsc-export.sh \
  --site "https://example.com/" \
  --dimensions "query,page,device,country" \
  --days 28 \
  --limit 5000 \
  --output full-dimensional.csv
```

CSV format:
```
keyword,page,device,country,clicks,impressions,ctr,position
"best seo tools","/blog/seo-tools/",MOBILE,usa,142,4823,0.0294,3.2
...
```

### Paginated Export (for large sites)

The API returns max 25,000 rows per request. For sites with more data, use `--paginate`:

```bash
bash scripts/gsc-export.sh \
  --site "https://example.com/" \
  --limit 25000 \
  --paginate \
  --output large-export.csv
```

---

## Output Format

Default terminal output (table):

```
📊 GSC Rankings — https://example.com/ — 2024-01-01 to 2024-01-28
──────────────────────────────────────────────────────────────────────
Keyword                          Clicks  Impr    CTR    Position
──────────────────────────────────────────────────────────────────────
best seo tools                    1,423  42,100  3.38%   2.1
keyword research tools              891  31,200  2.86%   3.4
seo audit checklist                 543  18,900  2.87%   4.2
...
──────────────────────────────────────────────────────────────────────
Total                             2,857  92,200  3.10%   —
```

---

## Common API Errors and Fixes

### 401 Unauthorized
**Cause:** Access token expired or invalid credentials.
**Fix:**
```bash
# Re-authenticate
bash scripts/gsc-auth.sh --method oauth --force

# For service accounts, verify the JSON file is valid
bash scripts/gsc-auth.sh --method service-account --test
```

### 403 Forbidden
**Cause:** The authenticated user/service account doesn't have access to this GSC property.
**Fix:**
1. Open GSC → Settings → Users and permissions
2. Add the account email with at least **Restricted** access
3. For domain properties, verify DNS ownership

### 400 Bad Request
**Cause:** Invalid date range, dimension name, or filter syntax.
**Fix:** Check that:
- Dates are in `YYYY-MM-DD` format
- Start date is not more than 16 months ago
- End date is not in the future (data lags 2-3 days)
- Country codes use ISO 3166-1 alpha-3 (e.g., `usa` not `us`)

### 429 Too Many Requests (Rate Limited)
**Cause:** Exceeded API quota.
**Fix:** The scripts automatically retry with exponential backoff. Default quotas:
- 1,200 queries per minute per project
- 200 queries per 100 seconds per user

If you hit limits frequently:
```bash
# Add delay between requests
bash scripts/gsc-export.sh --site "https://example.com/" --request-delay 2
```

Or increase quota in Google Cloud Console:
APIs & Services → Search Console API → Quotas & System Limits

### 500 / 503 Backend Error
**Cause:** Transient Google API error.
**Fix:** Scripts retry automatically up to 3 times with backoff. If persistent, check https://status.cloud.google.com/

### "Site not verified" / "No data for property"
**Cause:** The site URL doesn't exactly match a verified property.
**Fix:**
```bash
# List exact property URLs
bash scripts/gsc-query.sh --list-sites
# Use the exact string shown, including trailing slash
```

### Token Refresh Fails
**Cause:** Refresh token revoked (user changed password, revoked app access, or token expired after 7 days for test apps).
**Fix:**
```bash
bash scripts/gsc-auth.sh --method oauth --force
```
To prevent 7-day expiry: publish your OAuth consent screen in Google Cloud Console.

---

## Rate Limits and Pagination

### GSC API Limits

| Limit                        | Default Value          |
|------------------------------|------------------------|
| Rows per response            | 25,000 (max)           |
| Requests per day             | Unlimited (quota-based)|
| Queries per minute           | 1,200                  |
| Queries per 100s per user    | 200                    |
| Date range lookback          | ~16 months             |
| Data freshness lag           | 2–3 days               |

### Pagination

The API supports offset-based pagination via `startRow`. For exports exceeding 25,000 rows:

```bash
bash scripts/gsc-export.sh --site "https://example.com/" --paginate --limit 100000
```

The script automatically handles multiple API calls and merges results into one CSV.

### Dimension Cardinality Limits

When combining multiple dimensions (e.g., query + page + device + country), the number of possible combinations can be very large. The API applies **data thresholds** — rows with very low traffic may be omitted to protect user privacy. This is expected behavior, not a bug.

---

## Credential File Locations

```
~/.openclaw/gsc-credentials/
├── oauth-client.json       # OAuth2 client ID + secret (from Google Cloud Console)
├── tokens.json             # OAuth2 access + refresh tokens (generated by auth script)
└── service-account.json    # Service account key JSON (from Google Cloud Console)
```

These files contain sensitive credentials. They are stored outside the workspace intentionally and should never be committed to version control.

---

## Environment Variables

You can override defaults with environment variables:

```bash
export GSC_SITE="https://example.com/"
export GSC_DAYS=28
export GSC_CREDENTIALS_DIR="$HOME/.openclaw/gsc-credentials"
export GSC_AUTH_METHOD="oauth"   # or "service-account"
```

---

## Example Workflows

### Weekly SEO Report

```bash
#!/usr/bin/env bash
SITE="https://example.com/"
DATE=$(date +%Y-%m-%d)

# Top 100 keywords
bash scripts/gsc-export.sh --site "$SITE" --days 7 --sort clicks --limit 100 \
  --output "reports/weekly-keywords-$DATE.csv"

# Page performance
bash scripts/gsc-export.sh --site "$SITE" --days 7 --type pages --sort clicks --limit 50 \
  --output "reports/weekly-pages-$DATE.csv"

echo "✅ Reports saved to reports/"
```

### Find Quick Win Opportunities (High Impressions, Low CTR)

```bash
bash scripts/gsc-query.sh \
  --site "https://example.com/" \
  --days 90 \
  --sort impressions \
  --limit 1000 \
  --filter-max-ctr 0.03 \
  --filter-max-position 15
```

### Track a Specific Keyword Over Time

```bash
bash scripts/gsc-query.sh \
  --site "https://example.com/" \
  --type dates \
  --filter-query "your target keyword" \
  --days 90
```

### Compare Mobile vs Desktop Rankings

```bash
bash scripts/gsc-export.sh \
  --site "https://example.com/" \
  --filter-device mobile \
  --days 28 \
  --output mobile-rankings.csv

bash scripts/gsc-export.sh \
  --site "https://example.com/" \
  --filter-device desktop \
  --days 28 \
  --output desktop-rankings.csv
```
