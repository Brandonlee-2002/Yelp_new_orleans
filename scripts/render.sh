#!/usr/bin/env bash
set -eu
python3 scripts/build_final_sections.py
Rscript R/visual_story.R
python3 scripts/build_story.py
quarto render yelp_new_orleans_project.qmd --output-dir docs --no-clean
quarto render results.qmd --output-dir docs --no-clean
quarto render methods.qmd --output-dir docs --no-clean
quarto render ai-log.qmd --output-dir docs --no-clean
