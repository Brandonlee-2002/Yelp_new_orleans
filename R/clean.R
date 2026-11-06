source("R/config.R")

category_tokens <- function(x) {
  lapply(strsplit(ifelse(is.na(x), "", x), ",", fixed = TRUE), function(values) {
    values <- trimws(values)
    values[nzchar(values)]
  })
}

# One row per business/category membership.  Keeping this long form makes
# category counts and co-occurrence logic auditable instead of string-based.
category_long <- function(business, categories = selected_categories) {
  tokens <- category_tokens(business$categories)
  rows <- lapply(seq_along(tokens), function(i) {
    matched <- intersect(tokens[[i]], categories)
    if (!length(matched)) return(NULL)
    data.frame(business_id = business$business_id[i], category = matched,
      stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, rows)
  if (is.null(out)) data.frame(business_id=character(), category=character()) else out
}

clean_new_orleans_restaurants <- function(business) {
  tokens <- category_tokens(business$categories)
  keep <- !is.na(business$state) & business$state == "LA" &
    !is.na(business$city) & tolower(trimws(business$city)) == "new orleans" &
    vapply(tokens, function(x) "Restaurants" %in% x, logical(1))
  result <- business[keep, , drop = FALSE]
  result <- result[!duplicated(result$business_id), , drop = FALSE]
  result$business_name <- trimws(result$name)
  result$postal_code[result$postal_code == ""] <- NA_character_
  result
}

select_cooking_restaurants <- function(restaurants) {
  tokens <- category_tokens(restaurants$categories)
  keep <- vapply(tokens, function(x) any(x %in% selected_categories), logical(1))
  result <- restaurants[keep, , drop = FALSE]
  result$matched_categories <- vapply(tokens[keep], function(x) {
    paste(selected_categories[selected_categories %in% x], collapse = "; ")
  }, character(1))
  result
}
