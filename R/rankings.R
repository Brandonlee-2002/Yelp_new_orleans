# Final reviewer-adjusted analysis and sensitivity suite.
source("R/config.R")
source("R/clean.R")
source("R/rank_functions.R")
library(ggplot2)
library(sf)
library(ggrepel)
set.seed(analysis_seed)
dir.create("data/analysis",recursive=TRUE,showWarnings=FALSE)
write_table <- function(x,name) write.csv(x,file.path("data/analysis",name),row.names=FALSE,na="")

b <- readRDS("data/new_orleans/business_cooking_in_city.rds")
raw_reviews <- readRDS("data/new_orleans/reviews_cooking_in_city.rds")
pair_key <- paste(raw_reviews$user_id,raw_reviews$business_id,sep="\r")
duplicate_pairs <- raw_reviews[duplicated(pair_key)|duplicated(pair_key,fromLast=TRUE),c("review_id","user_id","business_id","stars","date")]
write.csv(duplicate_pairs,"data/analysis/duplicate_user_business_pairs.csv",row.names=FALSE,na="")
r <- prepare_reviews(raw_reviews)
base <- read.csv("data/analysis/restaurant_summary.csv",stringsAsFactors=FALSE)
base <- base[match(b$business_id,base$business_id),]
stopifnot(!anyNA(match(b$business_id,base$business_id)))
g <- read.csv("data/analysis/cooking_geographic_assignments.csv",stringsAsFactors=FALSE,colClasses=c(zcta="character"),na.strings="")
points <- g[match(b$business_id,g$business_id),]
stopifnot(!anyNA(match(base$business_id,points$business_id)))
base$ward <- points$ward; base$zcta <- points$zcta
base$core_nola <- grepl("Cajun/Creole|Southern|Soul Food",base$matched_categories)

fit <- function(k=primary_reviewer_threshold, baseline="loo") fit_reviews(r,base,k,baseline)
primary <- fit(primary_reviewer_threshold,"loo")
legacy <- fit(primary_reviewer_threshold,"legacy")
pool <- rank_pool(primary)
legacy_pool <- rank_pool(legacy)
stopifnot(nrow(pool)>=ranking_size, all(pool$rank==seq_len(nrow(pool))), all(pool$eligible_reviews<=pool$available_reviews))

eligible_r <- r[r$user_activity>=primary_reviewer_threshold & is.finite(r$normalized_mean),]
pool$adjusted_reviews_for_bootstrap <- split(eligible_r$normalized_mean,eligible_r$business_id)[pool$business_id]
pool$raw_reviews_for_bootstrap <- split(eligible_r$stars,eligible_r$business_id)[pool$business_id]
raw_all_order <- order(-pool$mean_review_stars,-pool$available_reviews,pool$business_id)
raw_eligible_order <- order(-pool$eligible_raw_mean,-pool$eligible_reviews,pool$business_id)
pool$raw_all_rank <- match(pool$business_id,pool$business_id[raw_all_order])
pool$raw_eligible_rank <- match(pool$business_id,pool$business_id[raw_eligible_order])
pool$rank_change <- pool$raw_all_rank-pool$rank
pool$selection_effect <- pool$eligible_raw_mean-pool$mean_review_stars
pool$adjustment_effect <- pool$adjusted_mean-pool$eligible_raw_mean

grand <- mean(pool$adjusted_mean); within <- mean(pool$adjusted_sd^2); between <- max(0,var(pool$adjusted_mean)-within/mean(pool$eligible_reviews)); k_shrink <- if(between>0) within/between else 1
pool$shrunk_score <- grand + pool$eligible_reviews/(pool$eligible_reviews+k_shrink)*(pool$adjusted_mean-grand)
shrink_pool <- rank_pool(pool,score="shrunk_score"); lower_pool <- rank_pool(pool,score="ci_low")

write_table <- function(x,name) write.csv(x[!vapply(x,is.list,logical(1))],file.path("data/analysis",name),row.names=FALSE,na="")
top <- head(pool,ranking_size); top10 <- head(pool,10)
write_table(primary,"reviewer_adjusted_restaurants.csv"); write_table(pool,"eligible_restaurant_rankings.csv"); write_table(top,"top_15_restaurants.csv"); write_table(top10,"top_10_restaurants.csv")
write_table(head(pool[order(-abs(pool$rank_change)),c("business_name","raw_all_rank","rank","rank_change","mean_review_stars","eligible_raw_mean","adjusted_mean","eligible_reviewers")],10),"largest_ranking_changes.csv")
seafood_only <- pool[pool$rank<=50 & !pool$core_nola & grepl("Seafood",pool$matched_categories),]
seafood_tokens <- category_tokens(seafood_only$categories)
other_category_counts <- sort(table(unlist(lapply(seafood_tokens,function(x) setdiff(x,c("Restaurants",selected_categories))))),decreasing=TRUE)
write_table(data.frame(category=names(other_category_counts),restaurants=as.integer(other_category_counts)),"seafood_only_top50_categories.csv")

rank_metrics <- function(label,a,b2) { common<-intersect(a$business_id,b2$business_id); data.frame(scenario=label,top_15_overlap=sum(head(b2$business_id,ranking_size)%in%top$business_id),common_pool_spearman=if(length(common)>2)cor(a$rank[match(common,a$business_id)],b2$rank[match(common,b2$business_id)],method="spearman")else NA_real_) }
selection_pool <- rank_pool(pool,score="eligible_raw_mean")
all_raw_pool <- pool[order(-pool$mean_review_stars,-pool$available_reviews,pool$business_id),]; all_raw_pool$rank <- seq_len(nrow(all_raw_pool))
eligible_raw_pool <- pool[order(-pool$eligible_raw_mean,-pool$eligible_reviews,pool$business_id),]; eligible_raw_pool$rank <- seq_len(nrow(eligible_raw_pool))
scenarios <- rbind(rank_metrics("Selection: all-review raw to eligible-reviewer raw",all_raw_pool,eligible_raw_pool),rank_metrics("Adjustment: eligible-reviewer raw to adjusted",eligible_raw_pool,pool),rank_metrics("Total: all-review raw to adjusted",all_raw_pool,pool),
 data.frame(scenario="Legacy: baseline includes own review",top_15_overlap=sum(head(legacy_pool$business_id,ranking_size)%in%top$business_id),common_pool_spearman=cor(pool$rank[match(intersect(pool$business_id,legacy_pool$business_id),pool$business_id)],legacy_pool$rank[match(intersect(pool$business_id,legacy_pool$business_id),legacy_pool$business_id)],method="spearman")),
 rank_metrics("Shrinkage: empirical-Bayes adjusted score",pool,shrink_pool),rank_metrics("Lower 90% confidence bound",pool,lower_pool))
scenario_specs <- list(`Reviewers: 3+`=list(k=3,all=50,users=20,score="adjusted_mean",open=TRUE,core=FALSE),`Reviewers: 10+`=list(k=10,all=50,users=20,score="adjusted_mean",open=TRUE,core=FALSE),`All reviews: 25+`=list(k=5,all=25,users=20,score="adjusted_mean",open=TRUE,core=FALSE),`All reviews: 100+`=list(k=5,all=100,users=20,score="adjusted_mean",open=TRUE,core=FALSE),`Eligible reviewers: 10+`=list(k=5,all=50,users=10,score="adjusted_mean",open=TRUE,core=FALSE),`Eligible reviewers: 30+`=list(k=5,all=50,users=30,score="adjusted_mean",open=TRUE,core=FALSE),`Median baseline`=list(k=5,all=50,users=20,score="adjusted_mean_median_baseline",open=TRUE,core=FALSE),`Include closed restaurants`=list(k=5,all=50,users=20,score="adjusted_mean",open=FALSE,core=FALSE),`Core cuisine only (Seafood-only excluded)`=list(k=5,all=50,users=20,score="adjusted_mean",open=TRUE,core=TRUE))
for(nm in names(scenario_specs)){s<-scenario_specs[[nm]];x<-if(s$k==5)primary else fit(s$k);alt<-rank_pool(x,s$all,s$users,s$score,s$open,s$core);scenarios<-rbind(scenarios,rank_metrics(nm,pool,alt))}
write_table(scenarios,"ranking_sensitivity.csv")

boot <- bootstrap_ranks(pool,B=bootstrap_replicates,seed=analysis_seed); pool <- merge(pool,boot,by="business_id",sort=FALSE); pool <- pool[order(pool$rank),]; pool$overlaps_rank16_20 <- pool$rank<=ranking_size & pool$rank_p95>=16; top <- head(pool,ranking_size); top10 <- head(pool,10)
write_table(pool,"eligible_restaurant_rankings.csv"); write_table(top,"top_15_restaurants.csv"); write_table(top[,c("business_id","business_name","rank","rank_p05","rank_median","rank_p95","prob_top15","overlaps_rank16_20")],"rank_uncertainty.csv")
reliability <- split_half_reliability(pool,B=split_half_replicates,seed=analysis_seed)
write_table(reliability,"split_half_reliability.csv")

area_scores <- function(system,field,rank_data=pool){areas<-read.csv(paste0("data/analysis/",tolower(system),"_area_summary.csv"),colClasses=c(area="character"));do.call(rbind,lapply(areas$area,function(area){x<-rank_data[!is.na(rank_data[[field]])&rank_data[[field]]==area,,drop=FALSE];n<-nrow(x);data.frame(system=system,area=area,eligible_restaurants=n,all_city_restaurants=areas$restaurants[match(area,areas$area)],mean_adjusted=if(n)mean(x$adjusted_mean)else NA,mean_raw=if(n)mean(x$mean_review_stars)else NA,mean_eligible_raw=if(n)mean(x$eligible_raw_mean)else NA,total_reviews=sum(x$available_reviews),eligible_reviews=sum(x$eligible_reviews),top_15=sum(top$business_id%in%x$business_id),rankable=n>=primary_area_restaurants)}))}
ward<-area_scores("Ward","ward");zcta<-area_scores("ZCTA","zcta");write_table(rbind(ward,zcta),"adjusted_area_summary.csv");ward_candidates<-ward[ward$rankable,];ward_candidates<-ward_candidates[order(-ward_candidates$mean_adjusted,-ward_candidates$eligible_restaurants,ward_candidates$area),];best<-ward_candidates[1,];write_table(ward_candidates,"recommended_ward_comparison.csv")
area_sensitivity <- data.frame(scenario="Primary",best_ward=best$area,mean_score=best$mean_adjusted,rankable_wards=nrow(ward_candidates),stringsAsFactors=FALSE)
for(nm in names(scenario_specs)) { s<-scenario_specs[[nm]]; x<-if(s$k==5)primary else fit(s$k); alt<-rank_pool(x,s$all,s$users,s$score,s$open,s$core); areas<-split(alt[!is.na(alt$ward),],alt$ward[!is.na(alt$ward)]); areas<-areas[vapply(areas,nrow,integer(1))>=primary_area_restaurants]; if(length(areas)){scores<-vapply(areas,function(v)mean(v[[s$score]]),numeric(1));winner<-names(which.max(scores));area_sensitivity<-rbind(area_sensitivity,data.frame(scenario=nm,best_ward=winner,mean_score=scores[winner],rankable_wards=length(scores)))}}
for(minimum_area in alternate_area_minima){candidates<-ward[ward$eligible_restaurants>=minimum_area,];candidates<-candidates[order(-candidates$mean_adjusted,-candidates$eligible_restaurants,candidates$area),];area_sensitivity<-rbind(area_sensitivity,data.frame(scenario=paste0("Area minimum: ",minimum_area,"+"),best_ward=candidates$area[1],mean_score=candidates$mean_adjusted[1],rankable_wards=nrow(candidates)))}
write_table(area_sensitivity,"area_recommendation_sensitivity.csv")

set.seed(analysis_seed);ward_boot<-do.call(rbind,lapply(split(pool,pool$ward),function(x){if(!nrow(x))return(NULL);v<-replicate(bootstrap_replicates,mean(sample(x$adjusted_mean,nrow(x),replace=TRUE)));data.frame(ward=x$ward[1],eligible_restaurants=nrow(x),mean_adjusted=mean(x$adjusted_mean),ci_low=quantile(v,.05),ci_high=quantile(v,.95))}))
set.seed(analysis_seed);obs<-best$mean_adjusted;perm_max<-numeric(ward_permutation_replicates);labels<-pool$ward
for(i in seq_len(ward_permutation_replicates)){shuffled<-sample(labels);means<-tapply(pool$adjusted_mean,shuffled,mean);counts<-table(shuffled);perm_max[i]<-max(means[as.character(names(counts)[counts>=primary_area_restaurants])],na.rm=TRUE)}
p_value<-mean(perm_max>=obs);ward_significance<-merge(ward_boot,data.frame(permutation_observed_max=obs,permutation_p_value=p_value));ward_significance$framing<-if(p_value>.05)"highest mean, not statistically distinguished"else"highest mean among rankable wards";write_table(ward_significance,"ward_significance.csv")

if(requireNamespace("lme4",quietly=TRUE)){mm<-lme4::lmer(stars~1+(1|user_id)+(1|business_id),data=eligible_r,REML=TRUE);re<-ranef(mm)$business_id;re$business_id<-rownames(re);names(re)[1]<-"mixed_model_score";mm_pool<-merge(pool,re,by="business_id");mm_pool<-mm_pool[order(-mm_pool$mixed_model_score),];mm_out<-data.frame(status="fit",top_15_overlap=sum(head(mm_pool$business_id,15)%in%top$business_id),spearman=cor(pool$rank[match(mm_pool$business_id,pool$business_id)],seq_len(nrow(mm_pool)),method="spearman"))}else mm_out<-data.frame(status="skipped: lme4 is not installed",top_15_overlap=NA,spearman=NA)
write_table(mm_out,"mixed_model_crosscheck.csv")

style<-theme_minimal(base_size=12)+theme(plot.title=element_text(face="bold"),panel.grid.minor=element_blank(),plot.caption=element_text(hjust=0));p<-ggplot(pool,aes(x=mean_review_stars,y=adjusted_mean))+geom_hline(yintercept=0,color="grey65",linetype="dashed")+geom_point(aes(size=eligible_reviewers),alpha=.4,color="#176b75")+geom_point(data=top,color="#b56a26",size=2.5)+geom_text_repel(data=top,aes(label=rank),seed=42,size=3,max.overlaps=Inf)+labs(title="Reviewer selection and leave-one-out adjustment",x="All-review mean stars",y="Leave-one-out adjusted score",size="Eligible reviewers")+style;ggsave("figures/final_raw_vs_adjusted.png",p,width=10,height=6,dpi=180,bg="white")
p<-ggplot(ward[ward$eligible_restaurants>0,],aes(x=reorder(area,mean_adjusted),y=mean_adjusted))+geom_hline(yintercept=0,color="grey65")+geom_point(aes(color=rankable),size=3)+coord_flip()+labs(title="Highest mean adjusted score among rankable wards",x=NULL,y="Mean adjusted score")+style;ggsave("figures/final_ward_scores.png",p,width=10,height=7,dpi=180,bg="white")

metrics<-list(city_restaurants=nrow(b),city_reviews=nrow(r),city_reviewers=length(unique(r$user_id)),eligible_reviewers=length(unique(r$user_id[r$user_activity>=primary_reviewer_threshold])),eligible_reviews=sum(r$user_activity>=primary_reviewer_threshold),eligible_restaurants=nrow(pool),best_restaurant=top$business_name[1],highest_mean_ward=best$area,highest_mean_ward_score=best$mean_adjusted,highest_mean_ward_restaurants=best$eligible_restaurants,primary_permutation_p=p_value,bootstrap_replicates=bootstrap_replicates,split_half_adjusted=reliability$mean[reliability$metric=="adjusted"],split_half_raw=reliability$mean[reliability$metric=="raw"],lme4_crosscheck=mm_out$status,current_operating_status_verified=FALSE);jsonlite::write_json(metrics,"data/analysis/final_metrics.json",auto_unbox=TRUE,pretty=TRUE)
checks<-c(top15_unique=nrow(top)==ranking_size&&!anyDuplicated(top$business_id),minimum_reviews=all(top$available_reviews>=primary_restaurant_reviews),minimum_reviewers=all(top$eligible_reviewers>=primary_restaurant_reviewers),ranks_contiguous=all(pool$rank==seq_len(nrow(pool))),duplicate_user_business_pairs_audited=file.exists("data/analysis/duplicate_user_business_pairs.csv"),matched_businesses=!anyNA(match(b$business_id,base$business_id)),all_have_coordinates=all(is.finite(top$latitude)&is.finite(top$longitude)),area_minimum_met=best$eligible_restaurants>=primary_area_restaurants);write_table(data.frame(check=names(checks),passed=unname(checks)),"final_validation.csv");stopifnot(all(checks));print(top[,c("rank","business_name","ward","adjusted_mean","rank_p05","rank_p95","prob_top15")]);print(metrics)
