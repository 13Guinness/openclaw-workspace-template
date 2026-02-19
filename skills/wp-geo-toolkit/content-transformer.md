---
description: Content Transformer add-on — transforms existing WordPress content from one location to another using AI. In-place updates that preserve URLs, perfect for businesses relocating or localizing generic content. Handles complex blocks, protects metadata, includes backup & undo.
kind: add-on
topics: ["[[wp-geo-toolkit]]", "[[ai-content]]", "[[geographic-transformation]]"]
---

# Content Transformer

Add-on that transforms existing WordPress content from one location to another using AI.

## Use Cases

### Business Relocation
**Scenario:** Company moving from Indianapolis to Naples
- **Before:** "Our Indianapolis office serves Hamilton County..."
- **After:** "Our Naples office serves Collier County..."
- All 50 pages transformed in 1 hour

### Localizing Generic Content
**Scenario:** Generic blog posts need local flavor
- **Source:** No specific location
- **Target:** "Naples, Florida"
- AI injects location context naturally

### Multi-Location Adaptation
**Scenario:** Content written for Indiana, expanding to Florida
- **Source locations:** Indianapolis, Carmel, Fishers
- **Target locations:** Naples, Tampa, Orlando
- AI handles all variations

## Process Flow

1. **Page Selection**
   - Select existing pages/posts
   - Preview current content
   - Choose transformation targets

2. **Location Specification**
   - **Source locations:** Current locations in content
   - **Target locations:** Where to transform to
   - Multiple sources supported

3. **AI Transformation**
   - Preserves structure (blocks, HTML)
   - [[geographic-transformation]] via [[claude-ai-integration]]
   - Handles complex blocks (Yoast FAQ, etc.)

4. **In-Place Update**
   - Updates existing page
   - Preserves URL (no redirects needed)
   - Updates [[location-data-structure]]
   - Maintains parent/child relationships

5. **Backup & Undo**
   - Automatic backup before transformation
   - Restore original content if needed
   - Tracks transformation history

## Features

### Complex Block Protection

Protects special blocks from transformation:
- Yoast FAQ schema
- Rank Math schema
- Custom shortcodes
- Elementor/Breakdance sections

**How it works:**
- Extracts protected blocks before AI
- Transforms remaining content
- Re-inserts protected blocks after

### Multiple Source Locations

Handle content referencing multiple locations:

**Input:**
```
Source locations:
- Indianapolis, Indiana
- Carmel, Indiana
- Fishers, Indiana

Target locations:
- Naples, Florida
- Fort Myers, Florida
- Bonita Springs, Florida
```

AI transforms all references correctly.

### Location Injection

For generic content with no location:

**Before:**
> "Our team provides excellent service..."

**After (Naples, Florida):**
> "Our Naples team provides excellent service to Collier County residents..."

### Real-Time Progress

```
Transforming: About Us Page
├── Creating backup... ✓
├── Extracting protected blocks... ✓
├── Transforming content with AI... ✓
├── Re-inserting protected blocks... ✓
├── Updating page... ✓
└── Complete!
```

### Undo Functionality

Restore original content:
- Access backup history
- One-click restore
- Preserves transformation log

## Settings

Access: **WP Admin → Geo Toolkit → Content Transformer**

**Pages to Transform:**
- Checkbox list of all pages
- Preview current content
- Batch selection

**Source Locations:**
- Current locations in content
- Multiple allowed
- Leave empty for generic content

**Target Locations:**
- New locations to inject
- One location per page typically
- Can map multiple sources → multiple targets

**Transformation Options:**
- Protect complex blocks
- Update SEO metadata
- Update schema markup

## In-Place vs New Pages

**Content Transformer:**
- ✅ Updates existing pages
- ✅ Preserves URLs
- ✅ Maintains page hierarchy
- ❌ Can't undo easily

**[[location-pages-generator]]:**
- ✅ Creates new pages
- ✅ Safe (doesn't touch originals)
- ❌ New URLs (redirects needed)
- ❌ Duplicate parent pages

**Choose Transformer when:**
- Relocating business
- Have established URLs
- Want to preserve SEO
- Trust the AI output

**Choose Generator when:**
- Expanding to new markets
- Starting fresh
- Want to test first
- Creating many variations

## Performance

- **Processing:** ~1-2 min/page
- **Cost:** ~$0.015/page (Claude API)
- **Memory:** ~5-10MB per page (backup storage)
- **Safety:** Automatic backups

## Troubleshooting

### Content Not Transforming

**Issue:** AI returns original content unchanged

**Causes:**
- Source location not in content
- Generic content with no location references
- Protected blocks covering entire page

**Solutions:**
- Use "inject location" mode
- Check source location spelling
- Review protected block settings

### Protected Blocks Breaking

**Issue:** FAQ schema or shortcodes corrupted

**Cause:** AI modified protected content

**Solution:**
- Add block type to protection list
- Use more specific regex patterns
- Restore from backup

## Code Location

- Main class: `WPGT_CT_Transformer`
- Files: `wpgt-content-transformer/includes/`
- GitHub: `13Guinness/wpgt-content-transformer`

## Related

- [[location-pages-generator]] — Create new pages instead
- [[geographic-transformation]] — Core transformation concept
- [[claude-ai-integration]] — AI transformation service
- [[location-data-structure]] — Updates metadata after transform

---

**Topics:**
- [[wp-geo-toolkit]]
- [[ai-content]]
- [[geographic-transformation]]
- [[wordpress]]
