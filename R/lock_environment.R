# Optional maintenance command: refresh the lock and test an isolated restore.
# Install renv first. Package libraries can be supplied through YELP_PACKAGE_LIBRARY.
tools_library <- Sys.getenv('YELP_RENV_TOOLS')
extra_library <- Sys.getenv('YELP_PACKAGE_LIBRARY')
.libPaths(c(extra_library[nzchar(extra_library)],tools_library[nzchar(tools_library)],.libPaths()))
cache_root <- Sys.getenv('YELP_RENV_CACHE', tempfile('yelp-renv-cache-'));dir.create(cache_root,recursive=TRUE,showWarnings=FALSE)
Sys.setenv(RENV_PATHS_ROOT=cache_root,RENV_PATHS_CACHE=file.path(cache_root,'cache'),
 RENV_PATHS_SOURCE=file.path(cache_root,'source'))
options(repos=c(CRAN='https://cloud.r-project.org'))
stopifnot(requireNamespace('renv',quietly=TRUE))
project <- normalizePath('.')
required <- c('jsonlite','ggplot2','sf','tigris','ggrepel','renv')
installed <- installed.packages(lib.loc=.libPaths())
deps <- tools::package_dependencies(required,db=installed,which=c('Depends','Imports','LinkingTo'),recursive=TRUE)
packages <- unique(c(required,unlist(deps)))
packages <- packages[packages %in% rownames(installed)]
packages <- packages[is.na(installed[match(packages,rownames(installed)),'Priority']) |
 installed[match(packages,rownames(installed)),'Priority']!='base']
seed_project <- tempfile('yelp-seed-');dir.create(seed_project)
seed_library <- file.path(seed_project,'library');dir.create(seed_library)
renv::hydrate(packages=packages,library=seed_library,sources=.libPaths(),project=seed_project,prompt=FALSE)
stopifnot(packageVersion('Rcpp',lib.loc=seed_library)>='1.1.0')
renv::snapshot(packages=required,library=seed_library,lockfile=file.path(project,'renv.lock'),prompt=FALSE,force=FALSE)
# renv::load creates a base-only sandbox, preventing the system library from
# satisfying restore requests behind the scenes.
restore_project <- tempfile('yelp-restore-');dir.create(restore_project)
renv::init(project=restore_project,bare=TRUE,force=TRUE,restart=FALSE)
renv::load(project=restore_project)
restore_library <- renv::paths$library(project=restore_project)
renv::restore(project=restore_project,lockfile=file.path(project,'renv.lock'),prompt=FALSE)
lock <- renv::lockfile_read(file.path(project,'renv.lock'))
packages <- names(lock$Packages)
versions <- vapply(packages,function(p) as.character(packageVersion(p,lib.loc=c(restore_library,.libPaths()))),character(1))
expected <- vapply(lock$Packages,function(p) as.character(package_version(p$Version)),character(1))
stopifnot(identical(unname(versions),unname(expected)))
# R's recommended packages are supplied by the base-only sandbox.
locations <- vapply(packages,function(p) find.package(p,lib.loc=c(restore_library,.libPaths())),character(1))
priority <- vapply(packages,function(p) { v <- packageDescription(p,lib.loc=c(restore_library,.libPaths()))$Priority; if(is.null(v)) '' else v },character(1))
stopifnot(all(priority=='recommended' | startsWith(locations,restore_library)))
write.csv(data.frame(package=packages,locked_version=expected,restored_version=versions,source=ifelse(priority=="recommended","R recommended package","isolated project library"),verified=versions==expected),
 file.path(project,'data/analysis/environment_restore_check.csv'),row.names=FALSE)
setwd(project)
before <- read.csv('data/analysis/top_15_restaurants.csv')$business_id
source('R/rankings.R',local=new.env())
after <- read.csv('data/analysis/top_15_restaurants.csv')$business_id
stopifnot(identical(before,after))
writeLines(c(paste('Verified',length(packages),'locked packages in an independent renv library.'),
 'Restored environment regenerated the identical ordered top-15 business IDs.',
 paste('R version:',getRversion()),'System libraries (GDAL/GEOS/PROJ) remain platform prerequisites.'),
 'data/analysis/environment_restore_result.txt')
writeLines(sub('[[:space:]]+$','',capture.output(sessionInfo())),'data/analysis/session_info.txt')
message('Isolated lockfile restore and ranking reproduction passed.')
