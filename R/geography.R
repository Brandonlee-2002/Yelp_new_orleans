# Steps 3-6. First run R/analysis.R and R/download_boundaries.R.
source("R/clean.R")
source("R/report_helpers.R")
library(sf)
library(ggplot2)
# Planar predicates in a local projected CRS avoid antimeridian/spherical edge effects.
analysis_crs <- 26982 # NAD83 / Louisiana South (metres)
read_boundary <- function(path) st_transform(st_make_valid(st_read(path, quiet=TRUE)), analysis_crs)
places <- read_boundary("data/boundaries/louisiana_places_2020.geojson")
city <- places[places$NAME == "New Orleans", ]
stopifnot(nrow(city)==1)
wards <- read_boundary("data/boundaries/new_orleans_wards.geojson")
zctas <- read_boundary("data/boundaries/zctas_2020_prefix70.geojson")
zctas <- zctas[lengths(st_intersects(zctas, city)) > 0, ]
zcta_id <- intersect(c("ZCTA5CE20", "ZCTA5CE10", "GEOID20", "GEOID"), names(zctas))[1]
stopifnot(!is.na(zcta_id))
zctas$area <- as.character(zctas[[zcta_id]])
wards$area <- paste("Ward", wards$WARD)
wards <- wards[order(as.integer(wards$WARD)), ]
write_table <- function(x, name) write.csv(x, file.path("data/analysis",name), row.names=FALSE, na="")
all_business <- readRDS("data/new_orleans/business_new_orleans.rds")
business <- readRDS("data/new_orleans/business_new_orleans_cooking.rds")
review_data <- readRDS("data/new_orleans/reviews_new_orleans_cooking.rds")
summary <- read.csv("data/analysis/restaurant_summary.csv", stringsAsFactors=FALSE,
  colClasses=c(postal_code="character"))
points <- st_transform(st_as_sf(all_business, coords=c("longitude","latitude"), crs=4326, remove=FALSE), analysis_crs)

# Step 5: assign every filtered New Orleans restaurant to Census place boundaries.
place_assignments <- st_join(points, places[, c("GEOID","NAME")], join=st_within, left=TRUE)
stopifnot(nrow(place_assignments)==nrow(points), !anyDuplicated(place_assignments$business_id))
place_assignments$place_status <- ifelse(is.na(place_assignments$NAME), "No place match",
  ifelse(place_assignments$NAME == "New Orleans", "Inside New Orleans", "Other Census place"))
place_data <- st_drop_geometry(place_assignments)
write_table(place_data, "restaurant_place_assignments.csv")
write_table(place_data[place_data$place_status != "Inside New Orleans", ], "place_mismatches.csv")
place_counts <- as.data.frame(table(place_data$place_status), stringsAsFactors=FALSE)
names(place_counts) <- c("Place assignment", "Restaurants")
write_table(place_counts, "place_assignment_counts.csv")

# Step 4: explicit many-to-one join, preserving every review exactly once.
# The saved RDS supports later reviewer normalization and is excluded from Git.
joined <- merge(review_data, business[,c("business_id","business_name","categories","matched_categories")],
  by="business_id", all.x=TRUE, sort=FALSE)
stopifnot(nrow(joined)==nrow(review_data), !anyDuplicated(joined$review_id), !anyNA(joined$business_name))
saveRDS(joined, "data/new_orleans/reviews_cooking_joined.rds")
join_audit <- data.frame(check=c("Selected restaurants","Reviews before join","Reviews after join",
  "Unmatched review businesses","Duplicate review IDs after join"),
  count=c(nrow(business), nrow(review_data), nrow(joined), sum(is.na(joined$business_name)), sum(duplicated(joined$review_id))))
write_table(join_audit,"review_join_audit.csv")
rm(joined)

selected_points <- points[match(summary$business_id, points$business_id), ]
selected_points$available_reviews <- summary$available_reviews
selected_points$mean_review_stars <- summary$mean_review_stars
assign <- function(boundaries, system) {
  out <- st_join(selected_points, boundaries[,"area",drop=FALSE], join=st_within, left=TRUE)
  stopifnot(nrow(out)==nrow(selected_points), !anyDuplicated(out$business_id))
  # Classify boundary-touching and outside points without silently snapping them.
  unmatched <- is.na(out$area)
  touching <- lengths(st_intersects(out[unmatched, ], boundaries)) > 0
  out$assignment_status <- ifelse(unmatched,"Outside boundaries","Within area")
  out$assignment_status[which(unmatched)[touching]] <- "On boundary; unassigned"
  d <- st_drop_geometry(out)
  stats <- do.call(rbind,lapply(boundaries$area,function(area) {
    x <- d[!is.na(d$area) & d$area==area,]
    n <- nrow(x)
    data.frame(system=system,area=area,restaurants=n,marked_open=sum(x$is_open==1),
      mean_business_stars=if(n) mean(x$stars) else NA_real_,
      median_business_stars=if(n) median(x$stars) else NA_real_,
      total_reviews=sum(x$available_reviews),
      mean_review_stars=if(n) mean(x$mean_review_stars) else NA_real_,
      sparse=n<10)
  }))
  write_table(d,paste0(tolower(system),"_restaurant_assignments.csv"))
  write_table(d[unmatched,],paste0(tolower(system),"_unmatched.csv"))
  write_table(stats,paste0(tolower(system),"_area_summary.csv"))
  populated <- stats$restaurants[stats$restaurants>0]
  comparison <- data.frame(system=system,boundary_areas=nrow(stats),populated_areas=length(populated),
    assigned=sum(!unmatched),unmatched=sum(unmatched),boundary_points=sum(touching),
    smallest_count=min(stats$restaurants),smallest_populated_count=min(populated),
    largest_count=max(stats$restaurants),median_populated_count=median(populated),
    areas_under_10=sum(stats$restaurants<10),empty_areas=sum(stats$restaurants==0),
    seven_area_requirement=length(populated)>=7)
  list(points=out,stats=stats,comparison=comparison,boundaries=boundaries)
}
# Preserve the initial Yelp-city-label results before choosing a city-only scope.
z_initial <- assign(zctas,"ZCTA")
w_initial <- assign(wards,"Ward")
write_table(rbind(z_initial$comparison,w_initial$comparison),"geography_initial_scope.csv")
initial_assignments <- data.frame(business_id=business$business_id,
  zcta=z_initial$points$area[match(business$business_id,z_initial$points$business_id)],
  ward=w_initial$points$area[match(business$business_id,w_initial$points$business_id)],
  place_name=place_data$NAME[match(business$business_id,place_data$business_id)])
initial_assignments$in_census_city <- !is.na(initial_assignments$place_name) & initial_assignments$place_name=="New Orleans"
write_table(initial_assignments,"cooking_geographic_assignments.csv")
# Explicit scope decision: compare identical city-contained businesses in both systems.
# Retain the 16 outside-city records in an audit rather than silently discard them.
inside <- initial_assignments$in_census_city
write_table(merge(business[!inside,],initial_assignments[!inside,],by="business_id"),
  "cooking_outside_city.csv")
outside_points <- selected_points[!inside, ]
outside_audit <- merge(st_drop_geometry(outside_points),initial_assignments[!inside,],by="business_id")
distance_to_city <- setNames(as.numeric(st_distance(outside_points,city)),outside_points$business_id)
outside_audit$distance_to_city_m <- unname(distance_to_city[outside_audit$business_id])
write_table(outside_audit,"cooking_outside_city.csv")
city_business <- business[inside,]
city_reviews <- review_data[review_data$business_id %in% city_business$business_id,]
saveRDS(city_business,"data/new_orleans/business_cooking_in_city.rds")
saveRDS(city_reviews,"data/new_orleans/reviews_cooking_in_city.rds")
selected_points <- selected_points[selected_points$business_id %in% city_business$business_id,]
z <- assign(zctas,"ZCTA")
w <- assign(wards,"Ward")
# Distances for unmatched ward locations help investigate shoreline gaps.
ward_unmatched <- w$points[is.na(w$points$area),]
if(nrow(ward_unmatched)) {
  nearest <- st_nearest_feature(ward_unmatched,wards)
  ward_unmatched$nearest_ward <- wards$area[nearest]
  ward_unmatched$distance_to_ward_m <- as.numeric(st_distance(ward_unmatched,wards[nearest,],by_element=TRUE))
  write_table(st_drop_geometry(ward_unmatched),"ward_unmatched.csv")
}
city_category_counts <- data.frame(category=selected_categories,
  initial_restaurants=vapply(selected_categories,function(cat) sum(vapply(category_tokens(business$categories),function(x) cat %in% x,logical(1))),integer(1)),
  city_restaurants=vapply(selected_categories,function(cat) sum(vapply(category_tokens(city_business$categories),function(x) cat %in% x,logical(1))),integer(1)))
write_table(city_category_counts,"category_scope_comparison.csv")
pairs <- combn(selected_categories,2)
city_pairs <- data.frame(category_1=pairs[1,],category_2=pairs[2,],
  restaurants=apply(pairs,2,function(pair) sum(vapply(category_tokens(city_business$categories),function(x) all(pair %in% x),logical(1)))))
write_table(city_pairs,"city_category_pairs.csv")
write_table(data.frame(scope=c("Initial Yelp city label","Inside Census city"),
  restaurants=c(nrow(business),nrow(city_business)),reviews=c(nrow(review_data),nrow(city_reviews)),
  marked_open=c(sum(business$is_open==1),sum(city_business$is_open==1))),"geographic_scope.csv")
comparison <- rbind(z$comparison,w$comparison)
write_table(comparison,"geography_comparison.csv")

# Category-by-area evidence uses the union as its base; category memberships overlap.
by_category <- do.call(rbind,lapply(list(z=z,w=w),function(result) {
 d <- st_drop_geometry(result$points)
 tokens <- category_tokens(d$categories)
 do.call(rbind,lapply(selected_categories,function(cat) {
   keep <- vapply(tokens,function(x) cat %in% x,logical(1))
   do.call(rbind,lapply(result$stats$area,function(area) {
    ix <- keep & !is.na(d$area) & d$area==area
    data.frame(system=result$stats$system[1],area=area,category=cat,restaurants=sum(ix),
      mean_business_stars=if(any(ix)) mean(d$stars[ix]) else NA_real_,
      total_reviews=sum(d$available_reviews[ix]))
   }))
 }))
}))
write_table(by_category,"category_by_area.csv")

# Maps display full city context plus a separate urban detail panel for readability.
city_box <- st_bbox(city)
urban <- st_bbox(c(xmin=-90.15,ymin=29.90,xmax=-89.98,ymax=30.04),crs=st_crs(4326))
urban_box <- st_bbox(st_transform(st_as_sfc(urban),analysis_crs))
map_theme <- theme_minimal(base_size=11)+theme(axis.text=element_text(size=7),
  plot.title=element_text(face="bold"),panel.grid.minor=element_blank(),
  plot.caption=element_text(hjust=0,size=9))
map_result <- function(result,system,detail=FALSE) {
 b <- result$boundaries
 b$n <- result$stats$restaurants[match(b$area,result$stats$area)]
 box <- if(detail) urban_box else city_box
 clipped <- suppressWarnings(st_intersection(b,st_geometry(city)))
 p <- ggplot()+geom_sf(data=clipped,aes(fill=n),color="white",linewidth=.25)+
   scale_fill_viridis_c(option="C",name="Restaurants",begin=.1,
     limits=c(0,max(z$stats$restaurants,w$stats$restaurants)))+
   geom_sf(data=city,fill=NA,color="grey35",linewidth=.35)+
   geom_sf(data=result$points,color="#15444c",size=.8,alpha=.65)+
   coord_sf(xlim=box[c("xmin","xmax")],ylim=box[c("ymin","ymax")],expand=FALSE)+
   labs(title=paste(system,"coverage:",if(detail) "urban detail" else "New Orleans"),
     subtitle=paste("New Orleans cooking;", nrow(selected_points), "city-contained restaurants"),
     caption="Area colors count restaurants inside full source polygons. Display clipped to Census city boundary.\nPoints outside a polygon are retained in assignment audits; maps do not establish current opening status.")+
   map_theme
 if(detail) {
  label_shapes <- clipped[clipped$n>0, ]
  labels <- st_point_on_surface(st_geometry(label_shapes))
  label_data <- st_sf(area=label_shapes$area,geometry=labels)
  xy <- st_coordinates(label_data)
  # Avoid labels for empty slivers or text cut off by the detail-panel edges.
  inset <- 300
  keep <- xy[,1]>box["xmin"]+inset & xy[,1]<box["xmax"]-inset &
    xy[,2]>box["ymin"]+inset & xy[,2]<box["ymax"]-inset
  label_data <- label_data[keep, ]
  p <- p+geom_sf_text(data=label_data,aes(label=area),size=2.8,check_overlap=TRUE)
 }
 ggsave(paste0("figures/cooking_",tolower(system),if(detail) "_detail" else "_map",".png"),p,
   width=9,height=6,dpi=160,bg="white")
}
for(detail in c(FALSE,TRUE)) { map_result(z,"ZCTA",detail); map_result(w,"Ward",detail) }
# Place-boundary map includes all 2,259 initial restaurants, including mismatches.
p <- ggplot()+geom_sf(data=city,fill="grey95",color="grey35")+
  geom_sf(data=place_assignments,aes(color=place_status),size=.8,alpha=.6)+
  scale_color_manual(values=c("Inside New Orleans"="#176b75","Other Census place"="#bf542d","No place match"="#8a3990"))+
  labs(title="Yelp city labels compared with the Census boundary",color="Place assignment",
    subtitle="All 2,259 initially filtered New Orleans restaurant businesses")+map_theme
 ggsave("figures/new_orleans_place_check.png",p,width=9,height=6,dpi=160,bg="white")
# Counts and ratings remain descriptive, particularly in sparsely populated areas.
counts <- rbind(z$stats,w$stats)
counts$area_label <- paste(counts$system,counts$area,sep=": ")
p <- ggplot(counts[counts$restaurants>0,],aes(x=reorder(area_label,restaurants),y=restaurants,fill=sparse))+
  geom_col()+coord_flip()+facet_wrap(~system,scales="free_y",ncol=2)+
  scale_fill_manual(values=c("FALSE"="#176b75","TRUE"="#cb7b48"),
    labels=c("FALSE"="10 or more","TRUE"="Fewer than 10"),name="Sample size")+
  labs(title="Restaurant coverage by geographic system",x=NULL,y="Restaurants",
    caption="Populated areas only. The 18 empty ZCTA intersections remain in the exported summary.")+map_theme
 ggsave("figures/cooking_area_counts.png",p,width=12,height=8,dpi=160,bg="white")
# Area ratings are equal-weight means across businesses; show sample size.
rating_data <- counts[counts$restaurants>0,]
rating_data$label <- paste0(rating_data$area," (n=",rating_data$restaurants,")")
p <- ggplot(rating_data,aes(x=reorder(label,mean_business_stars),y=mean_business_stars,color=sparse))+
  geom_point(size=2.5)+coord_flip()+facet_wrap(~system,scales="free_y",ncol=2)+
  scale_color_manual(values=c("FALSE"="#176b75","TRUE"="#cb7b48"),
    labels=c("FALSE"="10 or more","TRUE"="Fewer than 10"),name="Sample size")+
  labs(title="Raw business ratings by area",x=NULL,y="Mean Yelp business stars",
    caption="Each restaurant has equal weight. Small-area results are descriptive; rankings are not reviewer-adjusted.")+map_theme
ggsave("figures/cooking_area_ratings.png",p,width=12,height=8,dpi=160,bg="white")
# Persist a compact analysis GeoPackage for reproducible map inspection.
# Separate layers avoid duplicating full review data in geographic files.
for(layer in c("city","zcta","ward")) {
 x <- switch(layer,city=city,zcta=z$boundaries,ward=w$boundaries)
 st_write(x,"data/boundaries/analysis_boundaries.gpkg",layer=layer,delete_layer=TRUE,quiet=TRUE)
}

# Presentation tables use short labels, while CSV exports retain analytic names.
report_table <- function(x, labels) { names(x)<-labels; md_table(x) }
area_report <- function(x) {
 x<-x[x$restaurants>0,c("area","restaurants","marked_open","mean_business_stars","total_reviews")]
 x<-x[order(-x$restaurants),]
 report_table(x,c("Area","Restaurants","Marked open","Mean stars","Reviews"))
}
comparison_display <- comparison[,c("system","populated_areas","assigned","unmatched","smallest_populated_count","largest_count")]
join_display <- join_audit
geo_lines <- c("## Steps 3–6: categories, joins, and geography", "",
  "### Step 3: category evidence", "",
  "The selected New Orleans cooking theme connects Cajun/Creole, seafood, Southern, and soul-food traditions. A restaurant qualifies by matching at least one selected category, rather than all four. The labels are an operational definition, not proof that every menu is uniquely local. Category memberships overlap.", "",
  "The initial city-label subset contains 672 restaurants. After the explicit city-boundary check below, 656 restaurants remain in the geographic comparison:", "",
  report_table(city_category_counts,c("Category","Initial subset","Inside city")), "",
  "Co-occurrence among the 656 city-contained restaurants supports analyzing the labels together:", "",
  report_table(city_pairs,c("Category 1","Category 2","Restaurants")), "",
  "The selected group occupies **17 ZCTAs and all 17 wards**. Both systems exceed the requirement of 10 restaurants across seven geographic areas. Category-by-area counts, average ratings, and review volumes are exported in [category_by_area.csv](https://github.com/Brandonlee-2002/Yelp_new_orleans/blob/main/data/analysis/category_by_area.csv).", "",
  "### Step 4: businesses joined to reviews", "",
  "Reviews were filtered before joining. An explicit many-to-one join on business_id attaches business names and categories to every selected review, preserving review IDs and the row count. The joined review-level RDS is saved locally as data/new_orleans/reviews_cooking_joined.rds; the smaller audit is committed.", "",
  report_table(join_display,c("Check","Count")), "",
  sprintf("The later city-only geographic subset contains **%s reviews** for 656 restaurants. The original 250,304-review subset is preserved; the new city-only RDS files are separate.",format(nrow(city_reviews),big.mark=",")), "",
  "### Step 5: official city-boundary check", "",
  "All 2,259 initial New Orleans restaurant locations were spatially joined to 2020 Census Louisiana place polygons using sf::st_join and st_within. The join assigns 2,202 to New Orleans and 57 to other Census places; no locations lack a place match. Among the selected theme, 656 are in New Orleans and 16 are assigned to nearby places such as Jefferson, Harahan, and Elmwood.", "",
  "For the main geographic comparison, use the official city-contained subset so ZCTAs and wards describe the same city. This is an explicit analytical scope choice, not deletion of the original records. City-label mismatches may reflect postal labeling, geocoding, mobile businesses, or boundary differences; their specific causes are not established. The export includes place names and distances to the city for review. Le Petit Bistro, for example, has a blank address and coordinates in Kenner despite a New Orleans postal label and requires further checking.", "",
  "[All place assignments](https://github.com/Brandonlee-2002/Yelp_new_orleans/blob/main/data/analysis/restaurant_place_assignments.csv) · [Selected restaurants outside the city](https://github.com/Brandonlee-2002/Yelp_new_orleans/blob/main/data/analysis/cooking_outside_city.csv)", "",
  "![Census boundary and all initially filtered restaurant locations](figures/new_orleans_place_check.png)", "",
  "### Step 6: ZCTAs compared with wards", "",
  "Restaurant coordinates are transformed from longitude/latitude (EPSG:4326) to NAD83 / Louisiana South in metres (EPSG:26982). Polygon validity is repaired before spatial joins. The same 656 city-contained locations are joined to each system with st_within. No nearest-area assignment or snapping is applied. The joins are checked for duplicated businesses and boundary-touching points.", "",
  report_table(comparison_display,c("System","Populated areas","Assigned","Unmatched","Min count*","Max count")), "",
  "*Minimum among populated areas. Of 35 ZCTA polygons intersecting the city, 18 contain no selected city restaurants and five populated ZCTAs contain fewer than 10. All 17 wards contain selected restaurants, and only Ward 16 has fewer than 10 (five). Empty and small areas are retained in the exported summaries. Empty areas have no rating, not a rating of zero.", "",
  "The two unmatched ward locations are Felix's Restaurant & Oyster Bar and Brisbi's Lakefront Restaurant & Bar, both at 7400 Lakeshore Drive. They fall inside the Census city but approximately 16.3 and 13.4 metres outside the nearest Ward 4 polygon. These shoreline discrepancies could reflect coordinate or boundary precision; they are not corrected without further evidence. Both receive ZCTA 70124. They remain in the city dataset and are omitted only from ward-level aggregates.", "",
  "[Complete comparison](https://github.com/Brandonlee-2002/Yelp_new_orleans/blob/main/data/analysis/geography_comparison.csv) · [Unmatched ward locations](https://github.com/Brandonlee-2002/Yelp_new_orleans/blob/main/data/analysis/ward_unmatched.csv)", "",
  "![ZCTA boundaries and selected restaurant locations across New Orleans](figures/cooking_zcta_map.png)", "",
  "![ZCTA boundaries and restaurant locations in the urban core](figures/cooking_zcta_detail.png)", "",
  "![Ward boundaries and selected restaurant locations across New Orleans](figures/cooking_ward_map.png)", "",
  "![Ward boundaries and restaurant locations in the urban core](figures/cooking_ward_detail.png)", "",
  "The full-city maps preserve the geographic context; the urban-detail panels make the dense restaurant cluster readable. Colors describe counts in the full source areas, using only city-contained restaurants. Displayed boundaries are clipped to the Census city. ZCTAs are Census approximations of postal service areas, not neighborhoods; wards are the City's numbered divisions, not neighborhood labels.", "",
  "![Restaurant counts by ZCTA and ward](figures/cooking_area_counts.png)", "",
  "![Average raw business ratings by ZCTA and ward, with sample sizes](figures/cooking_area_ratings.png)", "",
  "#### Main geographic choice: wards", "",
  "Use **wards** for the main area comparison and keep ZCTAs as the sensitivity comparison. Wards divide this restaurant pool more evenly: the median populated-area count is 25 versus 16 for ZCTAs, the largest ward contains 116 restaurants versus 213 in the largest ZCTA, and only one ward has fewer than 10 restaurants versus five populated ZCTAs. Both systems offer 17 populated areas. Wards therefore reduce the number of very small samples while retaining city-specific numbered areas that can be shown clearly on maps. This choice follows coverage and sample-size evidence, not which system yields a higher rating.", "",
  "The tradeoffs are the two unmatched lakefront points, the need to explain ward numbers to visitors, and broad wards that can hide variation within an area. Ward 16's five restaurants are too few for a strong area-level recommendation; its rating remains descriptive. ZCTAs offer familiar postal-style identifiers and complete assignment of the city subset, so both sets of results remain available. Restaurant counts measure selection, not density per square kilometre or travel convenience.", "",
  "#### Area summaries", "",
  "Means below give each restaurant equal weight, not each review. Review totals indicate evidence volume but do not establish independence or uncertainty. These are historical raw-rating summaries; the reviewer-adjusted comparison in Step 7 remains outstanding.", "",
  "**Wards**", "", area_report(w$stats), "",
  "**ZCTAs**", "", area_report(z$stats), "",
  "Ward 4 has the most qualifying restaurants (116); Ward 13 has the highest mean business rating among wards with at least 10 restaurants (4.15, n=20), narrowly ahead of Ward 8 (4.147, n=17). This is not enough to declare a final best area. ZCTA 70130 has the largest selection (213), while 70117 leads populated ZCTAs with at least 10 restaurants in raw mean stars (4.13, n=30). Ratings must still be checked against reviewer adjustment and final eligibility rules.", "",
  "#### Boundary sources and time limitations", "",
  "Census boundaries: [2020 TIGER/Line place files](https://www.census.gov/geographies/mapping-files/time-series/geo/tiger-line-file.html) and [2020 cartographic ZCTA boundaries](https://www.census.gov/geographies/mapping-files/time-series/geo/cartographic-boundary.html), obtained with tigris. Wards: [City of New Orleans Enterprise GIS, Administrative Layers, Wards layer 3](https://maps.nola.gov/server/rest/services/Administrative/Administrative_Layers/MapServer/3), downloaded October 29, 2026. The ward service does not state a historical effective date; it is a saved current-service snapshot, not verified 2020 ward geometry. Yelp reviews span 2005–2022, so neither boundary set proves which area applied at every review date. Saved boundaries, source metadata, and checksums support reproduction; no demographic or causal claims are made.")
writeLines(geo_lines,"geographic_results.qmd")
message("Steps 3-6 tables and maps saved.")
print(comparison)
print(place_counts)
