# Data dictionary

## Core entities

| Field | Entity | Meaning | Source/transformation |
|---|---|---|---|
| `business_id` | Business/review | Stable Yelp business identifier | Yelp Open Dataset |
| `review_id` | Review | Stable Yelp review identifier | Yelp Open Dataset |
| `user_id` | Review | Reviewer identifier | Yelp Open Dataset |
| `stars` | Business/review | Business or review rating on a 1–5 scale | Source field |
| `review_count` | Business | Yelp business-level count | Source field; not used as available-review count |
| `available_reviews` | Business | Reviews present in the downloaded review stream | Counted from filtered reviews |
| `is_open` | Business | Historical Yelp open flag | Source field; not current operating status |
| `categories` | Business | Comma-separated Yelp labels | Source field |
| `matched_categories` | Business | Selected theme labels carried by the business | Exact-token match after trimming |
| `adjusted_mean` | Business | Mean review star minus reviewer mean baseline | Derived from eligible reviewers |
| `eligible_reviewers` | Business | Distinct reviewers meeting the five-review threshold | Derived |
| `ward` | Business | Official ward containing the point | Spatial join to saved ward snapshot |
| `zcta` | Business | Census ZIP Code Tabulation Area containing the point | Spatial join to 2020 Census geometry |

## Interpretation

The adjusted score is a relative deviation, not a replacement Yelp rating. Restaurant rankings are historical and descriptive. The bootstrap outputs hold the eligibility pool, reviewer baselines, and geography fixed while resampling eligible reviews within each restaurant.
