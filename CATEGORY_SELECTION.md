# Selected theme: New Orleans cooking

The analysis will identify the **top 15 restaurants** for New Orleans cooking and compare geographic areas after filtering.

## Categories and rationale

| Category | Restaurants |
|---|---:|
| Cajun/Creole | 401 |
| Seafood | 331 |
| Southern | 155 |
| Soul Food | 70 |

These categories connect regional cooking traditions and seafood dining. This is an operational theme based on Yelp labels; inclusion does not establish that every menu is uniquely New Orleans cuisine.

## Inclusion rule

Use businesses with Yelp city `New Orleans`, state `LA`, and the exact `Restaurants` category token. Include a business if it matches **at least one** selected category. The union contains **672 unique restaurants**; counts above overlap and must not be summed. Keep both open and closed businesses initially, with `is_open` available for a later decision about recommendation eligibility. No minimum rating or review count is imposed during filtering.

## Co-occurrence evidence

| Category pair | Restaurants carrying both labels |
|---|---:|
| Cajun/Creole + Seafood | 156 |
| Cajun/Creole + Southern | 72 |
| Cajun/Creole + Soul Food | 30 |
| Seafood + Southern | 45 |
| Seafood + Soul Food | 20 |
| Southern + Soul Food | 19 |

The category overlaps support examining these labels as one related group. Matching all four labels is not required.

## Final analysis decisions

Filtering the complete review file (6,990,280 records) retained **250,304 reviews** for the 672 selected restaurants. Every selected restaurant has reviews and coordinates. Of these businesses, **435 are marked open** in the historical snapshot; this does not verify current operating status. Selected review dates span March 2005 through January 2022. Full filter metrics are saved in `data/new_orleans/cooking_filter_summary.json`.

- **City-boundary check complete:** 656 theme restaurants and 249,002 reviews remain inside Census New Orleans; 16 outside-city restaurants are retained in the mismatch audit. City-contained category counts are Cajun/Creole 398, Seafood 320, Southern 150, and Soul Food 69.
- **Seven-area requirement met:** the city-contained group occupies 17 ZCTAs and all 17 wards.
- **Main geography: wards.** Wards have a median of 25 restaurants per populated area versus 16 for ZCTAs; only one ward has fewer than 10 restaurants versus five populated ZCTAs. Wards assign 654 of 656 locations; two lakefront points remain unmatched and are documented. ZCTAs assign all 656 and remain the sensitivity comparison.
- See `data/analysis/geography_comparison.csv`, `data/analysis/category_by_area.csv`, and the report for maps, area summaries, scope decisions, and source dates.
- **Ranking complete:** historical open flag, at least 50 available reviews, and at least 20 distinct reviewers who each have five city/category reviews. Rank 288 eligible restaurants by mean-baseline adjusted score; retain a top 15.
- **Open-status decision:** businesses marked closed remain in descriptive audits but are excluded from the final ranking. Current operation has not been independently verified.
- **Final outputs complete:** top-15 table and numbered ward map, mean and median baselines, reviewer/restaurant threshold sensitivity, and a conditional Ward 9 area recommendation. No ward is a stable winner across all alternatives.

The instructor's source document specifies a top 10; this project uses **top 15** following the user's direction. The original inference instructions remain unchanged.

## Reproduce the filtering

Run `Rscript R/import.R` from the repository root with `jsonlite` installed and both raw JSON files present. The script reads the complete business and review files, retains all New Orleans restaurant reviews, and saves separate theme-specific outputs. It generates category counts, pair counts, and a filter summary in `data/new_orleans/`.
