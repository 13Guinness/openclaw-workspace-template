---
description: Proximity calculator — calculates distances between coordinates using Haversine formula, accounting for Earth's curvature. Used for service areas, nearest location features, and overlap detection.
kind: core-service
topics: ["[[wp-geo-toolkit]]", "[[geolocation]]"]
---

# Proximity Calculator

Calculates distances between geographic coordinates using the Haversine formula.

## Algorithm: Haversine Formula

Accounts for Earth's curvature when calculating distances between two points on a sphere.

**Why not Euclidean distance?**
- Earth is round, not flat
- Straight-line distance would be inaccurate
- Matters at distances >10 miles

**Accuracy:**
- Within ~0.5% of actual distance
- Good enough for service area calculations
- Better than zip code radius

## Usage

```php
$proximity = wpgt()->get_proximity();

$distance = $proximity->calculate_distance(
    26.1420, -81.7948,  // Naples, FL
    27.3364, -82.5307   // Sarasota, FL
);

echo $distance; // ~72.3 miles
```

## Use Cases

### 1. Multi-Office Service Areas
Determine which office serves which territory:
```php
$offices = get_office_locations();
$customer_coords = geocode($customer_address);

$nearest = null;
$min_distance = PHP_INT_MAX;

foreach ($offices as $office) {
    $distance = $proximity->calculate_distance(
        $customer_coords['latitude'],
        $customer_coords['longitude'],
        $office['latitude'],
        $office['longitude']
    );
    
    if ($distance < $min_distance) {
        $min_distance = $distance;
        $nearest = $office;
    }
}
```

### 2. "Other Areas We Serve" Links
[[location-pages-generator]] uses this to find the 8 nearest locations for cross-linking:

```php
$nearby = $proximity->find_nearest_locations(
    $current_location, 
    $all_locations, 
    8
);
```

### 3. Service Area Overlap Detection
Identify locations with overlapping service areas (e.g., within 20 miles):

```php
foreach ($locations as $loc1) {
    foreach ($locations as $loc2) {
        if ($loc1 === $loc2) continue;
        
        $distance = $proximity->calculate_distance(
            $loc1['latitude'], $loc1['longitude'],
            $loc2['latitude'], $loc2['longitude']
        );
        
        if ($distance < 20) {
            echo "{$loc1['city']} overlaps with {$loc2['city']}";
        }
    }
}
```

## Performance

- **Computation:** ~0.01ms per calculation
- **Bottleneck:** Usually the looping, not the math
- **Optimization:** Pre-filter by bounding box before calculating exact distances

## Mathematical Details

**Formula:**
```
a = sin²(Δlat/2) + cos(lat1) × cos(lat2) × sin²(Δlon/2)
c = 2 × atan2(√a, √(1−a))
distance = radius × c
```

Where:
- `Δlat` = difference in latitudes (radians)
- `Δlon` = difference in longitudes (radians)
- `radius` = Earth's radius (~3,959 miles)

## Code Location

- Class: `WPGT_Proximity`
- File: `wp-geo-toolkit/includes/class-proximity.php`
- GitHub: `13Guinness/wp-geo-toolkit`

## Related

- [[geocoding-service]] — Provides coordinates for calculation
- [[location-pages-generator]] — Uses proximity for linking nearby pages
- [[location-data-structure]] — Stores coordinates in page metadata

---

**Topics:**
- [[wp-geo-toolkit]]
- [[geolocation]]
- [[algorithms]]
