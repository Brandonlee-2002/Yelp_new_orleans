# Run once from the project root. Subsequent analyses use the saved boundaries.
stopifnot(requireNamespace("tigris", quietly=TRUE), requireNamespace("sf", quietly=TRUE))
dir.create("data/boundaries", recursive=TRUE, showWarnings=FALSE)
options(tigris_use_cache=FALSE, timeout=600)
save_layer <- function(x, path) {
  sf::st_write(sf::st_transform(x, 4326), path, quiet=TRUE, delete_dsn=TRUE)
}
if (!file.exists("data/boundaries/louisiana_places_2020.geojson")) {
  save_layer(tigris::places(state="LA", year=2020, cb=FALSE, class="sf"),
    "data/boundaries/louisiana_places_2020.geojson")
}
if (!file.exists("data/boundaries/zctas_2020_prefix70.geojson")) {
  save_layer(tigris::zctas(year=2020, cb=TRUE, starts_with="70", class="sf"),
    "data/boundaries/zctas_2020_prefix70.geojson")
}
ward_url <- paste0("https://maps.nola.gov/server/rest/services/Administrative/",
  "Administrative_Layers/MapServer/3/query?where=1%3D1&outFields=*&outSR=4326&f=geojson")
if (!file.exists("data/boundaries/new_orleans_wards.geojson")) {
  download.file(ward_url, "data/boundaries/new_orleans_wards.geojson", mode="wb", quiet=TRUE)
}
if (!file.exists("data/boundaries/wards_metadata.json")) {
  download.file(paste0("https://maps.nola.gov/server/rest/services/Administrative/",
    "Administrative_Layers/MapServer/3?f=pjson"),
    "data/boundaries/wards_metadata.json", mode="wb", quiet=TRUE)
}
wards <- sf::st_read("data/boundaries/new_orleans_wards.geojson", quiet=TRUE)
stopifnot(nrow(wards)==17L, !anyDuplicated(wards$WARD))
message("Saved Census place and ZCTA boundaries and 17 official New Orleans wards.")
