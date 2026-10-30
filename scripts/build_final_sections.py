"""Build the final report prose and tables from the exported R results."""
from pathlib import Path
import csv, json, html
ROOT=Path(__file__).resolve().parents[1]
def read(name):
 return list(csv.DictReader((ROOT/'data/analysis'/name).open()))
def table(headers,rows,cls=''):
 def cell(x): return html.escape(str(x))
 head=''.join('<th scope="col">'+cell(h)+'</th>' for h in headers)
 body=''.join('<tr>'+''.join('<td>'+str(v)+'</td>' for v in row)+'</tr>' for row in rows)
 return f'<div class="report-table" tabindex="0" role="region" aria-label="Scrollable data table"><table class="{cls}"><thead><tr>{head}</tr></thead><tbody>{body}</tbody></table></div>'
def num(x):return f'{int(float(x)):,}'
def score(x):return f'{float(x):+.3f}'
m=json.loads((ROOT/'data/analysis/final_metrics.json').read_text())
# Guard the hand-written interpretation against silently publishing stale prose
# if a different input extract or analysis specification is used in the future.
expected={'city_restaurants':656,'city_reviews':249002,'eligible_restaurants':288,
          'eligible_reviewers':7066,'eligible_reviews':59584,'best_ward':'Ward 9',
          'best_restaurant':"Tito's Ceviche & Pisco",'raw_adjusted_top15_overlap':12}
for key,value in expected.items():
 assert m[key]==value, f'Results changed ({key}); revise the narrative before publishing.'
top=read('top_15_restaurants.csv')
rows=[]
for r in top:
 place=f'<span class="restaurant-name">{html.escape(r["business_name"])}</span><span class="restaurant-meta">{html.escape(r["address"])}<br>{html.escape(r["matched_categories"])}</span>'
 rows.append([f'<span class="rank">{r["rank"]}</span>',place,html.escape(r['ward'] or 'Unassigned'),f'{float(r["mean_review_stars"]):.2f}',f'<span class="score">{score(r["adjusted_mean"])}</span>',num(r['available_reviews']),num(r['eligible_reviewers'])])
rank_table=table(['Rank','Restaurant · address · theme labels','Ward','Raw stars','Adjusted','Reviews','Reviewers'],rows,'rank-table')
reviewer_table=table(['Minimum reviews per reviewer','Reviewers retained','Reviews retained','Review share'],[[num(r['minimum_reviews']),num(r['reviewers']),num(r['reviews']),f'{float(r["percent"]):.1f}%'] for r in read('final_reviewer_thresholds.csv')])
sens=read('ranking_sensitivity.csv')
sensitivity_table=table(['Analysis rule','Eligible places','Top-15 overlap','Rank correlation†'],[[html.escape(r['scenario']),num(r['eligible_restaurants']),f'{r["top_15_overlap"]}/15',f'{float(r["common_pool_spearman"]):.3f}'] for r in sens])
areas=read('recommended_ward_comparison.csv')
area_table=table(['Ward','Eligible restaurants','Mean adjusted*','Raw stars','Total reviews'],[[r['area'],num(r['eligible_restaurants']),score(r['mean_adjusted']),f'{float(r["mean_raw"]):.2f}',num(r['total_reviews'])] for r in areas])
area_sens=read('area_recommendation_sensitivity.csv')
area_sens_table=table(['Analysis rule','Leading ward','Wards meeting area minimum'],[[html.escape(r['scenario']),r['best_ward'],num(r['rankable_wards'])] for r in area_sens])
changes=read('largest_ranking_changes.csv')[:5]
changes_table=table(['Restaurant','Raw rank','Adjusted rank','All-review stars','Selected-reviewer stars'],[[html.escape(r['business_name']),r['raw_rank'],r['rank'],f'{float(r["mean_review_stars"]):.2f}',f'{float(r["eligible_raw_mean"]):.2f}'] for r in changes])
geo=read('geography_comparison.csv')
geo_table=table(['System','Populated areas','Assigned','Unmatched','Median area count','Largest area'],[[r['system'],r['populated_areas'],r['assigned'],r['unmatched'],r['median_populated_count'],r['largest_count']] for r in geo])
base='https://github.com/Brandonlee-2002/Yelp_new_orleans/blob/main/'
content=f'''<p class="eyebrow">Historical Yelp data · Reviews through January 2022</p>

<div class="stat-grid"><div class="stat-card"><span class="stat-number">656</span><span class="stat-label">Restaurants inside New Orleans</span></div><div class="stat-card"><span class="stat-number">249,002</span><span class="stat-label">Reviews in the city/category pool</span></div><div class="stat-card"><span class="stat-number">288</span><span class="stat-label">Restaurants meeting ranking criteria</span></div></div>

## The answer

**Tito's Ceviche & Pisco leads the restaurant ranking**, followed by Ajun Cajun and Restaurant August, after accounting for reviewers' scoring habits. The top 15 span **{len(set(r['ward'] for r in top))} wards**, so the strongest individual restaurants are spread across the city.

<div class="finding"><p><strong>For an area-level starting point, Ward 9 leads under the primary rules.</strong> Its 12 eligible restaurants average <strong>+0.083 star points</strong> above their reviewers' usual scores. Ward 4 offers the largest selection overall, with 116 theme restaurants. The leading area changes under several alternative rules, so the evidence does not establish one universally best ward.</p></div>

These findings describe a **historical dataset**, not a verified list of restaurants operating today. The theme includes Cajun/Creole, Seafood, Southern, or Soul Food labels; a Seafood match can include Peruvian or Thai restaurants. It is a reproducible Yelp category grouping, not an authenticity test for New Orleans cuisine.

## The top 15

Restaurants must be inside the Census city boundary, marked open in the snapshot, have **at least 50 available reviews**, and have reviews from **at least 20 distinct eligible reviewers**. An eligible reviewer has written at least five reviews within the city/category pool. These rules retain **288 of 423 snapshot-open restaurants**.

{rank_table}

**Adjusted** = mean of each eligible review's stars minus that reviewer's mean stars in this category/city pool. It is a deviation in star points, **not a new Yelp rating**. Raw stars are the mean from all available reviews, displayed to two decimals. **Reviewers** counts distinct eligible reviewers, not all reviewers. Rankings use full precision; ties break by raw mean, review count, then business ID.

The 20-reviewer minimum provides more evidence than the 10-reviewer alternative while retaining 288 of that alternative's 304 restaurants. It does not guarantee statistical certainty. For example, Ajun Cajun has only 21 eligible reviewers and 51 total reviews, while Restaurant August has 383 eligible reviewers and 1,350 total reviews. Read those differences alongside their positions.

[Download the complete top-15 table]({base}data/analysis/top_15_restaurants.csv) · [All 288 eligible restaurant rankings]({base}data/analysis/eligible_restaurant_rankings.csv)

### Where the top 15 are located

![Top 15 restaurant locations on official ward boundaries; numbers match the ranking table](figures/final_top_15_map.png)

All 15 ranked restaurants have ward assignments. The map highlights Ward 9, the primary area-level recommendation. The region with the highest average eligible restaurant score need not contain the largest number of top-15 restaurants.

![Citywide locator for the 15 ranked restaurants](figures/final_city_locator.png)

## What makes a restaurant “best”?

### Reviewers have different scoring habits

A four-star review from someone who usually awards three stars is **+1** above their baseline. The same four-star review from someone averaging 4.5 stars is **−0.5**. We calculate both mean and median reviewer baselines using all of each reviewer's reviews within the 656-restaurant pool, including the target review. That inclusion tends to pull deviations toward zero, particularly for less-active reviewers.

The primary analysis uses the **mean baseline** because it centers each reviewer's deviations at zero and retains rating differences throughout the scale. Median baselines are tested as an alternative. Reviewers are selected by activity rather than a claim that they are experts or local residents.

{reviewer_table}

The five-review threshold retains **7,066 reviewers and 59,584 reviews**—**23.9%** of the full review pool. All reviewers contribute to the raw comparison; only the selected reviewers contribute to the adjusted score. This intentionally changes the reviewer mix and can exclude visitors or infrequent reviewers.

At restaurant level, each eligible review contributes equally. For area comparisons, **each eligible restaurant contributes equally**, so heavily reviewed venues do not dominate an area's score merely because they have more reviews.

### How much do the rankings change?

**12 of the adjusted top 15 also appear in the raw top 15**, using the same 288 eligible restaurants. The rank correlation across that common pool is **0.876**. Adjustment therefore preserves much of the signal while changing important positions.

![Raw all-review means versus reviewer-adjusted deviations, with top-15 rank labels](figures/final_raw_vs_adjusted.png)

Some large rank changes reflect **both reviewer selection and baseline subtraction**. The selected-reviewer raw mean below helps distinguish those mechanisms; changes cannot be attributed to normalization alone.

{changes_table}

### Sensitivity to the rules

{ sensitivity_table }

† Spearman correlation on restaurants shared by the alternative and primary eligible pools. Changing evidence thresholds can change eligibility without changing the order among restaurants that remain. The seven methodological alternatives retain **10–14 of the primary top 15**. The median-baseline alternative has the lowest overlap, showing that the exact shortlist depends on the definition of adjustment.

[Full sensitivity results]({base}data/analysis/ranking_sensitivity.csv) · [Raw, selected-reviewer, and adjusted results for all city restaurants]({base}data/analysis/reviewer_adjusted_restaurants.csv)

## Which geographic area is best?

### Why use wards?

The same 656 city-contained locations are compared with official ZCTAs and wards. Both systems occupy 17 areas, meeting the assignment's seven-area requirement.

{geo_table}

**Wards are the main geography** because their restaurant counts are more balanced: only one ward has fewer than ten theme restaurants, compared with five populated ZCTAs. ZCTA 70130 contains 213 restaurants, versus 116 in the largest ward. ZCTAs remain a useful postal-style comparison; they are not neighborhoods. See the [complete geographic comparison and maps](methods.html#steps-36-categories-joins-and-geography).

Two lakefront locations fall about 13–16 metres outside the nearest ward polygon despite being inside the Census city. They are documented and left unsnapped. One meets restaurant-ranking eligibility, but neither enters the top 15. The unassigned eligible restaurant contributes to the city ranking and ZCTA results, but not ward means.

### An area recommendation with an evidence minimum

To compare areas, require **at least ten restaurants that pass the final restaurant eligibility rules**, then rank wards by the equal-weight mean of their restaurant-level adjusted scores. This leaves **ten comparable wards**.

{area_table}

**Ward 9 leads (+0.083; 12 eligible restaurants)**, followed by Ward 2 (+0.062; 15). Ward 13's nine eligible restaurants average a higher +0.128, but it fails the stated area minimum and is shown as insufficient for the main area ranking. The eligibility rule therefore materially affects the answer; the difference between nine and ten restaurants is a practical cutoff, not a statistical boundary.

![Adjusted ward-level restaurant means, with eligible restaurant counts](figures/final_ward_scores.png)

### Is Ward 9 a robust winner?

{area_sens_table}

**No single ward leads across all reasonable specifications.** Ward 9 leads in three of the ten analyses including the primary, while Wards 2, 7, 12, and 13 lead others. With the median baseline, the leading score is negative; that still represents the highest score among the eligible wards under that alternative. These are descriptive comparisons without significance tests or a causal interpretation. Recommend Ward 9 conditionally under the stated rules, and use the individual top-15 locations for a more specific shortlist.

[Ward and ZCTA adjusted summaries]({base}data/analysis/adjusted_area_summary.csv) · [Area recommendation sensitivity]({base}data/analysis/area_recommendation_sensitivity.csv)

## Data, scope, and limitations

- **Scope:** initial exact city-label filtering found 672 theme restaurants. Sixteen map to other Census places; the main city-contained analysis uses 656 restaurants and 249,002 reviews. Their original records remain in an audit. Businesses labeled with another Yelp city were not recovered by this initial filter.
- **Historical data:** selected reviews run from March 2005 to January 2022. Snapshot-open flags do not establish current operation, and pooling years can hide changes in quality or ownership.
- **Completeness:** retained columns have no NA values; seven initial restaurant records have blank street addresses. Coordinates remain available. Missingness checks do not establish accuracy.
- **Reviewer and category selection:** only 23.9% of reviews contribute to adjusted scores. Category labels overlap and are not evidence of a uniquely local menu. Scores remain subject to selection bias and unequal reviewer coverage.
- **Boundaries and precision:** place/ZCTA polygons are from Census 2020; wards are a City service snapshot downloaded in 2026 with an unspecified historical effective date. Small shoreline gaps and two unmatched ward points are retained transparently.
- **Reliability:** evidence thresholds and sensitivity comparisons improve transparency but do not establish a population-best restaurant or statistically significant ward differences. Prices, travel time, accessibility, recency, and service preferences were not modeled.

## Reproduce and inspect

The [methods appendix](methods.html) documents category counts and co-occurrences, large-file handling, review joins, cleaning decisions, geography selection, and full coverage maps. The [AI assistance log](ai-log.html) records prompts, corrections, and AI-supported decisions.

R code, exported tables, saved boundary snapshots, and a dependency lockfile are in the [GitHub repository](https://github.com/Brandonlee-2002/Yelp_new_orleans). Follow the README's commands to rebuild the results and HTML. The lockfile restore is checked separately from the raw-data download, and raw JSON/review-level RDS files are excluded from Git. [Review the completion audit]({base}PROJECT_STATUS.md).

<div class="portfolio-footer">Brandon Lee · Yelp New Orleans Restaurant Analysis · Historical dataset, 2005–2022 · Updated October 29, 2026</div>
'''
(ROOT/'final_results.qmd').write_text(content)
