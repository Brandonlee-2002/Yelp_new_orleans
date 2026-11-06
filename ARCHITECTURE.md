# Project architecture

```text
Yelp business/review JSON
          |
          v
Paged import + exact category cleaning (R/import.R, R/clean.R)
          |
          v
Filtered business/review RDS + normalized category table
          |
          +--> descriptive QA and summaries (R/analysis.R)
          +--> official place/ZCTA/ward joins (R/geography.R)
          +--> reviewer normalization, rankings, sensitivity (R/rankings.R)
          +--> bootstrap score uncertainty (R/uncertainty.R)
          |
          v
CSV validation/results + PNG figures + JSON metrics
          |
          v
Generated Quarto HTML report and visual story -> docs/
```

`make report` is the intended full pipeline. `make test` checks the committed result artifacts and core invariants without requiring the raw Yelp files.
