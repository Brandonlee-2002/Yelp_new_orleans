# Where to Find New Orleans Cooking

**[Read the report online](https://brandonlee-2002.github.io/Yelp_new_orleans/yelp_new_orleans_project.html)** · [AI assistance log](https://brandonlee-2002.github.io/Yelp_new_orleans/ai-log.html)

**Project status:** Steps 3–6 are complete: categories, review join, city-boundary check, and ZCTA/ward comparison. Reviewer adjustment and the final top 15 remain in progress. [Deliverables audit](PROJECT_STATUS.md).

## Research question

> Where can someone find the top 15 restaurants for New Orleans cooking—Cajun/Creole, Seafood, Southern, or Soul Food—in New Orleans, and which geographic area is best for finding them?

## Executive summary

The initial filter contains 672 New Orleans cooking restaurants and 250,304 reviews. The Census boundary check retains 656 restaurants and 249,002 reviews for the geographic comparison; wards provide more balanced restaurant counts than ZCTAs and are selected for the main analysis. Reviewer adjustment, the top 15, and a final best-area conclusion remain outstanding.

## View the report

This portfolio uses **Option 2: a README landing page plus a rendered HTML report**. The report contains the methods, tables, graphs, limitations, and analysis progress. The README provides the question, key findings, and links to the supporting work.

View the report directly on [GitHub Pages](https://brandonlee-2002.github.io/Yelp_new_orleans/yelp_new_orleans_project.html) without running R or Quarto. For an offline copy, download or clone this repository and open `docs/yelp_new_orleans_project.html` in a browser. Open `docs/ai-log.html` to read the AI log. Both HTML pages embed their display resources. Keep the repository folders together so links to source code and CSV tables work. GitHub may show HTML source when following the file link; use the downloaded file for the rendered browser view.

## Data sources

The analysis uses the business and review JSON files from the [Yelp Open Dataset](https://business.yelp.com/data/resources/open-dataset/). Download and extract these files to `data/raw/` when reproducing the import. Geographic analysis uses 2020 Census place and ZCTA boundaries plus the City of New Orleans ward service snapshot downloaded October 29, 2026. See [boundary sources and provenance](data/boundaries/README.md).

Raw Yelp JSON files belong in `data/raw/` locally and must not be committed.

## Project scope and decisions

- Restaurant definition: Yelp businesses with city `New Orleans`, state `LA`, and the exact `Restaurants` category token.
- Selected theme: **New Orleans cooking** — Cajun/Creole, Seafood, Southern, and Soul Food.
- Inclusion rule: match at least one selected category; each business counts once.
- Ranking target: **top 15 restaurants**; ranking criteria will be established during ratings analysis.
- Open status: retain open and closed businesses in this historical dataset for now.
- Geographic systems to compare: **ZIP Code Tabulation Areas (ZCTAs) and New Orleans wards**. Use official boundaries and restaurant coordinates for both systems; Yelp postal codes alone do not establish ZCTA membership.
- Final geographic system: **wards**, supported by more balanced sample sizes; ZCTAs remain the comparison. Both systems contain restaurants in 17 areas.
- Geographic scope: 656 restaurants inside Census New Orleans; 16 initial city-label mismatches are retained in an audit. Two city-contained lakefront points remain unmatched to wards.

## Main findings

- The city-only group occupies 17 ZCTAs and 17 wards. Wards have a median of 25 restaurants per populated area versus 16 for ZCTAs.
- Ward 4 offers the largest selection (116 restaurants); Ward 13 has the highest raw mean rating among wards with at least 10 restaurants (4.15 stars, 20 restaurants). These are preliminary historical summaries, not final recommendations.

- No NA values were found in the retained columns, but seven restaurants have blank street addresses; all have coordinates.
- The median Yelp business rating is 4 stars, and the median number of available reviews per restaurant is 106.5.
- Of 672 restaurants, 435 are marked open and 237 closed in the historical snapshot. Eligibility for the top 15 has not been decided.

![Selected category counts](figures/cooking_category_counts.png)

[Restaurant summary table](data/analysis/restaurant_summary.csv) · [Data-quality audit](data/analysis/missing_values.csv) · [Review-count threshold comparison](data/analysis/review_thresholds.csv)

## Limitations

Review records end in January 2022; historical open-status flags do not establish current operating status. Categories overlap. Reviewer-adjusted scores and final rankings remain pending. Ward boundaries have an unspecified historical effective date; two lakefront points fall outside the saved ward polygons.

## Source code

- [Quarto report](yelp_new_orleans_project.qmd)
- [Import workflow](R/import.R)
- [Cleaning workflow](R/clean.R)
- [Analysis workflow](R/analysis.R)
- [Geographic analysis](R/geography.R)
- [Boundary download workflow](R/download_boundaries.R)

## Repository guide

| Location | Contents |
|---|---|
| `README.md` | Portfolio landing page |
| `docs/yelp_new_orleans_project.html` | Viewable analysis report |
| `docs/ai-log.html` | Viewable AI assistance log |
| `yelp_new_orleans_project.qmd`, `initial_results.qmd`, `geographic_results.qmd` | Report source and generated results section |
| `ai-log.qmd` | AI log source |
| `R/` | Import, cleaning, and analysis code |
| `data/raw/` | Local raw files, excluded from Git because of their size |
| `data/new_orleans/` | Filtered data and category evidence; RDS files are local |
| `data/boundaries/` | Official boundary snapshots, metadata, and source checksums |
| `data/analysis/` | Exported descriptive and validation tables |
| `figures/` | Saved report plots |

## Reproduce or update the report

Place the Yelp business and review JSON files in `data/raw/`. Install the R package `jsonlite`, then run `Rscript R/import.R` from the repository root. The script scans both complete input files in pages, keeps all New Orleans restaurant businesses and their reviews, and saves a separate New Orleans cooking subset. Review text and voting fields are omitted because the planned ratings analysis does not need them. Filtered reviews are accumulated in memory, then written as compressed RDS files.

See [category selection](CATEGORY_SELECTION.md), [filtered restaurants](data/new_orleans/business_new_orleans_cooking.csv), and [filter summary](data/new_orleans/cooking_filter_summary.json). Raw JSON and generated RDS files are ignored by Git. These historical data do not establish current opening status.

For the initial and geographic analysis, install `ggplot2`, `sf`, and `tigris` (plus `jsonlite` for import), then run these commands from the repository root (Quarto is needed only to rebuild the HTML):

```sh
Rscript R/analysis.R
Rscript R/download_boundaries.R
Rscript R/geography.R
quarto render yelp_new_orleans_project.qmd --output-dir docs --no-clean
quarto render ai-log.qmd --output-dir docs --no-clean
```

The scripts read the saved theme RDS files and saved official boundaries, generate CSV summaries in `data/analysis/`, plots and maps in `figures/`, and the generated report sections `initial_results.qmd` and `geographic_results.qmd`. Boundary downloads are skipped when snapshots already exist. The city-only RDS files are saved separately; initial inputs remain unchanged. The `--no-clean` option preserves the other HTML page. Include the rendered `docs/` pages, CSV summaries, figures, and source code in the portfolio repository so readers can inspect results without executing the analysis. Raw JSON and generated RDS files stay excluded from Git.

## GitHub Pages publishing

GitHub Pages serves the committed `docs/` folder from the `main` branch. Render the report and AI log locally with the commands above, commit the updated HTML and figures, then push to `main` to update the site. No raw data or R execution is required on GitHub. `docs/index.html` opens the report at the site root; `docs/.nojekyll` serves the rendered files directly.
