# Yelp New Orleans Restaurant Analysis

## Research question

> Where can someone find the top 15 restaurants for New Orleans cooking—Cajun/Creole, Seafood, Southern, or Soul Food—in New Orleans, and which geographic area is best for finding them?

## Executive summary

_To be completed after the analysis._

## View the complete report

_Link to the rendered report will be added after rendering._

## Data sources

- Yelp Open Dataset business JSON
- Yelp Open Dataset review JSON
- U.S. Census/TIGER boundary data or New Orleans boundary data

Raw Yelp JSON files belong in `data/raw/` locally and must not be committed.

## Project scope and decisions

- Restaurant definition: Yelp businesses with city `New Orleans`, state `LA`, and the exact `Restaurants` category token.
- Selected theme: **New Orleans cooking** — Cajun/Creole, Seafood, Southern, and Soul Food.
- Inclusion rule: match at least one selected category; each business counts once.
- Ranking target: **top 15 restaurants**; ranking criteria will be established during ratings analysis.
- Open status: retain open and closed businesses in this historical dataset for now.
- Geographic systems to compare: **ZIP Code Tabulation Areas (ZCTAs) and New Orleans wards**. Use official boundaries and restaurant coordinates for both systems; Yelp postal codes alone do not establish ZCTA membership.
- Final geographic system: undecided; seven-area coverage remains to be checked.

## Main findings

_To be completed after the analysis._

## Limitations

_To be completed after the analysis._

## Source code

- [Quarto report](yelp_new_orleans_project.qmd)
- [Import workflow](R/import.R)
- [Cleaning workflow](R/clean.R)
- [Analysis workflow](R/analysis.R)

## Reproducibility

Place the Yelp business and review JSON files in `data/raw/`. Install the R package `jsonlite`, then run `Rscript R/import.R` from the repository root. The script scans both complete input files in pages, keeps all New Orleans restaurant businesses and their reviews, and saves a separate New Orleans cooking subset. Review text and voting fields are omitted because the planned ratings analysis does not need them. Filtered reviews are accumulated in memory, then written as compressed RDS files.

See [category selection](CATEGORY_SELECTION.md), [filtered restaurants](data/new_orleans/business_new_orleans_cooking.csv), and [filter summary](data/new_orleans/cooking_filter_summary.json). Raw JSON and generated RDS files are ignored by Git. These historical data do not establish current opening status.
