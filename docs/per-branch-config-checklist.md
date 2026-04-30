# Per-branch `_config.yml` checklist

This checklist documents the values that **must differ** when the master
branch (Lafayette) is propagated to the three EMD branches:

- `lakecharlesphotobooth.com`
- `batonrougephotobooth.rentals`
- `alexandriaphotobooth.com`

Code (templates, plugins, schema partials, includes) propagates as-is.
Content data (`_data/*.yml`, `_posts/*`, `_pages/*`) propagates as-is unless
the branch needs different content. The values below are the only
required per-branch divergences in `_config.yml`.

---

## Required changes per EMD branch

### 1. Identity

```yaml
url: https://[domain]
name: "Ohh Snap Booth — [City]"
description: >-
  Ohh Snap! Photo Booth offers modern photo booth and 360 booth rentals
  in [City], LA, and surrounding areas. Perfect for weddings, corporate
  events, and parties.
location: [City]
```

### 2. Schema mode flag

```yaml
is_primary_location: false   # ONLY true on master/Lafayette
```

When `false`, `_includes/seo.html` emits `Service` schema with `provider`
referencing the Lafayette `LocalBusiness`, instead of claiming a phantom
`LocalBusiness` for an address the EMD doesn't have. This is the most
important schema fix — see `_includes/schema/service-business.html`.

### 3. Address (only if a real address exists)

```yaml
address:
  street:  ""        # leave blank if no real address
  city:    ""
  region:  "LA"
  zip:     ""
  country: "US"
latitude:  ""        # leave blank if no real address
longitude: ""
```

**Important:** if Carlos does NOT have a real local entity in this city,
leave these blank. Do NOT copy Lafayette's address. The `Service`
schema (used when `is_primary_location: false`) handles the no-address
case correctly. Future state: when an EMD lessee comes online with a
real local entity, populate these and flip `is_primary_location: true`.

### 4. Suburbs (`local_keywords`)

These drive the auto-generated `/locations/<city>/` pages and the
`Service.areaServed` schema array. Each branch's list should reflect
that city's metro area, not Acadiana villages.

**Lake Charles branch:**
```yaml
local_keywords:
  - Sulphur
  - Westlake
  - Moss Bluff
  - Iowa
  - DeRidder
  - Lake Arthur
  - Welsh
  - Vinton
```

**Baton Rouge branch:**
```yaml
local_keywords:
  - Prairieville
  - Denham Springs
  - Zachary
  - Baker
  - Central
  - Gonzales
  - Walker
  - Geismar
  - St. Francisville
  - New Roads
```

**Alexandria branch:**
```yaml
local_keywords:
  - Pineville
  - Ball
  - Tioga
  - Boyce
  - Marksville
  - Natchitoches
  - Leesville
  - Cottonport
  - Bunkie
```

### 5. Cross-branch links (`alt_location`)

```yaml
alt_location:
  - location: Lafayette
    url: https://ohhsnapbooth.com
  - location: [Other branch 1]
    url: https://[other-domain-1]
  - location: [Other branch 2]
    url: https://[other-domain-2]
```

Each branch lists the OTHER three. Lafayette already lists all three
EMDs; each EMD should list Lafayette + the other two EMDs.

### 6. Open Graph image

```yaml
og_image: /assets/img/[city]-og-image.jpg
```

City-specific OG image preferred. If not available yet, falling back to
Lafayette's `default-og-image.jpg` is acceptable temporarily.

---

## Required changes outside `_config.yml`

### `_data/locations.yml`

Each EMD branch should have its own `_data/locations.yml` with overrides
for that branch's suburbs (the cities listed in step 4 above). Master's
`_data/locations.yml` is for Acadiana villages and isn't useful on EMDs.

If Carlos has no local content yet for the EMD's suburbs, the file can
stay empty (`[]`) — the `/locations/<city>/` pages will still generate
with default copy. They just won't have unique per-city content yet.

### `_data/testimonial.yml`

Currently used by Lafayette's `LocalBusiness` schema. Reviews are
**already gated** to the primary location only (Phase 3d), so EMD
branches won't emit review schema regardless of what's in this file.
When EMD branches eventually have real local testimonials, drop them
in this file on the EMD branch — once that branch's
`is_primary_location` becomes `true`, the schema will pick them up.

---

## Values that should NOT change per branch

- `social.links` — same Twitter/Facebook/Pinterest/Instagram/YouTube/
  LinkedIn brand handles network-wide
- `google_analytics`, `google_site_verification`, `bing_site_verification`
  — these may need per-property values in GSC/GA but are
  property-level config, not code; check those externally
- All collection definitions (`products`, `wedding`, `coordinators`,
  `booths`, `event_type`)
- All plugins
- `payment_accepted`, `opening_hours`, `weekday`/`weekend` blocks,
  `price_range`, `rating_value` (network-wide rating)
- `phone` (currently a network number; if the EMDs ever get local
  numbers, this becomes a per-branch value)

---

## Quick-merge propagation steps (for Carlos)

When merging master → an EMD branch:

1. Pull master into the EMD branch.
2. In `_config.yml`, verify or update:
   - `url`, `name`, `description`, `location`
   - `is_primary_location: false`
   - `address` block (blank or real, never Lafayette's)
   - `latitude` / `longitude` (blank or real)
   - `local_keywords` list (city's metro)
   - `alt_location` list
   - `og_image` (if a city-specific one exists)
3. Update `_data/locations.yml` to match the new `local_keywords` list
   (or leave empty until content is written).
4. Build locally and spot-check:
   - The schema on the homepage is `Service` (not `LocalBusiness`)
   - The schema's `provider.@id` is `https://ohhsnapbooth.com/#localbusiness`
   - The schema has no `aggregateRating` or `review` block
   - The `/locations/<city>/` pages reflect the new suburb list
5. Push.
