# Run from the repository root: Rscript R/import.R
# Pages limit parsing memory; filtered review columns are accumulated in memory.
source("R/clean.R")
stopifnot(requireNamespace("jsonlite", quietly = TRUE))
output_dir <- "data/new_orleans"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

business_pages <- list()
business_connection <- file("data/raw/yelp_academic_dataset_business.json", "r")
jsonlite::stream_in(business_connection, pagesize = 10000L, verbose = FALSE,
  handler = function(page) {
    cols <- c("business_id", "name", "address", "city", "state", "postal_code",
              "latitude", "longitude", "stars", "review_count", "categories", "is_open")
    filtered <- clean_new_orleans_restaurants(page[, cols, drop = FALSE])
    if (nrow(filtered)) business_pages[[length(business_pages) + 1L]] <<- filtered
  })
close(business_connection)
restaurants <- do.call(rbind, business_pages)
restaurants <- restaurants[!duplicated(restaurants$business_id), , drop = FALSE]
selected <- select_cooking_restaurants(restaurants)
saveRDS(restaurants, file.path(output_dir, "business_new_orleans.rds"))
saveRDS(selected, file.path(output_dir, "business_new_orleans_cooking.rds"))
write.csv(selected, file.path(output_dir, "business_new_orleans_cooking.csv"), row.names = FALSE)
message("Retained ", nrow(selected), " cooking-theme restaurants from ", nrow(restaurants), " restaurants.")

tokens <- category_tokens(selected$categories)
category_counts <- data.frame(category = selected_categories,
  restaurants = vapply(selected_categories, function(cat) {
    sum(vapply(tokens, function(x) cat %in% x, logical(1)))
  }, integer(1)))
write.csv(category_counts, file.path(output_dir, "cooking_category_counts.csv"), row.names = FALSE)
pairs <- combn(selected_categories, 2L)
pair_counts <- data.frame(category_1 = pairs[1, ], category_2 = pairs[2, ],
  restaurants = apply(pairs, 2L, function(pair) {
    sum(vapply(tokens, function(x) all(pair %in% x), logical(1)))
  }))
write.csv(pair_counts, file.path(output_dir, "cooking_category_pairs.csv"), row.names = FALSE)

review_pages <- list()
review_rows_read <- 0L
review_connection <- file("data/raw/yelp_academic_dataset_review.json", "r")
jsonlite::stream_in(review_connection, pagesize = 10000L, verbose = FALSE,
  handler = function(page) {
    review_rows_read <<- review_rows_read + nrow(page)
    keep <- page$business_id %in% restaurants$business_id
    if (any(keep)) {
      review_pages[[length(review_pages) + 1L]] <<-
        page[keep, c("review_id", "business_id", "user_id", "stars", "date"), drop = FALSE]
    }
    if (review_rows_read %% 1000000L == 0L) message("Scanned ", review_rows_read, " reviews.")
  })
close(review_connection)
reviews <- do.call(rbind, review_pages)
stopifnot(!anyDuplicated(reviews$review_id))
selected_reviews <- reviews[reviews$business_id %in% selected$business_id, , drop = FALSE]
saveRDS(reviews, file.path(output_dir, "reviews_new_orleans.rds"))
saveRDS(selected_reviews, file.path(output_dir, "reviews_new_orleans_cooking.rds"))

summary <- list(theme = "New Orleans cooking", selected_categories = selected_categories,
  inclusion_rule = "Match at least one selected category", ranking_size = ranking_size,
  new_orleans_restaurants = nrow(restaurants), selected_restaurants = nrow(selected),
  selected_open_restaurants = sum(selected$is_open == 1L, na.rm = TRUE),
  selected_missing_coordinates = sum(is.na(selected$latitude) | is.na(selected$longitude)),
  review_rows_scanned = review_rows_read, new_orleans_reviews = nrow(reviews),
  selected_reviews = nrow(selected_reviews),
  selected_restaurants_with_reviews = length(unique(selected_reviews$business_id)),
  review_date_min = min(selected_reviews$date), review_date_max = max(selected_reviews$date),
  geographic_systems_to_compare = c("ZIP Code Tabulation Areas (ZCTAs)", "New Orleans wards"),
  geographic_system = "Final choice undecided; official spatial joins have not been performed",
  open_status_rule = "Retain both open and closed businesses in the historical dataset")
jsonlite::write_json(summary, file.path(output_dir, "cooking_filter_summary.json"),
  pretty = TRUE, auto_unbox = TRUE)
message("Complete: ", nrow(selected_reviews), " theme reviews retained.")
