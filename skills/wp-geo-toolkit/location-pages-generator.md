---
description: Location Pages Generator add-on — creates new location-specific pages from a template. AI generates unique content for each location with SEO metadata, internal links, and schema markup. For franchises and multi-location businesses entering new markets.
kind: add-on
topics: ["[[wp-geo-toolkit]]", "[[ai-content]]", "[[local-seo]]"]
---

# Location Pages Generator

Add-on that creates new location-specific pages from a template using AI.

## Use Cases

**Franchise expanding to 50 cities:**
- Create parent page with template content
- Enter list of new cities
- AI generates unique pages for all 50
- Complete in ~1 hour vs 100+ hours manual

**Service provider entering new markets:**
- Have content for existing location
- Entering 10 new markets
- AI adapts content for each location
- SEO-optimized from day one

## Process Flow

1. **Site Crawling**
   - Extract services, images, contact info
   - Cache for 24 hours
   - Used in AI prompt

2. **Location Geocoding**
   - Convert "City, State" → coordinates
   - Via [[geocoding-service]]
   - Required for proximity calculations

3. **Proximity Calculation**
   - Find 8 nearest locations
   - Via [[proximity-calculator]]
   - For "Other Areas We Serve" links

4. **Prompt Building**
   - Combine site data + location data
   - Specify structure: heading, content, FAQ
   - Set [[ai-rewrite-levels]]

5. **AI Generation**
   - Send to [[claude-ai-integration]]
   - Returns JSON with content + metadata
   - ~1 minute per page

6. **Page Creation**
   - Create WordPress page
   - Add SEO meta (Rank Math/Yoast)
   - Store [[location-data-structure]]
   - Add schema markup

7. **Image Selection** (optional)
   - Scan media library
   - Select relevant images
   - Set as featured image

8. **Internal Linking**
   - Add "Other Areas We Serve" section
   - Link to 8 nearest pages
   - Two-way linking

## Features

### Real-Time Progress Tracking
```
Generating: Naples, Florida
├── Geocoding... ✓
├── Finding nearby locations... ✓
├── Generating content with AI... ✓
├── Creating WordPress page... ✓
├── Adding SEO metadata... ✓
└── Complete! (Page ID: 123)
```

### AI Rewrite Levels

Via [[ai-rewrite-levels]]:
- **Low (10-20%):** Mostly geographic replacements
- **Medium (40-60%):** Balanced, natural (recommended)
- **High (80-90%):** Maximum uniqueness

### Auto-Generate Images

Intelligently selects from media library:
- Match location name in filename
- Match service keywords
- Fallback to most recent uploads

### Two-Pass Process

**Pass 1: Content + SEO**
- Generate page content
- Add metadata
- Create pages

**Pass 2: Internal Links**
- All pages exist
- Calculate proximity between all
- Add cross-links

### Update Links Without Regenerating

Added new locations? Update links only:
- Recalculates proximity
- Updates "Other Areas" sections
- Preserves existing content

## Generated Content Structure

Each page includes:

1. **Hero Section**
   - Location-specific heading
   - Natural language intro
   - Service overview

2. **Main Content** (1200-1800 words)
   - Service details
   - Location-specific information
   - Benefits, process, FAQ

3. **Other Areas We Serve**
   - Links to 8 nearest locations
   - Distances displayed
   - Two-way linking

4. **SEO Metadata**
   - Title (60 chars)
   - Meta description (155 chars)
   - Local business schema

5. **FAQ Section** (optional)
   - 3-5 common questions
   - FAQ schema markup

## Settings

Access: **WP Admin → Geo Toolkit → Location Pages**

**Parent Page:**
- Template page for content
- New pages created as children

**AI Rewrite Level:**
- Low / Medium / High
- Controls variation amount

**Auto-Generate Images:**
- Enable/disable image selection
- Uses media library

**Locations List:**
- One location per line
- Format: "City, State"

## Performance

- **Processing:** ~1 min/page sequential
- **Cost:** ~$0.015/page (Claude API)
- **Memory:** ~2-5MB per page
- **Database:** O(n) queries, no complex joins

**Example:**
- 50 pages = ~1 hour, ~$0.75
- 100 pages = ~2 hours, ~$1.50

## Code Location

- Main class: `WPGT_LP_Generator`
- Files: `wpgt-location-pages/includes/`
- GitHub: `13Guinness/wpgt-location-pages`

## Related

- [[content-transformer]] — Transform existing content instead
- [[geographic-transformation]] — Core AI transformation concept
- [[claude-ai-integration]] — AI generation service
- [[proximity-calculator]] — Finds nearby locations for linking

---

**Topics:**
- [[wp-geo-toolkit]]
- [[ai-content]]
- [[local-seo]]
- [[wordpress]]
