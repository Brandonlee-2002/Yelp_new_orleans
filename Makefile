.PHONY: all rebuild import analyze geography rank uncertainty recall report test clean

all: report

import:
	Rscript R/import.R

analyze:
	Rscript R/analysis.R

geography:
	Rscript R/download_boundaries.R
	Rscript R/geography.R

rank:
	Rscript R/rankings.R

uncertainty:
	Rscript R/rankings.R

recall:
	Rscript R/recall_audit.R

rebuild: import analyze geography rank uncertainty

report: uncertainty
	bash scripts/render.sh

test:
	Rscript tests/test_pipeline.R

clean:
	find figures -type f -name '*.png' -delete
