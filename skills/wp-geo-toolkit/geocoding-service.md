---
description: Geocoding service — converts "City, State" into coordinates and location metadata using Google Geocoding API (primary) with built-in fallback database
kind: core-service
topics: ["[[wp-geo-toolkit]]", "[[geolocation]]"]
---

# Geocoding Service

Converts "City, State" strings into detailed location data.

## Data Sources

1. **Google Geocoding API** (optional, recommended)
   - Most accurate
   - Handles edge cases, typos
   - Requires API key

2. **Built-in database** (fallback)
   - US states and major counties
   - No API key needed
   - Lower accuracy

3. **Caching layer**
   - 1-hour cache
   - Reduces API calls
   - Improves performance

## Returns

```php
[
    'city' => 'Naples',
    'state' => 'Florida',
    'state_abbr' => 'FL',
    'county' => 'Collier',
    'latitude' => 26.1420,
    'longitude' => -81.7948
]
```

## Usage

```php
$geocoder = wpgt()->get_geocoder();
$data = $geocoder->geocode('Naples, Florida');

if ($data) {
    echo "Coordinates: {$data['latitude']}, {$data['longitude']}";
    echo "County: {$data['county']}";
}
```

## Input Format

**Required format:** `"City, State"`

**Examples:**
- ✅ "Naples, Florida"
- ✅ "Indianapolis, Indiana"  
- ✅ "New York, New York"
- ❌ "Naples FL" (missing comma)
- ❌ "Naples" (missing state)

## Google API Setup

1. Get key from [Google Cloud Console](https://console.cloud.google.com)
2. Enable Geocoding API
3. Add to: WP Admin → Geo Toolkit → Settings
4. Optional but recommended

## Fallback Behavior

When Google API unavailable:
1. Parse state name/abbreviation
2. Lookup in built-in database
3. Use state centroid for coordinates
4. Less accurate but functional

## Error Handling

**"Could not geocode location":**
- Check format: "City, State"
- Verify Google API key
- Check API quota/billing
- Review debug logs

## Performance

- First call: API request (~200ms)
- Cached calls: Database lookup (~5ms)
- Cache duration: 1 hour
- Cache storage: WordPress transients

## Code Location

- Class: `WPGT_Geocoder`
- File: `wp-geo-toolkit/includes/class-geocoder.php`
- GitHub: `13Guinness/wp-geo-toolkit`

## Use Cases

- [[location-pages-generator]] — Geocode each location before page creation
- [[proximity-calculator]] — Requires coordinates to calculate distances
- [[location-data-structure]] — Populates coordinate metadata

## Related

- [[proximity-calculator]] — Uses geocoding results
- [[google-api-setup]] — Configuration guide
- [[troubleshooting]] — Geocoding errors

---

**Topics:**
- [[wp-geo-toolkit]]
- [[geolocation]]
- [[google-api]]
