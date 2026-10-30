# Project completion audit

Checked against `inference/yelp new orleans project instructions.qmd` on October 29, 2026. Status reflects completed outputs, not planned work. The user requested a top 15; the instructor's document specifies a top 10. This project follows the user's top-15 direction.

| Requirement | Status | Evidence or next action |
|---|---|---|
| Steps 1–2: import and clean the full New Orleans restaurant data | Complete within documented Yelp city-label scope | `R/import.R`, `R/clean.R`; 2,259 restaurants and 476,421 reviews retained from complete inputs |
| Step 3: at least three related categories and rationale | Complete | Four-category New Orleans cooking theme; explicit at-least-one inclusion rule |
| Step 3: counts and co-occurrence evidence | Complete | Initial and city-contained counts; six category pairs; `category_by_area.csv` |
| Step 3: at least 10 restaurants in at least seven areas | Complete | 656 city-contained restaurants; 17 populated ZCTAs and 17 populated wards |
| Step 4: filter and join reviews by business_id | Complete | 250,304 rows before and after the initial review-level join, unique review IDs, no unmatched businesses; local `reviews_cooking_joined.rds` and `review_join_audit.csv` |
| Step 5: spatial join to official city/place polygons | Complete | All 2,259 restaurants joined to 2020 Census Louisiana places; 57 other-place labels investigated through exported names and coordinates |
| Step 5: investigate city-label mismatches | Complete as an audit; causes not independently verified | 16 theme restaurants outside the city retained in `cooking_outside_city.csv`, with distances and matched place names; 656 kept in the city-only comparison |
| Step 6: compare at least two geographic systems | Complete | Official ZCTA and ward joins; complete area counts, raw means, review totals, missing assignments, sparse areas, maps, and comparison table |
| Step 6: defend the main geographic system | Complete | Wards selected for more balanced sample sizes; two shoreline gaps documented; ZCTA results retained |
| Step 7: all reviewers vs selected reviewers | Complete | 138,367 reviewers in the city pool; five-review threshold retains 7,066 reviewers and 59,584 reviews; raw and selected-reviewer means exported |
| Step 7: mean/median baselines and normalization | Complete | Both baselines computed; primary mean-based deviations centered at zero per reviewer; `reviewer_adjusted_restaurants.csv` |
| Step 7: sensitivity and ranking changes | Complete | Activity 3/5/10, restaurant volume 25/50/100, distinct-reviewer minima 10/20/30, median baselines, raw comparison, and area minima 5/10/15; ranking and area sensitivity exports |
| Final top-15 restaurant table and map | Complete | `top_15_restaurants.csv`, numbered `final_top_15_map.png`; all 15 assigned to wards; eligibility checks passed |
| Main question, best area, final conclusions | Complete with qualified inference | Tito's Ceviche & Pisco leads; Ward 9 leads primary eligible-area comparison but is not a stable winner across alternatives; final report explains the conditional answer |
| Large-data management explanation | Complete for documented experience | Page/chunk import, column selection, saved RDS, RStudio unresponsiveness and separate-process workaround; actual cause not measured |
| At least three informative visualizations, including a map | Complete | Three initial plots, seven geographic maps/plots, and four final ranking/location figures |
| Viewable README and rendered HTML | Complete | Option 2 plus GitHub Pages in `docs/`; source and results committed without raw JSON |
| Data-source and boundary provenance | Complete | Saved source GeoJSON, ward metadata, source URLs, checksums, CRS and vintage limitations |
| AI prompts and reprompt examples | Complete to current stage | `ai-log.qmd` and rendered log; includes prompt corrections and verification status |
| Reproducible dependency environment | Complete | Populated lockfile, compatible Rcpp for units, isolated restore/version checks, and identical top-15 IDs regenerated; native-library prerequisites documented |

## Final specification

- Dataset: 656 city-contained restaurants, 249,002 reviews, and 138,367 distinct reviewers.
- Primary reviewers: at least five reviews within the city/category group; mean baseline is primary and median is a sensitivity alternative.
- Restaurant eligibility: historical open flag, at least 50 all-review records, at least 20 distinct eligible reviewers; 288 qualify.
- Area eligibility: at least ten final-eligible restaurants; ten wards qualify. Equal restaurant weights are used for area means.
- Ward 9 leads the primary area analysis, but only three of ten area specifications including the primary. The report does not claim an invariant or statistically proven best ward.
- Current operating status remains unverified; this is a limitation of the historical analysis rather than an unfinished project deliverable.

## Verification evidence

`steps_3_to_6_validation.csv` records 12 passing cross-file/geographic checks. `final_validation.csv` records nine passing final eligibility, centering, ID, and coordinate checks. `environment_restore_check.csv` records all locked package version checks; `environment_restore_result.txt` records the independent restore and ranking reproduction. HTML link, navigation, embedded-figure, and responsive-table checks accompany the rendered pages. A visual-story landing page now links to the full Results page, methods appendix, and AI log; the presentation adds no new statistical claims.

## Scope and limitations carried forward

The initial exact Yelp city filter can omit businesses labeled with another city even if their coordinates are inside the official city. This analysis does not claim to recover those businesses. The stricter 656-restaurant city subset is an explicit change from the 672-restaurant initial descriptive pool. No source records were deleted. The ward service snapshot was downloaded in 2026 and has no verified historical effective date. The two ward-unmatched city points remain in the city dataset, with ZCTA assignments and distance audits. The final ranking does not require ward membership: one eligible lakefront restaurant remains in the city ranking but outside ward aggregates, and neither unmatched location is in the top 15. No records are snapped.
