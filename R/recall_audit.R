# Full city-label recall audit. Requires the original Yelp JSON files.
source("R/clean.R")
stopifnot(requireNamespace("jsonlite",quietly=TRUE),requireNamespace("sf",quietly=TRUE))
business_path <- "data/raw/yelp_academic_dataset_business.json"
review_path <- "data/raw/yelp_academic_dataset_review.json"
if(!file.exists(business_path) || !file.exists(review_path)) stop("Raw Yelp JSON files are required for the full city-label recall audit.")

business_pages <- list()
con <- file(business_path,"r")
jsonlite::stream_in(con,pagesize=10000L,verbose=FALSE,handler=function(page){
  cols <- c("business_id","name","city","state","latitude","longitude","categories","is_open")
  x <- page[,intersect(cols,names(page)),drop=FALSE]
  keep <- !is.na(x$state) & x$state=="LA" & is.finite(x$latitude) & is.finite(x$longitude) &
    vapply(category_tokens(x$categories),function(z) "Restaurants" %in% z,logical(1))
  if(any(keep)) business_pages[[length(business_pages)+1L]] <<- x[keep,,drop=FALSE]
})
close(con)
la_restaurants <- do.call(rbind,business_pages)
places <- sf::st_transform(sf::st_make_valid(sf::st_read("data/boundaries/louisiana_places_2020.geojson",quiet=TRUE)),26982)
city <- places[places$NAME=="New Orleans",]
pts <- sf::st_transform(sf::st_as_sf(la_restaurants,coords=c("longitude","latitude"),crs=4326,remove=FALSE),26982)
inside <- lengths(sf::st_within(pts,city))>0
tokens <- category_tokens(la_restaurants$categories)
theme <- vapply(tokens,function(z) any(z %in% selected_categories),logical(1))
existing <- readRDS("data/new_orleans/business_cooking_in_city.rds")
extra <- la_restaurants[inside & theme & !la_restaurants$business_id %in% existing$business_id,,drop=FALSE]
extra$matched_categories <- vapply(category_tokens(extra$categories),function(z) paste(intersect(z,selected_categories),collapse="; "),character(1))

review_counts <- setNames(integer(nrow(extra)),extra$business_id)
if(nrow(extra)) {
  ids <- extra$business_id
  con <- file(review_path,"r")
  jsonlite::stream_in(con,pagesize=10000L,verbose=FALSE,handler=function(page){
    hit <- page$business_id %in% ids
    if(any(hit)) { counts <- table(page$business_id[hit]); review_counts[names(counts)] <<- review_counts[names(counts)] + as.integer(counts) }
  })
  close(con)
}
out <- extra[,c("business_id","name","city","state","latitude","longitude","categories","matched_categories","is_open"),drop=FALSE]
out$available_reviews <- unname(review_counts[out$business_id])
write.csv(out,"data/analysis/city_label_recall_extra_businesses.csv",row.names=FALSE,na="")
summary <- data.frame(initial_exact_label_theme_restaurants=nrow(existing),extra_inside_city_theme_restaurants=nrow(extra),extra_inside_city_theme_reviews=sum(out$available_reviews),stringsAsFactors=FALSE)
write.csv(summary,"data/analysis/city_label_recall_audit.csv",row.names=FALSE)
message("Recall audit complete: ",nrow(extra)," additional theme businesses and ",sum(out$available_reviews)," reviews.")
