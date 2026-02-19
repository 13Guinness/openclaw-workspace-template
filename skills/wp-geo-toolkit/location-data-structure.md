---
description: Location data structure — WordPress page metadata schema for storing geographic information. Enables queries, sorting by distance, SEO optimization, and service area calculations. Every location page stores city, state, county, and coordinates.
kind: concept
topics: ["[[wp-geo-toolkit]]", "[[wordpress]]", "[[geolocation]]"]
---

# Location Data Structure

WordPress page metadata schema for storing geographic information.

## Metadata Fields

Every location page stores:

```php
_wpgt_location: "Naples, Florida"    // Primary identifier
_wpgt_city: "Naples"                 // City name
_wpgt_state: "Florida"               // Full state name
_wpgt_state_abbr: "FL"               // State abbreviation
_wpgt_county: "Collier"              // County name
_wpgt_latitude: "26.1420"            // Latitude (decimal)
_wpgt_longitude: "-81.7948"          // Longitude (decimal)
```

## Why This Structure

### 1. Queryable
Find all pages for a specific location:

```php
$florida_pages = get_posts([
    'post_type' => 'page',
    'meta_query' => [
        [
            'key' => '_wpgt_state',
            'value' => 'Florida'
        ]
    ]
]);
```

### 2. Sortable
Order pages by distance from user:

```php
$user_lat = 26.1420;
$user_lon = -81.7948;

// Get all location pages
$pages = get_location_pages();

// Calculate distances
foreach ($pages as &$page) {
    $page['distance'] = wpgt()->get_proximity()->calculate_distance(
        $user_lat, $user_lon,
        get_post_meta($page['ID'], '_wpgt_latitude', true),
        get_post_meta($page['ID'], '_wpgt_longitude', true)
    );
}

// Sort by distance
usort($pages, fn($a, $b) => $a['distance'] <=> $b['distance']);
```

### 3. SEO Optimization

Used in meta tags and schema:

```html
<meta name="geo.position" content="26.1420;-81.7948">
<meta name="geo.placename" content="Naples, Florida">
<meta name="geo.region" content="US-FL">
```

Schema markup:
```json
{
  "@type": "LocalBusiness",
  "address": {
    "@type": "PostalAddress",
    "addressLocality": "Naples",
    "addressRegion": "FL",
    "addressCountry": "US"
  },
  "geo": {
    "@type": "GeoCoordinates",
    "latitude": "26.1420",
    "longitude": "-81.7948"
  }
}
```

### 4. Service Area Calculations

Determine if customer is in service area:

```php
$customer_coords = geocode($customer_address);
$office_coords = [
    'lat' => get_post_meta($page_id, '_wpgt_latitude', true),
    'lon' => get_post_meta($page_id, '_wpgt_longitude', true)
];

$distance = wpgt()->get_proximity()->calculate_distance(
    $customer_coords['latitude'],
    $customer_coords['longitude'],
    $office_coords['lat'],
    $office_coords['lon']
);

if ($distance <= 50) {
    echo "We serve your area!";
}
```

## How It's Populated

### 1. During Page Generation

[[location-pages-generator]] creates pages with metadata:

```php
// Geocode location
$geo_data = wpgt()->get_geocoder()->geocode('Naples, Florida');

// Store metadata
update_post_meta($page_id, '_wpgt_location', 'Naples, Florida');
update_post_meta($page_id, '_wpgt_city', $geo_data['city']);
update_post_meta($page_id, '_wpgt_state', $geo_data['state']);
update_post_meta($page_id, '_wpgt_state_abbr', $geo_data['state_abbr']);
update_post_meta($page_id, '_wpgt_county', $geo_data['county']);
update_post_meta($page_id, '_wpgt_latitude', $geo_data['latitude']);
update_post_meta($page_id, '_wpgt_longitude', $geo_data['longitude']);
```

### 2. During Content Transformation

[[content-transformer]] updates metadata when transforming:

```php
// Before: Indianapolis, Indiana
// After: Naples, Florida

// Geocode new location
$new_geo = wpgt()->get_geocoder()->geocode($target_location);

// Update all metadata fields
update_post_meta($page_id, '_wpgt_location', $target_location);
update_post_meta($page_id, '_wpgt_city', $new_geo['city']);
// ... etc
```

## Accessing the Data

### Get Location String

```php
$location = get_post_meta($page_id, '_wpgt_location', true);
echo $location; // "Naples, Florida"
```

### Get Full Location Data

```php
$location_data = [
    'location' => get_post_meta($page_id, '_wpgt_location', true),
    'city' => get_post_meta($page_id, '_wpgt_city', true),
    'state' => get_post_meta($page_id, '_wpgt_state', true),
    'state_abbr' => get_post_meta($page_id, '_wpgt_state_abbr', true),
    'county' => get_post_meta($page_id, '_wpgt_county', true),
    'latitude' => get_post_meta($page_id, '_wpgt_latitude', true),
    'longitude' => get_post_meta($page_id, '_wpgt_longitude', true),
];
```

### Check if Page Has Location Data

```php
function is_location_page($page_id) {
    return !empty(get_post_meta($page_id, '_wpgt_location', true));
}
```

## Use Cases

### Multi-Location Service Finder

Build "Find Your Nearest Location" feature:

1. Get user's coordinates (browser geolocation or address)
2. Query all location pages
3. Calculate distances using [[proximity-calculator]]
4. Sort by distance
5. Display nearest 5 locations

### Dynamic Service Area Display

Show service coverage on map:

```php
$locations = get_posts([
    'post_type' => 'page',
    'meta_query' => [[
        'key' => '_wpgt_latitude',
        'compare' => 'EXISTS'
    ]]
]);

foreach ($locations as $loc) {
    $lat = get_post_meta($loc->ID, '_wpgt_latitude', true);
    $lon = get_post_meta($loc->ID, '_wpgt_longitude', true);
    
    // Add marker to map
    echo "addMarker({$lat}, {$lon}, '{$loc->post_title}');";
}
```

### State-Specific Archives

Create archive pages for each state:

```php
// template: archive-state-florida.php
$florida_pages = get_posts([
    'post_type' => 'page',
    'posts_per_page' => -1,
    'meta_query' => [[
        'key' => '_wpgt_state',
        'value' => 'Florida'
    ]]
]);
```

## Data Validation

### On Save

Validate coordinates are valid:

```php
$lat = get_post_meta($page_id, '_wpgt_latitude', true);
$lon = get_post_meta($page_id, '_wpgt_longitude', true);

if ($lat < -90 || $lat > 90) {
    wpgt_log("Invalid latitude: {$lat}");
}

if ($lon < -180 || $lon > 180) {
    wpgt_log("Invalid longitude: {$lon}");
}
```

### On Query

Handle missing data gracefully:

```php
$locations = get_location_pages();

foreach ($locations as $loc) {
    if (!$loc['latitude'] || !$loc['longitude']) {
        // Re-geocode if missing
        $geo = wpgt()->get_geocoder()->geocode($loc['location']);
        update_post_meta($loc['ID'], '_wpgt_latitude', $geo['latitude']);
        update_post_meta($loc['ID'], '_wpgt_longitude', $geo['longitude']);
    }
}
```

## Performance Considerations

### Indexing

WordPress automatically indexes meta_key for queries. For large sites (1000+ locations), consider:

```sql
CREATE INDEX idx_wpgt_state ON wp_postmeta(meta_key, meta_value(20))
WHERE meta_key = '_wpgt_state';
```

### Caching

Cache expensive distance calculations:

```php
$cache_key = "nearest_to_{$user_lat}_{$user_lon}";
$nearest = get_transient($cache_key);

if (!$nearest) {
    $nearest = calculate_nearest_locations($user_lat, $user_lon);
    set_transient($cache_key, $nearest, HOUR_IN_SECONDS);
}
```

## Code Location

- Metadata written in: `WPGT_LP_Page_Generator`, `WPGT_CT_Transformer`
- Core plugin: `wp-geo-toolkit/includes/`
- GitHub: `13Guinness/wp-geo-toolkit`

## Related

- [[geocoding-service]] — Populates the coordinate data
- [[proximity-calculator]] — Uses coordinates for distance calc
- [[location-pages-generator]] — Creates pages with this structure
- [[content-transformer]] — Updates structure when transforming

---

**Topics:**
- [[wp-geo-toolkit]]
- [[wordpress]]
- [[geolocation]]
- [[data-structures]]
