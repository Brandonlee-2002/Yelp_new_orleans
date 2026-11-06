# Project requirements audit

Checked against `inference/yelp new orleans project instructions.qmd` on October 29, 2026, including its required deliverables and README checklist. The core analytical outputs are present, but the project is not yet a literal match to every instruction. This re-audit corrects the earlier blanket completion assessment. Status reflects inspected source and saved outputs; this audit did not rerun the full data pipeline or verify the current live deployment.

## Remaining work before submission

1. **Category preparation:** Step 3 (instruction line 323) explicitly requests one row per business-category combination and capitalization/whitespace cleaning before counting. `R/clean.R` currently splits categories into lists and trims whitespace, using case-sensitive labels. Create a normalized long-format category table and derive or cross-check category counts and co-occurrences from it. Existing counts are not proven incorrect; the specified workflow is missing.
2. **Use of dplyr:** The overview (line 119) specifies summaries and visualizations with `dplyr` and `ggplot2`. Plots use ggplot2, but project summaries currently use base R. Use dplyr for an actual category or geographic summary. Its presence as a transitive dependency in the lockfile does not demonstrate its use.
3. **Large-data narrative:** Lines 238 and 650 request downloading, extraction, storage, import problems, memory/disk limitations, and solutions. The methods explain paged imports, column selection, RDS storage, and the RStudio workaround. Expand the download/extraction and storage/temporary-file account, distinguishing observed problems from unmeasured limits. Do not invent memory measurements or incidents.
4. **Package documentation:** Line 178 requests additional packages in both the report and `renv.lock`. The lockfile is populated, but the report needs an explicit package-and-purpose list, including additional packages such as `ggrepel`.
5. **Top 10 versus top 15:** Deliverable 1 (line 648) asks for a top-10 answer and boundary map. The user requested a top 15, and all first ten are included in the current table and boundary map. Preserve the requested top 15, but add an explicitly labeled top-10 subset/view for literal assignment compliance. This is a presentation difference, not a missing ranking calculation.

These are targeted workflow and documentation changes, not evidence that the current restaurant rankings or area comparisons are wrong.

| Requirement | Status | Evidence or next action |
|---|---|---|
| Steps 1–2: import and clean the full New Orleans restaurant data | Complete within documented Yelp city-label scope | `R/import.R`, `R/clean.R`; 2,259 restaurants and 476,421 reviews retained from complete inputs |
| Step 3: at least three related categories and rationale | Complete | Four-category New Orleans cooking theme; explicit at-least-one inclusion rule |
| Step 3: counts and co-occurrence evidence | Complete | Initial and city-contained counts; six category pairs; `category_by_area.csv` |
| Step 3: long-format categories and capitalization cleaning | Partial | Whitespace trimming and token lists exist; normalized long-format table is missing |
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
| Assignment's explicitly labeled top-10 answer and map | Scope difference | First ten are included in the user-requested top 15; add a clearly labeled required subset/view |
| Main question, best area, final conclusions | Complete with qualified inference | Tito's Ceviche & Pisco leads; Ward 9 leads primary eligible-area comparison but is not a stable winner across alternatives; final report explains the conditional answer |
| Large-data management explanation | Partial | Import, RDS, and RStudio workaround documented; download/extraction and storage/temporary-file account needs expansion |
| dplyr summaries and ggplot2 visualizations | Partial | ggplot2 plots present; summaries use base R rather than the specified dplyr |
| Additional-package documentation | Partial | Lockfile present; report needs explicit package roles, including ggrepel |
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

`steps_3_to_6_validation.csv` records 12 passing cross-file/geographic checks. `final_validation.csv` records nine passing final eligibility, centering, ID, and coordinate checks. These saved checks were inspected during this re-audit. `environment_restore_check.csv` and `environment_restore_result.txt` preserve the previous environment verification and ranking reproduction. Prior HTML checks are separate from this source-and-output audit. The rendered visual story links to the full Results page, methods appendix, and AI log; the presentation adds no new statistical claims. Passing analytical checks do not establish that every instructional requirement is satisfied.

## Scope and limitations carried forward

The initial exact Yelp city filter can omit businesses labeled with another city even if their coordinates are inside the official city. This analysis does not claim to recover those businesses. The stricter 656-restaurant city subset is an explicit change from the 672-restaurant initial descriptive pool. No source records were deleted. The ward service snapshot was downloaded in 2026 and has no verified historical effective date. The two ward-unmatched city points remain in the city dataset, with ZCTA assignments and distance audits. The final ranking does not require ward membership: one eligible lakefront restaurant remains in the city ranking but outside ward aggregates, and neither unmatched location is in the top 15. No records are snapped.

## Professionalization pass — November 5, 2026

The remaining portfolio improvements are now implemented:

- normalized long-format category memberships and a `dplyr`-based category summary;
- explicit top-10 table and map alongside the top-15 result;
- fixed-seed, 500-replicate bootstrap stability tables for restaurants and wards;
- repository tests in `tests/`, a GitHub Actions quality workflow, and `Makefile` targets;
- architecture, data dictionary, analytical decision log, and decision-oriented summary;
- explicit package documentation, ethics/use limitations, and bootstrap interpretation notes.

`Rscript tests/test_pipeline.R` passes. The committed HTML pages remain available in `docs/`; local Quarto rendering was not re-run successfully in this environment because Quarto failed to open its cache database.

## Statistical hardening pass — November 5, 2026

The primary ranking now uses leave-one-review-out reviewer baselines. The source contains 4,766 repeated `(user_id, business_id)` pairs, so these are audited in `duplicate_user_business_pairs.csv`; the analysis does not assume Yelp's one-review-per-business behavior. The LOO top restaurant remains Tito's Ceviche & Pisco. Ward 9 remains the highest mean among rankable wards at approximately +0.093, but the 10,000-replicate max-selection permutation test gives p = 0.2703, so it is not statistically distinguished.

Additional regenerated diagnostics include 1,000-replicate rank uncertainty, empirical-Bayes shrinkage, lower-confidence-bound ranking, closed-business and strict-core-cuisine scenarios, selection-versus-adjustment comparisons, split-half reliability, ward bootstrap intervals, and an explicit mixed-model skip record because `lme4` is not installed. Split-half reliability was lower for adjusted scores than raw scores in this diagnostic (0.752 versus 0.769); the report treats that as a limitation rather than claiming adjustment improves reliability.
