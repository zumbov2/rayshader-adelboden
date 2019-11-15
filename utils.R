# Packages
require(tibble)
require(httr)
require(jsonlite)
require(purrr)

# Get Coordinates for Raster (CH1903+ / LV95 (EPSG:2056) to WGS 84 (EPSG:4326)) 
get_raster_coords <- function(shape, edge.length = 500) {
  
  # Raster
  E_MIN <- floor(shape$E_MIN / edge.length) * edge.length
  E_MAX <- ceiling(shape$E_MAX / edge.length) * edge.length
  N_MIN <- floor(shape$N_MIN / edge.length) * edge.length
  N_MAX <- ceiling(shape$N_MAX / edge.length) * edge.length
  
  all <- expand.grid(E = seq(E_MIN, E_MAX, by = edge.length), N = seq(N_MIN, N_MAX, by = edge.length))
  
  # Calculate Coords
  y_ <- (all$E - 2600000) / 1000000
  x_ <- (all$N - 1200000) / 1000000
  
  tibble::tibble(
    lat = (16.9023892 + 3.238272 * x_ - 0.270978 * y_^2 - 0.002528 * x_^2 - 0.0447 * y_^2*x_ - 0.0140 * x_^3) * (100/36),
    lat_n = all$N,
    lon = (2.6779094 + 4.728982 * y_ + 0.791484 * y_ * x_ + 0.1306 * y_ * x_^2 - 0.0436 * y_^3) * (100/36),
    lon_n = all$E
  )
  
}

# Google Elevation API Workhorse
get_elevation_wh <- function(part, data, api.key) {
  
  # Info
  cat("Batch No.", part, "\n")
  
  # Data
  batch <- data[data$partition == part,]
  
  # URL
  url <- paste0(
    "https://maps.googleapis.com/maps/api/elevation/json?locations=", 
    paste(batch$location, collapse = "|"),
    "&key=", api.key
  )
  
  # GET
  res <- httr::GET(url)
  
  # Return
  res <- jsonlite::fromJSON(rawToChar(res$content))
  res <- c(res$results$elevation)
  
  return(res)
  
}

# High-level function for Google Elevation API
get_elevation <- function(lat, lon, api.key = "your_api_key") {
  
  # API check
  if (api.key == "your_api_key") stop("No valid API key")
  
  # Base url
  url.base <- "https://maps.googleapis.com/maps/api/elevation/json?locations="
  length.base <- nchar("https://maps.googleapis.com/maps/api/elevation/json?locations=")
  length.key <- nchar(api.key)
  
  # Locations
  partitions <- tibble::tibble(
    location = paste(lat, lon, sep =","),
    length = nchar(location)+1,
    cumlength = cumsum(length),
    partition = ceiling(cumlength / (8192 - (length.base + length.key)))
  )
  
  # Query
  res <- purrr::map(unique(partitions$partition), get_elevation_wh, data = partitions, api.key = api.key)
  return(unlist(res))
  
}

# Rayshade-Labeler
ray_label <- function(text, x, y, z, textsize, zscale, heightmap, 
                      relativez, linewidth, linecolor, 
                      freetype, ...) {
  
  rayshader::render_label(
    heightmap = heightmap,
    x = x,
    y = y,
    z = z,
    text = text,
    relativez = relativez,
    textsize = textsize,
    linewidth = linewidth,
    linecolor = linecolor,
    freetype = freetype,
    zscale = zscale,
    ...
    )
    
}

ray_labeler <- function(data, heightmap, zscale, relativez = F, linewidth = 2, 
                        linecolor = "grey80", freetype = T) {
  
  purrr::pwalk(
    list(
      text = data$text,
      x = data$x,
      y = data$y,
      z = data$z,
      textsize = data$textsize
      ),
    ray_label,
    heightmap = heightmap,
    zscale = zscale,
    relativez = relativez,
    linewidth = linewidth,
    linecolor = linecolor,
    freetype = freetype
    )
  
}
  