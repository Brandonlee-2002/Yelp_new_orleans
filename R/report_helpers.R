# Presentation helpers shared by the report-generating scripts.
md_table <- function(x) {
  labels <- c(dataset = "Dataset", column = "Column", missing_na = "NA values",
    blank_text = "Blank fields", category = "Category", restaurants = "Restaurants",
    marked_open = "Marked open", mean_business_stars = "Mean stars",
    median_available_reviews = "Median reviews", available_reviews = "Total reviews",
    metric = "Measure", minimum = "Min", q1 = "Q1", median = "Median", mean = "Mean",
    q3 = "Q3", maximum = "Max", minimum_available_reviews = "Min reviews",
    marked_open_restaurants = "Marked open", minimum_category_reviews = "Min reviews per reviewer",
    reviewers = "Reviewers", retained_reviews = "Reviews retained", percent_reviews = "Reviews retained (%)")
  headings <- unname(labels[names(x)])
  headings[is.na(headings)] <- names(x)[is.na(headings)]
  x[] <- lapply(x, function(v) if (is.numeric(v)) format(round(v, 2), big.mark = ",", trim = TRUE) else as.character(v))
  c('::: {.report-table tabindex="0" role="region" aria-label="Scrollable data table"}', "",
    paste0("| ", paste(headings, collapse = " | "), " |"),
    paste0("| ", paste(rep("---", ncol(x)), collapse = " | "), " |"),
    apply(x, 1, function(row) paste0("| ", paste(row, collapse = " | "), " |")),
    "", ":::")
}
