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

## Pending analysis decisions

Filtering the complete review file (6,990,280 records) retained **250,304 reviews** for the 672 selected restaurants. Every selected restaurant has reviews and coordinates. Of these businesses, **435 are marked open** in the historical snapshot; this does not verify current operating status. Selected review dates span March 2005 through January 2022. Full filter metrics are saved in `data/new_orleans/cooking_filter_summary.json`.

- Compare the selected systems: **ZIP Code Tabulation Areas (ZCTAs) and New Orleans wards**. Assign restaurant coordinates to official boundaries for each system, then compare restaurant counts, unmatched locations, ratings, and small-area sample sizes. Yelp postal codes alone do not establish ZCTA membership.
- Choose the final geographic system after this comparison and confirm at least seven areas contain qualifying restaurants.
- Define “best” using review volume, raw ratings, and reviewer-adjusted scores before selecting the top 15.
- Decide whether the final recommendation ranking should exclude businesses marked closed in this historical dataset.
- Produce a final table of 15 restaurants and a boundary map showing their locations.

The instructor's source document specifies a top 10; this project uses **top 15** following the user's direction. The original inference instructions remain unchanged.

## Reproduce the filtering

Run `Rscript R/import.R` from the repository root with `jsonlite` installed and both raw JSON files present. The script reads the complete business and review files, retains all New Orleans restaurant reviews, and saves separate theme-specific outputs. It generates category counts, pair counts, and a filter summary in `data/new_orleans/`.
