# Pure ranking/statistical functions. File I/O and plots stay in rankings.R.
loo_median <- function(values) {
  if (length(values) <= 1L) return(rep(NA_real_, length(values)))
  vapply(seq_along(values), function(i) median(values[-i]), numeric(1))
}

prepare_reviews <- function(reviews) {
  pair_key <- paste(reviews$user_id, reviews$business_id, sep="\r")
  groups <- split(seq_len(nrow(reviews)), reviews$user_id)
  user_n <- vapply(groups, length, integer(1))
  user_sum <- vapply(groups, function(ix) sum(reviews$stars[ix]), numeric(1))
  ix <- match(reviews$user_id, names(groups))
  reviews$user_activity <- user_n[ix]
  reviews$baseline_mean_legacy <- user_sum[ix] / user_n[ix]
  reviews$baseline_mean_loo <- ifelse(user_n[ix] > 1, (user_sum[ix] - reviews$stars) / (user_n[ix] - 1), NA_real_)
  medians <- lapply(groups, function(g) loo_median(reviews$stars[g]))
  reviews$baseline_median_loo <- unlist(medians, use.names=FALSE)[order(unlist(groups, use.names=FALSE))]
  # The preceding order is robust to split()'s alphabetical group names.
  median_by_row <- numeric(nrow(reviews))
  for (g in seq_along(groups)) median_by_row[groups[[g]]] <- medians[[g]]
  reviews$baseline_median_loo <- median_by_row
  reviews$normalized_mean_legacy <- reviews$stars - reviews$baseline_mean_legacy
  reviews$normalized_mean <- reviews$stars - reviews$baseline_mean_loo
  reviews$normalized_median <- reviews$stars - reviews$baseline_median_loo
  reviews
}

fit_reviews <- function(reviews, base, reviewer_threshold=primary_reviewer_threshold,
                        baseline="loo") {
  eligible <- reviews[reviews$user_activity >= reviewer_threshold & is.finite(reviews$normalized_mean),,drop=FALSE]
  score_col <- if (baseline == "legacy") "normalized_mean_legacy" else "normalized_mean"
  groups <- split(seq_len(nrow(eligible)), eligible$business_id)
  rows <- lapply(names(groups), function(id) {
    x <- eligible[groups[[id]],,drop=FALSE]
    score <- x[[score_col]]
    data.frame(business_id=id, eligible_reviews=nrow(x), eligible_reviewers=length(unique(x$user_id)),
      eligible_raw_mean=mean(x$stars), adjusted_mean=mean(score), adjusted_sd=if(length(score)>1) sd(score) else 0,
      adjusted_se=if(length(score)>1) sd(score)/sqrt(length(score)) else 0,
      ci_low=mean(score)-qnorm(.95)*if(length(score)>1) sd(score)/sqrt(length(score)) else 0,
      ci_high=mean(score)+qnorm(.95)*if(length(score)>1) sd(score)/sqrt(length(score)) else 0,
      adjusted_mean_median_baseline=mean(x$normalized_median), stringsAsFactors=FALSE)
  })
  scores <- if(length(rows)) do.call(rbind, rows) else data.frame(business_id=character())
  out <- merge(base, scores, by="business_id", all.x=TRUE, sort=FALSE)
  for (n in c("eligible_reviews","eligible_reviewers","adjusted_sd","adjusted_se","ci_low","ci_high","adjusted_mean_median_baseline")) out[[n]][is.na(out[[n]])] <- 0
  out
}

rank_pool <- function(x, minimum_all=primary_restaurant_reviews, minimum_users=primary_restaurant_reviewers,
                      score="adjusted_mean", require_open=TRUE, core_only=FALSE) {
  keep <- x$available_reviews >= minimum_all & x$eligible_reviewers >= minimum_users & is.finite(x[[score]])
  if (require_open) keep <- keep & x$is_open == 1
  if (core_only && "core_nola" %in% names(x)) keep <- keep & x$core_nola
  out <- x[keep,,drop=FALSE]
  out <- out[order(-out[[score]], -out$mean_review_stars, -out$available_reviews, out$business_id),,drop=FALSE]
  out$rank <- seq_len(nrow(out))
  out
}

rank_metrics <- function(primary, alternative, primary_top, size=ranking_size) {
  common <- intersect(primary$business_id, alternative$business_id)
  data.frame(top_15_overlap=sum(head(alternative$business_id,size) %in% primary_top$business_id),
    common_pool_spearman=if(length(common)>2) cor(primary$rank[match(common,primary$business_id)], alternative$rank[match(common,alternative$business_id)], method="spearman") else NA_real_)
}

bootstrap_ranks <- function(pool, score_col="adjusted_mean", B=bootstrap_replicates, seed=analysis_seed) {
  set.seed(seed)
  groups <- pool$adjusted_reviews_for_bootstrap
  names(groups) <- pool$business_id
  ids <- names(groups)
  ranks <- matrix(NA_integer_, nrow=B, ncol=length(ids), dimnames=list(NULL,ids))
  for (b in seq_len(B)) {
    scores <- vapply(groups, function(x) mean(sample(x,length(x),replace=TRUE)), numeric(1))
    order_ix <- order(-scores, ids)
    ranks[b,order_ix] <- seq_along(order_ix)
  }
  data.frame(business_id=ids, rank_p05=apply(ranks,2,quantile,.05), rank_median=apply(ranks,2,median),
    rank_p95=apply(ranks,2,quantile,.95), prob_top15=colMeans(ranks <= ranking_size), stringsAsFactors=FALSE)
}

split_half_reliability <- function(pool, B=split_half_replicates, seed=analysis_seed) {
  set.seed(seed)
  adjusted_groups <- pool$adjusted_reviews_for_bootstrap
  raw_groups <- pool$raw_reviews_for_bootstrap
  raw_cor <- adjusted_cor <- numeric(B)
  for (b in seq_len(B)) {
    adjusted_first <- adjusted_second <- raw_first <- raw_second <- numeric(length(adjusted_groups))
    for (i in seq_along(adjusted_groups)) {
      x <- adjusted_groups[[i]]; raw <- raw_groups[[i]]; ix <- sample(seq_along(x)); cut <- max(1L,floor(length(x)/2)); a <- ix[seq_len(cut)]; z <- ix[(cut+1L):length(x)]
      if(!length(z)) z <- a
      adjusted_first[i] <- mean(x[a]); adjusted_second[i] <- mean(x[z])
      raw_first[i] <- mean(raw[a]); raw_second[i] <- mean(raw[z])
    }
    adjusted_cor[b] <- cor(adjusted_first,adjusted_second,method="spearman")
    raw_cor[b] <- cor(raw_first,raw_second,method="spearman")
  }
  data.frame(metric=c("raw","adjusted"), mean=c(mean(raw_cor),mean(adjusted_cor)),
    ci_low=c(unname(quantile(raw_cor,.025)),unname(quantile(adjusted_cor,.025))),
    ci_high=c(unname(quantile(raw_cor,.975)),unname(quantile(adjusted_cor,.975))))
}
