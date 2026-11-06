"""A presentation layer over the completed analysis; no scores are recalculated."""
from pathlib import Path
import csv,json,html
root=Path(__file__).resolve().parents[1]
read=lambda f:list(csv.DictReader((root/'data/analysis'/f).open()))
esc=lambda x:html.escape(str(x))
top=read('top_15_restaurants.csv')
m=json.loads((root/'data/analysis/final_metrics.json').read_text())
assert len(top)==15 and m['city_restaurants']==656 and m['eligible_restaurants']==288
best_ward=m['highest_mean_ward']; best_score=m['highest_mean_ward_score']
cards=[]
for row in top[:3]:
 cards.append(f'''<a class="standout-card" href="results.html#the-top-15"><span class="story-rank">{int(row['rank']):02d}</span><h3>{esc(row['business_name'])}</h3><p>{esc(row['ward'])} · {esc(row['address'])}</p><strong>+{float(row['adjusted_mean']):.3f}</strong><span class="standout-unit"> adjusted star points</span><p class="standout-evidence">{int(row['eligible_reviewers']):,} eligible reviewers · {int(row['available_reviews']):,} total reviews</p></a>''')
steps=[(656,'Inside the city','All restaurants matching at least one theme label.'),(423,'Marked open','Historical snapshot flag; current operation is unverified.'),(288,'Enough review evidence','At least 50 reviews and 20 distinct eligible reviewers.'),(15,'The final shortlist','Highest mean reviewer-adjusted scores in the eligible pool.')]
funnel=''.join(f'''<div class="funnel-row"><div class="funnel-copy"><strong>{count:,}</strong><span>{label}</span><p>{desc}</p></div><div class="funnel-track" aria-hidden="true"><div class="funnel-bar" style="width:{count/656*100:.3f}%"></div></div></div>''' for count,label,desc in steps)
labels={'Primary':'Primary rules','Reviewers: 3+':'Reviewer activity ≥3','Reviewers: 10+':'Reviewer activity ≥10','All reviews: 25+':'Total restaurant reviews ≥25','All reviews: 100+':'Total restaurant reviews ≥100','Eligible reviewers: 10+':'Distinct eligible reviewers ≥10','Eligible reviewers: 30+':'Distinct eligible reviewers ≥30','Median baseline':'Median reviewer baseline','Area minimum: 5+':'At least 5 eligible places per ward','Area minimum: 15+':'At least 15 eligible places per ward'}
tiles=[]
for row in read('area_recommendation_sensitivity.csv'):
 ward=row['best_ward']; primary=row['scenario']=='Primary'
 tiles.append(f'''<div class="scenario-tile ward-{ward.split()[-1]}{' primary-scenario' if primary else ''}"><span>{esc(labels.get(row['scenario'],row['scenario']))}</span><strong>{esc(ward)}</strong><small>{'Primary result' if primary else 'Leading ward under this rule'}</small></div>''')
content=f'''<p class="eyebrow">A visual research story · Historical Yelp data through January 2022</p>

<div class="story-lede"><p>The strongest individual restaurants are spread across <strong>11 wards</strong>. Choosing one “best area” depends on how we define enough evidence.</p><a class="story-button" href="#from-656-restaurants-to-15-standouts">Follow the evidence ↓</a><a class="story-text-link" href="results.html">Read the full results →</a></div>

<p class="story-question"><strong>The question:</strong> Where can someone find the top 15 New Orleans cooking restaurants, and which geographic area is best for finding them?</p>

<div class="story-controls"><nav class="story-chapters" aria-label="Visual story chapters"><a href="#from-656-restaurants-to-15-standouts"><span>01</span> Pool</a><a href="#a-four-star-review-needs-context"><span>02</span> Ratings</a><a href="#the-top-15"><span>03</span> Standouts</a><a href="#put-the-shortlist-on-the-map"><span>04</span> Map</a><a href="#the-area-winner-changes-with-the-rules"><span>05</span> Areas</a></nav><button id="story-motion-toggle" class="story-motion-toggle" type="button" aria-label="Decorative story animations" aria-pressed="false" title="Turn scroll reveals and bar animations on or off" hidden>Motion: off</button></div>

## From 656 restaurants to 15 standouts

<p class="chapter-label">01 / Build a comparable pool</p>

We start with **249,002 reviews** for city-contained restaurants carrying Cajun/Creole, Seafood, Southern, or Soul Food labels. Each step makes the final shortlist more specific.

<div class="story-funnel" role="group" aria-label="Restaurant selection funnel">{funnel}</div>

<details class="story-details"><summary>Why these filters?</summary><p>The official city-boundary check removed 16 outside-city locations from the initial 672-restaurant theme pool, preserving them in an audit. The final evidence rules balance coverage with reviewer support. The theme is label-based and includes international restaurants carrying a Seafood or other selected label. <a href="methods.html">Inspect the category and geographic checks →</a></p></details>

## A four-star review needs context

<p class="chapter-label">02 / Account for scoring habits</p>

Some reviewers award high ratings frequently. Others score more strictly. We compare each review with that reviewer's usual score in this city/category pool.

<div class="baseline-examples" role="group" aria-label="Illustrative example of reviewer adjustment"><div class="baseline-card"><span>Reviewer A usually gives 3 stars</span><div class="baseline-equation">4 − 3 <b>= +1.0</b></div><p>A four-star review is above their usual score.</p></div><div class="baseline-card"><span>Reviewer B usually gives 4.5 stars</span><div class="baseline-equation">4 − 4.5 <b>= −0.5</b></div><p>The same four-star review is below their usual score.</p></div></div>

<p class="visual-note">Illustrative examples. Adjusted scores measure deviations in star points, not new Yelp ratings. Reviewer eligibility requires five reviews in the selected city/category pool; only 23.9% of all reviews enter the adjusted analysis.</p>

<div class="story-takeaway"><strong>Three comparisons</strong><p>separate reviewer selection from leave-one-review-out adjustment. The sensitivity table in the full report shows how each stage changes the shortlist.</p></div>

## The top 15

<p class="chapter-label">03 / Meet the standouts</p>

**Tito's Ceviche & Pisco, Ajun Cajun, and Restaurant August** lead under the primary rules. Their review evidence differs substantially, so a rank is best read alongside its sample size.

<div class="standout-grid">{''.join(cards)}</div>

![The 15 selected restaurants ranked by reviewer-adjusted deviation](figures/story_top_15.png)

<a class="story-button" href="results.html#the-top-15">See all 15 addresses and review counts →</a>

<p class="visual-note">Seafood is one of the inclusion labels, so the shortlist includes Peruvian and Thai restaurants. This is a Yelp category grouping, not a test of culinary authenticity. The full report compares reviewer thresholds, review-volume cutoffs, and mean versus median baselines.</p>

## Put the shortlist on the map

<p class="chapter-label">04 / Connect quality with place</p>

The top 15 cross **11 wards**. A single area cannot capture every standout. Map numbers match the ranking above and the full results table.

![The top 15 restaurants on official ward boundaries, numbered by rank](figures/final_top_15_map.png)

<div class="geography-story"><div><strong>17</strong><span>populated wards</span></div><div><strong>17</strong><span>populated ZCTAs</span></div><p>Both systems meet the geographic-coverage requirement. Wards have more balanced restaurant counts and are the main comparison; ZCTAs remain a sensitivity view.</p></div>

<details class="story-details"><summary>What do the boundaries leave out?</summary><p>Two lakefront points fall roughly 13–16 metres outside the nearest ward polygon. They are retained in the city dataset and left unsnapped. Neither enters the top 15. The ward geometry is a 2026 service snapshot with no verified historical effective date. <a href="methods.html#steps-36-categories-joins-and-geography">Explore the full maps and location audit →</a></p></details>

## The area winner changes with the rules

<p class="chapter-label">05 / Keep the uncertainty visible</p>

**{best_ward} has the highest mean among rankable wards:** its primary adjusted score is **{best_score:+.3f}**. The permutation test does not statistically distinguish the highest ward, so this is a descriptive comparison rather than a universal recommendation.

The tiles below show the leading ward each time we change one analysis choice.

<div class="scenario-grid" role="group" aria-label="Leading wards across ten sensitivity specifications">{''.join(tiles)}</div>

<p class="visual-note">Each tile is one specification, not a probability estimate or independent vote. The full report adds bootstrap intervals and a max-selection permutation test; the primary highest mean is not statistically distinguished.</p>

<div class="story-conclusion"><div><span class="eyebrow">Primary area result</span><h3>Highest mean: {best_ward}</h3><p>It leads among wards meeting the primary evidence rule, but the result is not statistically distinguished.</p></div><div><span class="eyebrow">Largest overall selection</span><h3>Explore Ward 4</h3><p>Selection size and adjusted quality answer different parts of the research question.</p></div></div>

## Explore the evidence

This visual story summarizes a completed historical analysis. Reviews end in **January 2022**, and snapshot-open flags do not verify current operation. Price, travel time, accessibility, and changes over time were not modeled.

<div class="story-resource-grid"><a href="results.html"><strong>Full results</strong><span>Ranked table, score definitions, and sensitivity comparisons →</span></a><a href="methods.html"><strong>Methods & maps</strong><span>Categories, joins, data quality, and official boundaries →</span></a><a href="ai-log.html"><strong>AI assistance log</strong><span>Prompts, revisions, decisions, and verification →</span></a></div>

<div class="portfolio-footer">Brandon Lee · New Orleans restaurant research · Data through January 2022 · Analysis completed October 29, 2026</div>
'''
(root/'story_results.qmd').write_text(content)
