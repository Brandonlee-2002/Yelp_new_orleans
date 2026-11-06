# Analytical decision log

| Decision | Choice | Reason | Sensitivity check |
|---|---|---|---|
| Theme | Cajun/Creole, Seafood, Southern, Soul Food | Related labels provide a reproducible New Orleans cooking scope | Category counts, overlaps, and limitations |
| City scope | Exact Yelp city label, then official Census boundary check | Reproducible initial filter with an explicit geographic audit | 16 outside-city records preserved |
| Reviewer baseline | Mean reviewer score | Retains rating-scale information and centers deviations | Median baseline |
| Reviewer activity | At least 5 reviews in the city/category pool | Reduces unstable one-review baselines | 3 and 10 reviews |
| Restaurant evidence | At least 50 available reviews and 20 eligible reviewers | Balances coverage and support | 25/100 reviews and 10/30 reviewers |
| Main geography | Wards | More balanced restaurant counts than ZCTAs | ZCTA comparison |
| Area evidence | At least 10 eligible restaurants | Avoids recommendations based on very small pools | 5 and 15 |
| Area weighting | Equal weight per eligible restaurant | Prevents heavily reviewed restaurants from dominating an area | Review totals reported separately |
| Missing ward points | Leave unmatched, do not snap | Preserves geometric uncertainty | ZCTA result remains available |

These are analysis rules, not claims that the data-generating process is unbiased or that small score differences are statistically meaningful.
