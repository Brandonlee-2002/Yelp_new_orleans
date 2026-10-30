# Final reviewer-adjusted analysis. Run after R/analysis.R and R/geography.R.
source("R/report_helpers.R")
library(ggplot2)
library(sf)
library(ggrepel)
b <- readRDS("data/new_orleans/business_cooking_in_city.rds")
r <- readRDS("data/new_orleans/reviews_cooking_in_city.rds")
base <- read.csv("data/analysis/restaurant_summary.csv",stringsAsFactors=FALSE)
base <- base[match(b$business_id,base$business_id),]
g <- read.csv("data/analysis/cooking_geographic_assignments.csv",stringsAsFactors=FALSE,
  colClasses=c(zcta="character"),na.strings="")
base <- merge(base,g[,c("business_id","ward","zcta")],by="business_id",all.x=TRUE,sort=FALSE)
write_table <- function(x,name) write.csv(x,file.path("data/analysis",name),row.names=FALSE,na="")
# Baselines are calculated within the complete city/category review pool.
user_scores <- split(r$stars,r$user_id)
baselines <- data.frame(user_id=names(user_scores),
  reviews=vapply(user_scores,length,integer(1)),
  mean=vapply(user_scores,mean,numeric(1)),
  median=vapply(user_scores,median,numeric(1)))
ix <- match(r$user_id,baselines$user_id)
r$user_activity <- baselines$reviews[ix]
r$normalized_mean <- r$stars-baselines$mean[ix]
r$normalized_median <- r$stars-baselines$median[ix]
stopifnot(!anyNA(ix),abs(sum(r$normalized_mean))<1e-7)
saveRDS(baselines,"data/new_orleans/reviewer_baselines_in_city.rds")
reviewer_thresholds <- do.call(rbind,lapply(c(1,3,5,10),function(k) {
 data.frame(minimum_reviews=k,reviewers=sum(baselines$reviews>=k),
   reviews=sum(r$user_activity>=k),percent=100*mean(r$user_activity>=k))
}))
write_table(reviewer_thresholds,"final_reviewer_thresholds.csv")
fit <- function(k) {
 eligible_reviews <- r[r$user_activity>=k,]
 groups <- split(seq_len(nrow(eligible_reviews)),eligible_reviews$business_id)
 s <- do.call(rbind,lapply(names(groups),function(id) {
  x <- eligible_reviews[groups[[id]],]
  data.frame(business_id=id,eligible_reviews=nrow(x),eligible_reviewers=length(unique(x$user_id)),
   eligible_raw_mean=mean(x$stars),adjusted_mean=mean(x$normalized_mean),
   median_baseline_score=mean(x$normalized_median),median_normalized_score=median(x$normalized_mean))
 }))
 out <- merge(base,s,by="business_id",all.x=TRUE,sort=FALSE)
 out$eligible_reviews[is.na(out$eligible_reviews)]<-0
 out$eligible_reviewers[is.na(out$eligible_reviewers)]<-0
 out
}
rank_pool <- function(x,minimum_all=50,minimum_users=20,score="adjusted_mean") {
 keep <- x$is_open==1 & x$available_reviews>=minimum_all & x$eligible_reviewers>=minimum_users & is.finite(x[[score]])
 out <- x[keep,]
 out <- out[order(-out[[score]],-out$mean_review_stars,-out$available_reviews,out$business_id),]
 out$rank <- seq_len(nrow(out))
 out
}
primary <- fit(5)
pool <- rank_pool(primary)
stopifnot(nrow(pool)>=15)
raw_order <- order(-pool$mean_review_stars,-pool$available_reviews,pool$business_id)
pool$raw_rank <- match(pool$business_id,pool$business_id[raw_order])
pool$rank_change <- pool$raw_rank-pool$rank
pool$selection_effect <- pool$eligible_raw_mean-pool$mean_review_stars
write_table(primary,"reviewer_adjusted_restaurants.csv")
write_table(pool,"eligible_restaurant_rankings.csv")
top <- head(pool,15)
write_table(top,"top_15_restaurants.csv")
write_table(head(pool[order(-abs(pool$rank_change)),
 c("business_name","raw_rank","rank","rank_change","mean_review_stars","eligible_raw_mean","adjusted_mean","eligible_reviewers")],10),"largest_ranking_changes.csv")

# Sensitivity uses the same raw city data and explicit alternative eligibility rules.
scenarios <- data.frame(scenario=c("Primary","Reviewers: 3+","Reviewers: 10+","All reviews: 25+","All reviews: 100+","Eligible reviewers: 10+","Eligible reviewers: 30+","Median baseline"),
 k=c(5,3,10,5,5,5,5,5),all=c(50,50,50,25,100,50,50,50),users=c(20,20,20,20,20,10,30,20),
 score=c(rep("adjusted_mean",7),"median_baseline_score"))
fits <- list(`3`=fit(3),`5`=primary,`10`=fit(10))
sensitivity <- do.call(rbind,lapply(seq_len(nrow(scenarios)),function(i) {
 scenario <- scenarios[i,]
 alt <- rank_pool(fits[[as.character(scenario$k)]],scenario$all,scenario$users,scenario$score)
 common <- intersect(pool$business_id,alt$business_id)
 data.frame(scenario=scenario$scenario,reviewer_threshold=scenario$k,minimum_all=scenario$all,
  minimum_reviewers=scenario$users,eligible_restaurants=nrow(alt),top_list_size=min(15,nrow(alt)),
  top_15_overlap=sum(head(alt$business_id,15) %in% top$business_id),
  common_pool_spearman=if(length(common)>2) cor(pool$rank[match(common,pool$business_id)],alt$rank[match(common,alt$business_id)],method="spearman") else NA_real_)
}))
raw_top <- pool[raw_order,]
sensitivity <- rbind(sensitivity,data.frame(scenario="Raw all-review stars",reviewer_threshold=5,
 minimum_all=50,minimum_reviewers=20,eligible_restaurants=nrow(pool),top_list_size=15,
 top_15_overlap=sum(head(raw_top$business_id,15) %in% top$business_id),
 common_pool_spearman=cor(pool$rank,pool$raw_rank,method="spearman")))
write_table(sensitivity,"ranking_sensitivity.csv")

area_scores <- function(system,field) {
 areas <- read.csv(paste0("data/analysis/",tolower(system),"_area_summary.csv"),colClasses=c(area="character"))
 do.call(rbind,lapply(areas$area,function(area) {
   x <- pool[!is.na(pool[[field]]) & pool[[field]]==area,]
   n <- nrow(x)
   data.frame(system=system,area=area,eligible_restaurants=n,
     all_city_restaurants=areas$restaurants[match(area,areas$area)],
     mean_adjusted=if(n) mean(x$adjusted_mean) else NA_real_,
     mean_raw=if(n) mean(x$mean_review_stars) else NA_real_,
     mean_eligible_raw=if(n) mean(x$eligible_raw_mean) else NA_real_,
     total_reviews=sum(x$available_reviews),eligible_reviews=sum(x$eligible_reviews),
     top_15=sum(top$business_id %in% x$business_id),rankable=n>=10)
 }))
}
ward <- area_scores("Ward","ward")
zcta <- area_scores("ZCTA","zcta")
area_all <- rbind(ward,zcta)
write_table(area_all,"adjusted_area_summary.csv")
ward_candidates <- ward[ward$rankable,]
ward_candidates <- ward_candidates[order(-ward_candidates$mean_adjusted,-ward_candidates$eligible_restaurants,ward_candidates$area),]
stopifnot(nrow(ward_candidates)>0)
best <- ward_candidates[1,]
write_table(ward_candidates,"recommended_ward_comparison.csv")
# Area recommendation sensitivity: mean/median baselines, activity and business thresholds.
area_sensitivity <- do.call(rbind,lapply(seq_len(nrow(scenarios)),function(i) {
 s <- scenarios[i,]
 alt <- rank_pool(fits[[as.character(s$k)]],s$all,s$users,s$score)
 areas <- split(alt[!is.na(alt$ward),],alt$ward[!is.na(alt$ward)])
 eligible_areas <- areas[vapply(areas,nrow,integer(1))>=10]
 if(!length(eligible_areas)) return(data.frame(scenario=s$scenario,best_ward=NA_character_,mean_score=NA_real_,rankable_wards=0))
 scores <- vapply(eligible_areas,function(x) mean(x[[s$score]]),numeric(1))
 winner <- names(sort(scores,decreasing=TRUE))[1]
 data.frame(scenario=s$scenario,best_ward=winner,mean_score=scores[winner],rankable_wards=length(scores))
}))
write_table(area_sensitivity,"area_recommendation_sensitivity.csv")
# The area minimum is itself a choice: test it directly, not only indirectly
# through changing restaurant eligibility.
for (minimum_area in c(5L,15L)) {
 candidates <- ward[ward$eligible_restaurants>=minimum_area,]
 candidates <- candidates[order(-candidates$mean_adjusted,-candidates$eligible_restaurants,candidates$area),]
 area_sensitivity <- rbind(area_sensitivity,data.frame(
   scenario=paste0("Area minimum: ",minimum_area,"+"),best_ward=candidates$area[1],
   mean_score=candidates$mean_adjusted[1],rankable_wards=nrow(candidates)))
}
write_table(area_sensitivity,"area_recommendation_sensitivity.csv")

style <- theme_minimal(base_size=12)+theme(plot.title=element_text(face="bold",size=15),
 plot.subtitle=element_text(color="#52666b"),panel.grid.minor=element_blank(),
 plot.caption=element_text(hjust=0,size=9),plot.margin=margin(14,18,14,14))
# Adjusted vs raw scores show how the definition of 'best' changes the result.
p <- ggplot(pool,aes(x=mean_review_stars,y=adjusted_mean))+
 geom_hline(yintercept=0,color="grey65",linetype="dashed")+
 geom_point(aes(size=eligible_reviewers),alpha=.4,color="#176b75")+
 geom_point(data=top,color="#b56a26",size=2.5)+
 geom_text_repel(data=top,aes(label=rank),seed=42,size=3,max.overlaps=Inf)+
 labs(title="The ranking changes when reviewer habits are considered",
 subtitle="Numbers identify the final top 15; only eligible restaurants are shown",
 x="Average stars · all available reviews",y="Average reviewer-adjusted deviation (star points)",
 size="Eligible reviewers",caption="Adjusted scores are deviations from each reviewer's usual score, not new Yelp ratings.")+style
 ggsave("figures/final_raw_vs_adjusted.png",p,width=10,height=6,dpi=180,bg="white")
area_plot <- ward[ward$eligible_restaurants>0,]
area_plot$label <- paste0(area_plot$area," · n=",area_plot$eligible_restaurants)
p <- ggplot(area_plot,aes(x=reorder(label,mean_adjusted),y=mean_adjusted))+
 geom_hline(yintercept=0,color="grey65")+
 geom_point(aes(color=rankable),size=3)+coord_flip()+
 scale_color_manual(values=c("FALSE"="#9ba7a7","TRUE"="#176b75"),labels=c("FALSE"="Fewer than 10 eligible restaurants","TRUE"="10+ eligible restaurants"),name=NULL)+
 labs(title="Which ward offers the strongest adjusted restaurant pool?",
 subtitle="Each eligible restaurant has equal weight; n is the eligible restaurant count",
 x=NULL,y="Mean restaurant-level adjusted deviation (star points)",
 caption="Area recommendation requires 10+ eligible restaurants. Differences are descriptive, not significance tests.")+style+
 theme(legend.position="bottom")
 ggsave("figures/final_ward_scores.png",p,width=10,height=7,dpi=180,bg="white")

# Final boundary map includes all ranked restaurants, even if a ward is unassigned.
wards <- st_read("data/boundaries/analysis_boundaries.gpkg",layer="ward",quiet=TRUE)
city <- st_read("data/boundaries/analysis_boundaries.gpkg",layer="city",quiet=TRUE)
pts <- st_transform(st_as_sf(top,coords=c("longitude","latitude"),crs=4326,remove=FALSE),st_crs(wards))
xy <- st_coordinates(pts)
map_labels <- cbind(st_drop_geometry(pts),x=xy[,1],y=xy[,2])
box <- st_bbox(pts); pad <- max(1500, .08*max(box["xmax"]-box["xmin"],box["ymax"]-box["ymin"]))
wards$recommended <- wards$area==best$area
p <- ggplot()+geom_sf(data=wards,aes(fill=recommended),color="white",linewidth=.5)+
 scale_fill_manual(values=c("FALSE"="#e5ece9","TRUE"="#f3d7a1"),guide="none")+
 geom_sf(data=city,fill=NA,color="#829591",linewidth=.35)+
 geom_sf(data=pts,color="#123f48",size=2.2)+
 geom_label_repel(data=map_labels,aes(x=x,y=y,label=rank),seed=42,max.overlaps=Inf,
  min.segment.length=0,box.padding=.35,point.padding=.2,size=3.5,fill="white",color="#123f48")+
 coord_sf(xlim=c(box["xmin"]-pad,box["xmax"]+pad),ylim=c(box["ymin"]-pad,box["ymax"]+pad),expand=FALSE)+
 labs(title="The top 15, located within New Orleans wards",
 subtitle=paste0("Numbers match the ranking table · ",best$area," highlighted as the recommended area"),
 x=NULL,y=NULL,caption="Official City ward snapshot, downloaded October 29, 2026. Locations and open-status flags are historical.\nRecommendations describe the Yelp dataset ending in January 2022, not verified current operations.")+style
 ggsave("figures/final_top_15_map.png",p,width=11,height=8,dpi=180,bg="white")
# Citywide context locator uses the same points and actual ward boundaries.
p2 <- ggplot()+geom_sf(data=wards,fill="#e5ece9",color="white",linewidth=.3)+
 geom_sf(data=city,fill=NA,color="#829591")+geom_sf(data=pts,color="#b56a26",size=1.7)+
 labs(title="Citywide context",subtitle="All 15 ranked restaurants",x=NULL,y=NULL)+style
 ggsave("figures/final_city_locator.png",p2,width=9,height=5,dpi=160,bg="white")

# Machine-readable summary drives the report and final audit.
metrics <- list(city_restaurants=nrow(b),city_reviews=nrow(r),city_reviewers=nrow(baselines),
 eligible_reviewers=sum(baselines$reviews>=5),eligible_reviews=sum(r$user_activity>=5),
 eligible_review_percent=100*mean(r$user_activity>=5),eligible_restaurants=nrow(pool),
 marked_open=sum(b$is_open==1),best_restaurant=top$business_name[1],best_ward=best$area,
 best_ward_score=best$mean_adjusted,best_ward_restaurants=best$eligible_restaurants,
 best_ward_top_15=best$top_15,rankable_wards=nrow(ward_candidates),
 top15_unmatched_ward=sum(is.na(top$ward)),pool_unmatched_ward=sum(is.na(pool$ward)),
 raw_adjusted_top15_overlap=sum(head(raw_top$business_id,15) %in% top$business_id),
 raw_adjusted_spearman=cor(pool$rank,pool$raw_rank,method="spearman"),
 area_sensitivity_same_winner=sum(area_sensitivity$best_ward==best$area,na.rm=TRUE),
 area_sensitivity_scenarios=nrow(area_sensitivity),
 current_operating_status_verified=FALSE)
jsonlite::write_json(metrics,"data/analysis/final_metrics.json",auto_unbox=TRUE,pretty=TRUE)
# Integrity checks: every recommendation satisfies the stated evidence rule.
checks <- c(top15_unique=nrow(top)==15&&!anyDuplicated(top$business_id),
 all_marked_open=all(top$is_open==1),minimum_50_reviews=all(top$available_reviews>=50),
 minimum_20_eligible_reviewers=all(top$eligible_reviewers>=20),
 all_have_coordinates=all(is.finite(top$latitude)&is.finite(top$longitude)),
 review_baselines_centered=abs(sum(r$normalized_mean))<1e-7,
 all_city_restaurants_retained=nrow(primary)==nrow(b),
 top15_in_city=all(top$business_id %in% b$business_id),
 area_minimum_met=best$eligible_restaurants>=10)
write_table(data.frame(check=names(checks),passed=unname(checks)),"final_validation.csv")
stopifnot(all(checks))
print(top[,c("rank","business_name","ward","mean_review_stars","adjusted_mean","eligible_reviewers")])
print(metrics)
