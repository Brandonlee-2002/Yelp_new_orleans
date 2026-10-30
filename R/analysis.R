# Run from the repository root: Rscript R/analysis.R
# Initial descriptive analysis. Run R/geography.R afterward for steps 3-6.
source("R/clean.R")
stopifnot(requireNamespace("ggplot2", quietly = TRUE))
library(ggplot2)
restaurants <- readRDS("data/new_orleans/business_new_orleans_cooking.rds")
reviews <- readRDS("data/new_orleans/reviews_new_orleans_cooking.rds")
dir.create("data/analysis", recursive = TRUE, showWarnings = FALSE)
dir.create("figures", recursive = TRUE, showWarnings = FALSE)
write_table <- function(x, filename) {
  write.csv(x, file.path("data/analysis", filename), row.names = FALSE, na = "")
}

# Audit every retained column, including blank strings (which are not NA).
audit <- function(x, dataset) {
  data.frame(dataset = dataset, column = names(x),
    missing_na = vapply(x, function(v) sum(is.na(v)), integer(1)),
    blank_text = vapply(x, function(v) {
      if (is.character(v)) sum(!is.na(v) & trimws(v) == "") else 0L
    }, integer(1)))
}
quality <- rbind(audit(restaurants, "restaurants"), audit(reviews, "reviews"))
write_table(quality, "missing_values.csv")
blank_address <- is.na(restaurants$address) | trimws(restaurants$address) == ""
write_table(restaurants[blank_address, c("business_id", "business_name", "address",
  "latitude", "longitude", "is_open")], "restaurants_missing_addresses.csv")
review_dates <- as.Date(reviews$date, format = "%Y-%m-%d")
checks <- data.frame(check = c("Duplicate business IDs", "Duplicate review IDs",
  "Reviews without a matching selected business", "Restaurants without reviews",
  "Invalid business ratings", "Invalid review ratings", "Invalid coordinates",
  "Invalid or missing review dates", "Invalid open-status values"),
  issues = c(sum(duplicated(restaurants$business_id)), sum(duplicated(reviews$review_id)),
    sum(!reviews$business_id %in% restaurants$business_id),
    sum(!restaurants$business_id %in% reviews$business_id),
    sum(is.na(restaurants$stars) | !restaurants$stars %in% seq(1, 5, 0.5)),
    sum(is.na(reviews$stars) | !reviews$stars %in% 1:5),
    sum(!is.finite(restaurants$latitude) | !is.finite(restaurants$longitude) |
        abs(restaurants$latitude) > 90 | abs(restaurants$longitude) > 180),
    sum(is.na(review_dates)), sum(is.na(restaurants$is_open) | !restaurants$is_open %in% 0:1)))
write_table(checks, "validation_checks.csv")
stopifnot(all(checks$issues == 0))

# Join restaurant-level review summaries back to the business table by business_id.
review_groups <- split(seq_len(nrow(reviews)), reviews$business_id)
review_summary <- do.call(rbind, lapply(names(review_groups), function(id) {
  ix <- review_groups[[id]]
  data.frame(business_id = id, available_reviews = length(ix),
    mean_review_stars = mean(reviews$stars[ix]),
    median_review_stars = median(reviews$stars[ix]),
    first_review = as.character(min(review_dates[ix])),
    last_review = as.character(max(review_dates[ix])))
}))
summary <- merge(restaurants, review_summary, by = "business_id", all.x = TRUE, sort = FALSE)
summary <- summary[match(restaurants$business_id, summary$business_id), ]
summary$review_count_difference <- summary$available_reviews - summary$review_count
stopifnot(nrow(summary) == nrow(restaurants), !anyNA(summary$available_reviews),
          sum(summary$available_reviews) == nrow(reviews))
write_table(summary, "restaurant_summary.csv")

# Categories overlap, so their restaurant and review totals are not additive.
tokens <- category_tokens(summary$categories)
category_summary <- do.call(rbind, lapply(selected_categories, function(category) {
  ix <- vapply(tokens, function(x) category %in% x, logical(1))
  data.frame(category = category, restaurants = sum(ix),
    marked_open = sum(summary$is_open[ix] == 1),
    mean_business_stars = mean(summary$stars[ix]),
    median_available_reviews = median(summary$available_reviews[ix]),
    available_reviews = sum(summary$available_reviews[ix]))
}))
write_table(category_summary, "category_summary.csv")

# Explore thresholds rather than silently impose one on the final top 15.
thresholds <- c(0L, 10L, 25L, 50L, 100L)
threshold_summary <- do.call(rbind, lapply(thresholds, function(threshold) {
  keep <- summary$available_reviews >= threshold
  data.frame(minimum_available_reviews = threshold, restaurants = sum(keep),
    marked_open_restaurants = sum(keep & summary$is_open == 1),
    mean_business_stars = mean(summary$stars[keep]))
}))
write_table(threshold_summary, "review_thresholds.csv")
activity <- table(reviews$user_id)
reviewer_thresholds <- do.call(rbind, lapply(c(1L, 3L, 5L, 10L), function(threshold) {
  eligible <- activity >= threshold
  data.frame(minimum_category_reviews = threshold, reviewers = sum(eligible),
    retained_reviews = sum(activity[eligible]),
    percent_reviews = 100 * sum(activity[eligible]) / nrow(reviews))
}))
write_table(reviewer_thresholds, "reviewer_thresholds.csv")

quantiles <- function(x, metric) {
  data.frame(metric = metric, minimum = min(x), q1 = unname(quantile(x, .25)),
    median = median(x), mean = mean(x), q3 = unname(quantile(x, .75)), maximum = max(x))
}
distributions <- rbind(quantiles(summary$stars, "Yelp business stars"),
  quantiles(summary$available_reviews, "Available reviews per restaurant"),
  quantiles(summary$mean_review_stars, "Mean available review stars per restaurant"))
write_table(distributions, "distributions.csv")

style <- theme_minimal(base_size = 12) + theme(plot.title = element_text(face = "bold"),
  panel.grid.minor = element_blank(), plot.caption = element_text(hjust = 0))
save_plot <- function(plot, name) {
  ggsave(file.path("figures", name), plot = plot + style, width = 9, height = 5.5,
    dpi = 160, bg = "white")
}
save_plot(ggplot(category_summary,
  aes(x = reorder(category, restaurants), y = restaurants)) +
  geom_col(fill = "#176B75", width = .65) + coord_flip() +
  geom_text(aes(label = restaurants), hjust = -.2) +
  scale_y_continuous(expand = expansion(mult = c(0, .15))) +
  labs(title = "New Orleans cooking: selected category counts", x = NULL,
    y = "Restaurants", caption = "672 unique restaurants; category memberships overlap."),
  "cooking_category_counts.png")
save_plot(ggplot(summary, aes(x = stars)) +
  geom_bar(fill = "#176B75", width = .4) +
  scale_x_continuous(breaks = seq(1, 5, .5)) +
  labs(title = "How Yelp business ratings are distributed", x = "Yelp business stars",
    y = "Restaurants", caption = "All 672 selected restaurants, including businesses marked closed."),
  "cooking_rating_distribution.png")
save_plot(ggplot(summary, aes(x = available_reviews, y = mean_review_stars,
  color = factor(is_open, levels = c(1, 0), labels = c("Marked open", "Marked closed")))) +
  geom_point(alpha = .55, size = 2) + scale_x_log10() +
  scale_color_manual(values = c("#176B75", "#C66B39")) +
  labs(title = "Ratings and review volume", x = "Available reviews (logarithmic scale)",
    y = "Mean stars from available reviews", color = "Historical status",
    caption = "Each point is one restaurant. Review dates end in January 2022."),
  "cooking_ratings_review_volume.png")

# Generate a report section from actual results, so it updates on reruns.
source("R/report_helpers.R")

nonzero <- quality[quality$missing_na > 0 | quality$blank_text > 0, ]
missing_text <- if (!nrow(nonzero)) {
  "No NA values or blank text fields were found in the retained restaurant and review columns."
} else {
  paste0("The missing-value audit found ", sum(quality$missing_na), " NA values and ",
    sum(quality$blank_text), " blank text fields. Details are shown below.")
}
lines <- c("## Initial descriptive results", "",
  sprintf("The filtered theme contains **%s restaurants** and **%s reviews** from **%s distinct reviewers**. Reviews span **%s to %s**.",
    format(nrow(summary), big.mark = ","), format(nrow(reviews), big.mark = ","),
    format(length(activity), big.mark = ","), min(review_dates), max(review_dates)), "",
  "### Data quality", "", missing_text, "",
  "Duplicate-ID, review-linkage, rating-range, coordinate-range, date-parsing, and open-status checks found no issues. Range checks do not establish coordinate accuracy, and absence of missing values does not establish overall accuracy.", "",
  if (nrow(nonzero)) md_table(nonzero) else NULL, "",
  "The seven blank street addresses are retained because coordinates are present. They have not been imputed or independently checked; see the exported missing-address table for follow-up.", "",
  sprintf("**%s businesses are marked open and %s marked closed** in the historical snapshot. No open-status exclusion has been applied; these flags do not verify current operating status.",
    sum(summary$is_open == 1), sum(summary$is_open == 0)), "",
  "### Category counts and overlap", "",
  "Memberships overlap: the four category counts must not be added together. Category means describe the included businesses; they are not independent cuisine comparisons.", "",
  md_table(category_summary), "", "![Restaurant counts for the four selected categories](figures/cooking_category_counts.png)", "",
  "### Ratings and review volume", "", md_table(distributions), "",
  "Business stars are Yelp's published business-level values. Mean review stars are recalculated from the available review records; they are separate measures. Each restaurant receives equal weight in the descriptive means above.", "",
  sprintf("Available-review counts differ from the business table's review_count for **%s restaurants**. Both counts are retained separately; threshold comparisons below use actual available review records. The cause of any differences has not been established.",
    sum(summary$review_count_difference != 0)), "",
  "![Distribution of Yelp business stars](figures/cooking_rating_distribution.png)", "",
  "![Restaurant average review stars versus available review volume](figures/cooking_ratings_review_volume.png)", "",
  "### Review-volume sensitivity", "",
  "These are alternative eligibility rules, not a selected cutoff. The marked-open column shows how an additional historical open-status filter would change the pool.", "",
  md_table(threshold_summary), "",
  "### Reviewer activity before normalization", "",
  "Activity counts use reviews within the selected category group. This table shows how much data remains at different reviewer thresholds; no reviewer-adjusted scores have been calculated yet.", "",
  md_table(reviewer_thresholds), "",
  "### What remains", "",
  "This initial section preserves the original 672-restaurant subset. The steps 3–6 section below completes the city-boundary and ZCTA/ward comparisons using the resulting 656 city-contained restaurants. Final eligibility rules, reviewer-adjusted scores, and the top 15 remain outstanding; the plots above are descriptive rather than final rankings.")
writeLines(lines, "initial_results.qmd")
message("Saved descriptive tables, three plots, and initial_results.qmd.")
