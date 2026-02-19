---
name: seo
description: >
  Comprehensive SEO analysis for any website or business type. Performs full site
  audits, single-page deep analysis, technical SEO checks (crawlability, indexability,
  Core Web Vitals with INP), schema markup detection/validation/generation, content
  quality assessment (E-E-A-T framework), image optimization, sitemap analysis,
  programmatic SEO with quality gates, competitor comparison pages, hreflang/i18n,
  and Generative Engine Optimization (GEO) for AI Overviews, ChatGPT, and Perplexity.
  Use when asked about SEO audits, schema markup, Core Web Vitals, sitemaps, E-E-A-T,
  AI search optimization, local SEO, geo pages, or structured data.
---

# SEO — Universal SEO Analysis Skill

Comprehensive SEO analysis across all industries (SaaS, local services,
e-commerce, publishers, agencies). Orchestrates 12 specialized sub-skills.

Sub-skills are located at:
`~/.openclaw/workspace/skills/seo-*/SKILL.md`

Reference files: `skills/seo/references/`
Schema templates: `skills/seo/schema/templates.json`
Scripts: `skills/seo/scripts/`
Agent definitions: `skills/seo/agents/`

## Commands

| Command | What it does |
|---------|-------------|
| `seo audit <url>` | Full website audit with parallel subagent delegation |
| `seo page <url>` | Deep single-page analysis |
| `seo sitemap <url or generate>` | Analyze or generate XML sitemaps |
| `seo schema <url>` | Detect, validate, and generate Schema.org markup |
| `seo images <url>` | Image optimization analysis |
| `seo technical <url>` | Technical SEO audit (8 categories) |
| `seo content <url>` | E-E-A-T and content quality analysis |
| `seo geo <url>` | AI Overviews / Generative Engine Optimization |
| `seo plan <business-type>` | Strategic SEO planning |
| `seo programmatic [url\|plan]` | Programmatic SEO analysis and planning |
| `seo competitor-pages [url\|generate]` | Competitor comparison page generation |
| `seo hreflang [url]` | Hreflang/i18n SEO audit and generation |

## Orchestration Logic

When asked for a full audit, delegate to sub-skills in parallel:
1. Detect business type (SaaS, local, ecommerce, publisher, agency, other)
2. Spawn sub-analyses: seo-technical, seo-content, seo-schema, seo-sitemap, seo-performance, seo-visual
3. Collect results and generate unified report with SEO Health Score (0-100)
4. Create prioritized action plan (Critical → High → Medium → Low)

For individual commands, load the relevant sub-skill directly from `skills/seo-*/SKILL.md`.

## Industry Detection

Detect business type from homepage signals:
- **SaaS**: pricing page, /features, /integrations, /docs, "free trial", "sign up"
- **Local Service**: phone number, address, service area, "serving [city]", Google Maps embed
- **E-commerce**: /products, /collections, /cart, "add to cart", product schema
- **Publisher**: /blog, /articles, /topics, article schema, author pages, publication dates
- **Agency**: /case-studies, /portfolio, /industries, "our work", client logos

## Quality Gates

Read `references/quality-gates.md` for thin content thresholds per page type.
Hard rules:
- ⚠️ WARNING at 30+ location pages (enforce 60%+ unique content)
- 🛑 HARD STOP at 50+ location pages (require user justification)
- Never recommend HowTo schema (deprecated Sept 2023)
- FAQ schema only for government and healthcare sites
- All Core Web Vitals references use INP, never FID

## Reference Files

Load these on-demand as needed — do NOT load all at startup:
- `references/cwv-thresholds.md` — Current Core Web Vitals thresholds
- `references/schema-types.md` — All supported schema types with deprecation status
- `references/eeat-framework.md` — E-E-A-T evaluation criteria (Sept 2025 QRG update)
- `references/quality-gates.md` — Content length minimums, uniqueness thresholds
- `google-seo-reference.md` — Google SEO quick reference guide

## SEO Health Score (0-100)

| Category | Weight |
|----------|--------|
| Technical SEO | 25% |
| Content Quality | 25% |
| On-Page SEO | 20% |
| Schema / Structured Data | 10% |
| Performance (CWV) | 10% |
| Images | 5% |
| AI Search Readiness | 5% |

## Priority Levels
- **Critical**: Blocks indexing or causes penalties (fix immediately)
- **High**: Significantly impacts rankings (fix within 1 week)
- **Medium**: Optimization opportunity (fix within 1 month)
- **Low**: Nice to have (backlog)

## Sub-Skills

1. **seo-audit** — Full website audit with parallel delegation
2. **seo-page** — Deep single-page analysis
3. **seo-technical** — Technical SEO (8 categories)
4. **seo-content** — E-E-A-T and content quality
5. **seo-schema** — Schema markup detection and generation
6. **seo-images** — Image optimization
7. **seo-sitemap** — Sitemap analysis and generation
8. **seo-geo** — AI Overviews / GEO optimization
9. **seo-plan** — Strategic planning with industry templates
10. **seo-programmatic** — Programmatic SEO analysis and planning
11. **seo-competitor-pages** — Competitor comparison page generation
12. **seo-hreflang** — Hreflang/i18n SEO audit and generation
