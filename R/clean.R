# Exact tokens prevent partial matches such as "Seafood Markets".
selected_categories <- c("Cajun/Creole", "Seafood", "Southern", "Soul Food")
ranking_size <- 15L

category_tokens <- function(x) {
  lapply(strsplit(ifelse(is.na(x), "", x), ",", fixed = TRUE), trimws)
}

clean_new_orleans_restaurants <- function(business) {
  tokens <- category_tokens(business$categories)
  keep <- !is.na(business$state) & business$state == "LA" &
    !is.na(business$city) & business$city == "New Orleans" &
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
