# Shared analysis specification. Keep primary rules here so code and prose do
# not silently drift apart.
selected_categories <- c("Cajun/Creole", "Seafood", "Southern", "Soul Food")
ranking_size <- 15L
primary_reviewer_threshold <- 5L
primary_restaurant_reviews <- 50L
primary_restaurant_reviewers <- 20L
primary_area_restaurants <- 10L
alternate_area_minima <- c(5L, 15L)
bootstrap_replicates <- 1000L
split_half_replicates <- 200L
ward_permutation_replicates <- 10000L
analysis_seed <- 42L
boundary_snapshot_date <- "October 29, 2026"
review_end_date <- "January 2022"
