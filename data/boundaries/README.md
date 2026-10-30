# Official geographic boundary inputs

Downloaded October 29, 2026 using `R/download_boundaries.R`. `sources.json` records source URLs, scope, and SHA-256 checksums for the saved inputs.

- `louisiana_places_2020.geojson`: Census 2020 TIGER/Line Louisiana place polygons, obtained through `tigris::places(cb = FALSE)`.
- `zctas_2020_prefix70.geojson`: Census 2020 cartographic ZCTAs at 1:500,000 scale, obtained through `tigris::zctas(cb = TRUE, starts_with = "70")`. The analysis selects polygons intersecting New Orleans. This regional file is not all U.S. ZCTAs.
- `new_orleans_wards.geojson`: all 17 features from City of New Orleans Enterprise GIS Administrative Layers, Wards layer 3, queried with all attributes and output CRS EPSG:4326. `wards_metadata.json` is the saved layer metadata. The service does not establish a historical effective date; this snapshot must not be described as verified 2020 ward boundaries.
- `analysis_boundaries.gpkg`: derived analysis layers created by `R/geography.R` in EPSG:26982. Input polygons are repaired with `st_make_valid()` and transformed to a local projected CRS for joins.

Re-run `Rscript R/download_boundaries.R` only when inputs are missing. It preserves existing snapshots. The wards endpoint can change over time, so a fresh download may differ; the committed snapshot is the source for these results. No nearest-area snapping is used. Boundary and coordinate discrepancies are retained in CSV audit tables.
