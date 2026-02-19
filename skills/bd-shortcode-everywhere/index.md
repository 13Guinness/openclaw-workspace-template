---
description: BD Shortcode Everywhere — WordPress plugin that processes shortcodes in all Breakdance Builder element output. Drop-in solution, zero configuration. Enables shortcodes in headings, text, buttons where Breakdance normally blocks them.
kind: skill-graph
topics: ["[[wordpress]]", "[[breakdance]]", "[[shortcodes]]"]
---

# BD Shortcode Everywhere

WordPress plugin that enables shortcodes in Breakdance Builder elements.

## The Problem

**Breakdance blocks shortcodes in most elements:**
- Headings: `[year]` doesn't work
- Text blocks: `[site_name]` ignored
- Buttons: `[phone]` stays literal

**Why?** Breakdance processes content through Twig, which escapes shortcodes before WordPress can run them.

## The Solution

**BD Shortcode Everywhere** hooks into Breakdance's rendering pipeline and processes shortcodes **before** Twig rendering.

**Result:**
- `[year]` → `2026`
- `[site_name]` → `Your Site Name`
- `[phone]` → `(555) 123-4567`

All work in any Breakdance element.

## How It Works

### Hook Position
```
Breakdance Element Properties
  ↓
BD Shortcode Everywhere Hook
  ↓
do_shortcode() on all text properties
  ↓
Twig Rendering (shortcodes already processed)
  ↓
HTML Output
```

### Technical Implementation

Uses Breakdance filter: `breakdance_element_properties`

```php
add_filter('breakdance_element_properties', function($properties) {
    // Walk through all properties
    // Process shortcodes in text fields
    // Return modified properties
}, 10, 1);
```

## Supported Shortcodes

**Works with ALL WordPress shortcodes:**
- Core WP shortcodes: `[caption]`, `[gallery]`, etc.
- Custom shortcodes from plugins
- Your own shortcodes
- Dynamic shortcodes (ACF, etc.)

**Common use cases:**
- `[year]` — Current year (copyright)
- `[site_name]` — Site title
- `[phone]` — Business phone
- `[email]` — Contact email
- `[current_user]` — User info
- `[acf field="field_name"]` — ACF fields

## Installation

### Zero Configuration

1. Upload to `/wp-content/plugins/bd-shortcode-everywhere/`
2. Activate
3. **That's it.** No settings page.

Shortcodes immediately work in all Breakdance elements.

## Use Cases

### Dynamic Copyright Year
**Breakdance heading:**
```
© [year] Your Company. All rights reserved.
```

**Output:**
```
© 2026 Your Company. All rights reserved.
```

Auto-updates every year.

### Contact Info Shortcodes
**Breakdance button:**
```
Call [phone]
```

**Output:**
```
Call (555) 123-4567
```

Change phone once (shortcode definition), updates everywhere.

### User-Specific Content
**Breakdance text:**
```
Welcome back, [current_user]!
```

**Output:**
```
Welcome back, Matt!
```

Personalized content in Breakdance.

### ACF Integration
**Breakdance text:**
```
Location: [acf field="office_address"]
```

**Output:**
```
Location: 123 Main St, Naples FL
```

Pull ACF data into Breakdance elements.

## Performance

**Overhead:** ~0.1ms per element with shortcodes

**Why negligible:**
- Only processes text properties
- Skips non-text elements
- No database queries
- Pure PHP processing

## Compatibility

**Works with:**
- Breakdance 1.x - 2.x
- WordPress 6.0+
- PHP 7.4+
- All shortcode plugins

**Tested on:**
- WP Engine
- Kinsta
- Standard shared hosting

## Limitations

### What Works
- Text content in any element
- Simple shortcodes
- Nested shortcodes
- Dynamic shortcodes

### What Doesn't
- Complex shortcodes with HTML output (may break Twig)
- Shortcodes that modify query context
- Shortcodes that enqueue scripts mid-render

**Workaround:** Use shortcodes that return plain text only.

## Troubleshooting

### Shortcode Not Processing

**Check:**
1. Plugin activated?
2. Shortcode defined correctly?
3. Test shortcode outside Breakdance (in classic editor)
4. Check for PHP errors

### Output Breaking Layout

**Cause:** Shortcode returning complex HTML

**Fix:**
- Simplify shortcode output (plain text)
- Use Breakdance native elements instead
- Test in isolation

## Code Location

- Repo: `13Guinness/bd-shortcode-everywhere`
- Local: `~/.openclaw/workspace/bd-shortcode-everywhere/`
- WordPress: `/wp-content/plugins/bd-shortcode-everywhere/`

## Version

**Current:** v1.3.0

**Changelog:**
- v1.0: Initial release
- v1.2: Recursive property walking
- v1.3: Performance optimization

## Development

### File Structure
```
bd-shortcode-everywhere/
├── bd-shortcode-everywhere.php  # Main plugin file (~50 lines)
└── README.md
```

Ultra-lightweight — single file, no dependencies.

## Related

- [[breakdance]] — Page builder
- [[wordpress-shortcodes]] — Shortcode API
- [[wp-geo-toolkit]] — Uses shortcodes for dynamic content

---

**Topics:**
- [[wordpress]]
- [[breakdance]]
- [[shortcodes]]
- [[drop-in-plugins]]
