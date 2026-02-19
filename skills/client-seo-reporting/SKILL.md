---
name: client-seo-reporting
description: Generate professional monthly SEO PDF reports for clients. Takes audit data and GSC metrics as input and outputs a branded, print-ready PDF report. Use when creating client deliverables, monthly reports, or SEO progress summaries.
version: 1.0
category: seo
---

# Client SEO Reporting

Generate professional, branded monthly SEO PDF reports from audit data and Google Search Console exports. Outputs a print-ready PDF with executive summary, traffic trends, keyword rankings, technical issues, and actionable recommendations.

---

## 1. Data to Gather Before Running

Collect the following before generating a report. All inputs are passed as environment variables or a JSON data file.

### Google Search Console (GSC)
Export from GSC > Performance > Search results for the report month:
- **Clicks** (total + MoM delta)
- **Impressions** (total + MoM delta)
- **Average CTR** (+ MoM delta)
- **Average Position** (+ MoM delta)
- **Top 10 pages by clicks** (URL, clicks, impressions, CTR, position)
- **Top 20 keywords by clicks** (query, clicks, impressions, CTR, position)

Export format: CSV → convert to JSON using the data prep script, or fill `data/report-data.json` manually.

### Technical Audit Scores
From your preferred crawler (Screaming Frog, Ahrefs, Semrush, etc.):
- Overall site health score (0–100)
- Count of critical errors
- Count of warnings
- Count of notices
- Top 5–10 specific issues with affected page counts

### Keyword Rankings
From your rank tracker (Semrush, Ahrefs, STAT, etc.):
- Top 20 target keywords: current position, previous position, change
- Any new top-10 entries or significant drops

### Optional Extras
- Backlink count (current + delta)
- Core Web Vitals scores (LCP, FID/INP, CLS) — mobile and desktop
- Competitor ranking comparisons

---

## 2. Running the Report Generator

### Quick Start

```bash
# 1. Set required environment variables
export CLIENT_NAME="Acme Corp"
export CLIENT_DOMAIN="acmecorp.com"
export REPORT_MONTH="February"
export REPORT_YEAR="2026"
export BRAND_COLOR="#1a3c5e"        # Optional — defaults to FuelVM navy
export ACCENT_COLOR="#e85d26"       # Optional — defaults to FuelVM orange
export LOGO_PATH="/path/to/logo.png"  # Optional — defaults to FuelVM logo placeholder

# 2. Place your data file
cp your-export.json data/report-data.json

# 3. Generate the HTML report
bash scripts/generate-report.sh

# 4. Export to PDF
bash scripts/pdf-export.sh
```

### Data File Format (`data/report-data.json`)

```json
{
  "client": {
    "name": "Acme Corp",
    "domain": "acmecorp.com",
    "logo": ""
  },
  "period": {
    "month": "February",
    "year": "2026",
    "prev_month": "January"
  },
  "gsc": {
    "clicks":       { "value": 12400, "delta": 8.2 },
    "impressions":  { "value": 198000, "delta": 5.1 },
    "ctr":          { "value": 6.26, "delta": 0.3 },
    "avg_position": { "value": 14.2, "delta": -1.8 },
    "top_pages": [
      { "url": "/services/seo", "clicks": 1840, "impressions": 22000, "ctr": 8.4, "position": 3.2 }
    ],
    "top_keywords": [
      { "query": "seo agency", "clicks": 640, "impressions": 9800, "ctr": 6.5, "position": 4.1, "prev_position": 5.3 }
    ]
  },
  "audit": {
    "health_score":   { "value": 87, "delta": 4 },
    "critical_errors": 3,
    "warnings":        22,
    "notices":         41,
    "top_issues": [
      { "type": "Missing meta descriptions", "count": 14, "severity": "warning" },
      { "type": "Broken internal links", "count": 3, "severity": "critical" }
    ]
  },
  "rankings": [
    { "keyword": "seo agency", "position": 4, "prev_position": 6, "change": 2, "url": "/services/seo" }
  ],
  "recommendations": [
    "Fix 3 broken internal links identified in the technical audit.",
    "Add meta descriptions to the 14 pages missing them.",
    "Expand the /blog/seo-tips page — it ranks position 6 for 3 high-volume queries."
  ],
  "next_steps": [
    "Schedule Q2 content calendar review",
    "Run Core Web Vitals audit on mobile",
    "Begin link building outreach for /services/local-seo"
  ]
}
```

---

## 3. Customizing the Report Template

### Brand Colors and Fonts

Edit the CSS variables at the top of `templates/report.html`:

```css
:root {
  --color-primary:   #1a3c5e;   /* Main brand color — header, headings */
  --color-accent:    #e85d26;   /* Accent — highlights, KPI deltas */
  --color-bg:        #f8f9fa;   /* Page background */
  --color-surface:   #ffffff;   /* Card/section background */
  --color-text:      #1e2128;   /* Body text */
  --color-muted:     #6b7280;   /* Labels, secondary text */
  --font-heading:    'Inter', sans-serif;
  --font-body:       'Inter', sans-serif;
}
```

Or override at generation time via environment variables (the shell script injects them):

```bash
export BRAND_COLOR="#0f4c81"
export ACCENT_COLOR="#f59e0b"
bash scripts/generate-report.sh
```

### Logo

Place your client's logo PNG at a path and set `LOGO_PATH`:

```bash
export LOGO_PATH="/Users/you/clients/acmecorp/logo.png"
```

The logo is embedded as a base64 data URI so the PDF is fully self-contained.

### Adding / Removing Sections

Each section in `templates/report.html` is wrapped in a `<section class="report-section" id="...">` block. Add, remove, or reorder sections freely. The generate script fills `{{PLACEHOLDER}}` tokens — add your own tokens and populate them in `scripts/generate-report.sh`.

---

## 4. Exporting to PDF

### Preferred: wkhtmltopdf

```bash
# Install (macOS)
brew install wkhtmltopdf

# Run export
bash scripts/pdf-export.sh
# Output: workspace/reports/2026-02/acmecorp-seo-report-2026-02.pdf
```

### Fallback: Puppeteer (Node.js)

```bash
# Install
npm install -g puppeteer-cli   # or: npx puppeteer

# The pdf-export.sh script auto-detects which tool is available
bash scripts/pdf-export.sh
```

The export script tries `wkhtmltopdf` first, then falls back to `puppeteer`. If neither is found, it prints the HTML path so you can print-to-PDF from a browser.

### Print from Browser (Manual Fallback)

Open the generated HTML in Chrome/Safari and use **File > Print > Save as PDF**. The template includes `@media print` rules for clean output.

---

## 5. Where Reports Are Saved

```
workspace/
└── reports/
    └── YYYY-MM/
        ├── {client-slug}-seo-report-YYYY-MM.html
        └── {client-slug}-seo-report-YYYY-MM.pdf
```

Example: `workspace/reports/2026-02/acmecorp-seo-report-2026-02.pdf`

The directory is created automatically by `generate-report.sh`.

---

## 6. Required Report Sections

Every report must include these sections in order:

| # | Section | Description |
|---|---------|-------------|
| 1 | **Cover Page** | Client name, domain, month/year, FuelVM branding |
| 2 | **Executive Summary** | 3–5 bullet highlights; overall performance narrative |
| 3 | **Traffic Overview** | GSC KPI cards (clicks, impressions, CTR, position) with MoM deltas |
| 4 | **Top Pages** | Table of top 10 pages by clicks |
| 5 | **Top Keywords** | Table of top 20 queries with position changes |
| 6 | **Technical Health** | Audit score, error/warning/notice counts, top issues list |
| 7 | **Keyword Rankings** | Target keyword tracker with position changes |
| 8 | **Recommendations** | Prioritized action items from current month's findings |
| 9 | **Next Steps** | Planned work for the coming month |

---

## Tips & Notes

- Run reports within the first 5 business days of the month (GSC data has ~2-day lag).
- Always QA the PDF at 100% zoom before sending — check tables don't clip and page breaks are clean.
- For multi-location or multi-domain clients, run once per domain and combine PDFs with `pdfunite` or Preview.
- Store generated reports in the client's folder in your project management tool in addition to `workspace/reports/`.
