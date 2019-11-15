# Packages --------------------------------------------------------------------------------
require(sf)
require(dplyr)
require(raster)
require(rgdal)
require(devtools)

# Newest version of rayshader
devtools::install_github("tylermorganwall/rayshader")
library(rayshader)

# Loading custom functions
source("utils.R")
source("map-image-api.R") # from https://github.com/wcmbishop/rayshader-demo
source("image-size.R") # from https://github.com/wcmbishop/rayshader-demo

# Geodata for Swiss Municipalities (Federal Office of Statistics) -------------------------

# Download zip-Archive
if (!dir.exists("data/geodata")) {
  download.file(
    url = "https://www.bfs.admin.ch/bfsstatic/dam/assets/7566557/master", 
    destfile = "data/geodata.zip",
    mode = "wb"
    )
  
  # Unzip
  unzip("data/geodata.zip", exdir = "data/geodata")
  Sys.sleep(2)
  file.remove("data/geodata.zip")
  
}
  
# Load municipal boundaries of Switzerland 
mun_shp <- sf::st_read("data/geodata/ggg_2019-LV95/shp/g1g19.shp")

# Choose your favorite Municipality
adelboden_shp <- mun_shp[mun_shp$GMDNAME == "Adelboden",]

# Transform to WGS84
adelboden_shp_wgs84 <- sf::st_transform(
  adelboden_shp, 
  crs = "+proj=longlat +datum=WGS84 +no_defs"
  )

# Elevation Data: SRTM 90m ----------------------------------------------------------------

# Visit https://dwtkns.com/srtm/ for tile selection
# No login needed
if (!dir.exists("data/srtm90")) {
  download.file(
    url = "http://srtm.csi.cgiar.org/wp-content/uploads/files/srtm_5x5/TIFF/srtm_38_03.zip", 
    destfile = "data/srtm90.zip",
    mode = "wb"
  )
  
  # Unzip
  unzip("data/srtm90.zip", exdir = "data/srtm90")
  Sys.sleep(2)
  file.remove("data/srtm90.zip")
  
}

# Load GeoTIFF
srtm90 <- raster::raster("data/srtm90/srtm_38_03.tif")

# Crop raster
adelboden90 <- srtm90 %>% 
  raster::crop(adelboden_shp_wgs84)

# Dim
dim(adelboden90)

# Elevation Data: SRTM 30m -----------------------------------------------------------------

# Visit https://dwtkns.com/srtm30m/ for tile selection
# Earthdata Login needed

# Load hgt-file
srtm30 <- raster::raster("data/N46E007.hgt")

# Crop raster
adelboden30 <- srtm30 %>% 
  raster::crop(adelboden_shp_wgs84)

# Dim
dim(adelboden30)

# Elevation Data: Google Elevation API ----------------------------------------------------

# API key needed (https://developers.google.com/maps/documentation/elevation/start)
# 1000 requets = 5$

# Get 10m raster coordinates for Adelboden
adelboden_rc <- get_raster_coords(adelboden_shp, edge.length = 10)

# approx. 5000 requests = 25$
adelboden_rc$elevation <- get_elevation(
  lat = adelbodenn_rc$lat, 
  lon = adelbodenn_rc$lon, 
  "your_api_key"
  ) 

# Load data
adelboden_rc <- readRDS("data/adelboden_rc.rds")

# Rasterize
adelboden10_lv95 <- adelboden_rc %>%
  dplyr::select(lon_n, lat_n, elevation) %>% 
  raster::rasterFromXYZ()

# Define crs
crs(adelboden10_lv95) <- crs(adelboden_shp)

# Transform and crop
adelboden10 <- raster::projectRaster(
  from = adelboden10_lv95, 
  crs = "+proj=longlat +datum=WGS84 +no_defs"
  ) %>% 
  raster::crop(adelboden_shp_wgs84)

# Dim
dim(adelboden10)

# Rayshader Basics -------------------------------------------------------------------------

# Folder for snapshots
if (!dir.exists("snapshots")) dir.create("snapshots")

# Adelboden 90m
adelboden90_em <- rayshader::raster_to_matrix(adelboden90)

adelboden90_em %>%
  sphere_shade(texture = "desert") %>%
  plot_map()

adelboden90_em %>%
  sphere_shade(texture = "desert") %>%
  plot_3d(
    adelboden90_em, 
    zscale = 30, 
    fov = 30, 
    theta = -200,
    phi = 15, 
    windowsize = c(2000, 1600), 
    zoom = 0.6, 
    solid = F
    )

Sys.sleep(0.2)
render_snapshot("snapshots/adelboden90.png", clear=TRUE)

# Adelboden 30m
adelboden30_em <- rayshader::raster_to_matrix(adelboden30)

adelboden30_em %>%
  sphere_shade(texture = "desert") %>%
  plot_map()

adelboden30_em %>%
  sphere_shade(texture = "desert") %>%
  plot_3d(
    adelboden30_em, 
    zscale = 11, 
    fov = 30, 
    theta = -200,
    phi = 15, 
    windowsize = c(2000, 1600), 
    zoom = 0.6, 
    solid = F
    )

Sys.sleep(0.2)
render_snapshot("snapshots/adelboden30.png", clear=TRUE)

# Adelboden 10m
adelboden10_em <- rayshader::raster_to_matrix(adelboden10)

adelboden10_em %>%
  sphere_shade(texture = "desert") %>%
  plot_map()

adelboden10_em %>%
  sphere_shade(texture = "desert") %>%
  plot_3d(
    adelboden10_em, 
    zscale = 6, 
    fov = 30, 
    theta = -200,
    phi = 15, 
    windowsize = c(2000, 1600), 
    zoom = 0.5, 
    solid = F
    )

Sys.sleep(0.2)
render_snapshot("snapshots/adelboden10.png", clear=TRUE)

# Overlay Image I: ArcGIS REST API (Export Web Map) --------------------------------------
# Idea and function from https://github.com/wcmbishop/rayshader-demo

# Define map_box, file and image size
map_box <- list(
  p1 = list(long = bbox(adelboden10_lv95)[1], lat = bbox(adelboden10_lv95)[2]),
  p2 = list(long = bbox(adelboden10_lv95)[3], lat = bbox(adelboden10_lv95)[4])
  )

file <- "data/overlay/adelboden_arcgis.png"

image_size <- define_image_size(
  bbox = map_box, 
  major_dim = max(ncol(adelboden10_lv95), nrow(adelboden10_lv95))
)

# Download image 
get_arcgis_map_image(
  bbox = map_box, 
  file = file,
  map_type = "World_Imagery",
  width = 3 * image_size$width, 
  height = 3 * image_size$height, 
  sr_bbox = 2056 # https://spatialreference.org/ref/epsg/ch1903-lv95/
  )

# Load image
adelboden_img_arcgis <- png::readPNG(file)

# Overlay Image II: Printscreen with Georeference ---------------------------------------

# Load as stack to keep RGB colors
adelboden_img_geoadmin <- raster::stack("data/overlay/adelboden_geoadmin.tif")

# Define crs
crs(adelboden_img_geoadmin) <- "+proj=longlat +datum=WGS84 +no_defs"

# Define extent
extent(adelboden_img_geoadmin) <- matrix(
  c(7.464626745, 7.634311179, 46.411532174, 46.546230251), 
  nrow = 2, 
  byrow = T
  )

# Crop image
adelboden_img_geoadmin <- adelboden_img_geoadmin %>% 
  raster::crop(adelboden10)

# Back to image array
adelboden_img_geoadmin <- array(
  data = c(
    matrix(
      adelboden_img_geoadmin@data@values[,1] / 255, 
      ncol = ncol(adelboden_img_geoadmin), 
      nrow = nrow(adelboden_img_geoadmin), 
      byrow = T
      ), 
    matrix(
      adelboden_img_geoadmin@data@values[,2] / 255, 
      ncol = ncol(adelboden_img_geoadmin), 
      nrow = nrow(adelboden_img_geoadmin), 
      byrow = T
      ),
    matrix(
      adelboden_img_geoadmin@data@values[,3] / 255, 
      ncol = ncol(adelboden_img_geoadmin), 
      nrow = nrow(adelboden_img_geoadmin), 
      byrow = T
      )
    ),
  dim = c(
    nrow(adelboden_img_geoadmin), 
    ncol(adelboden_img_geoadmin), 
    ncol(adelboden_img_geoadmin@data@values)
    )
  )

# Rayshader with Overlay ----------------------------------------

# SRTM 30m + ArcGIS
adelboden30_em %>% 
  sphere_shade(texture = "desert") %>% 
  add_overlay(adelboden_img_arcgis, alphalayer = 0.99) %>%
  plot_3d(
    adelboden30_em, 
    zscale = 10, 
    fov = 30, 
    theta = -200,
    phi = 15, 
    windowsize = c(2000, 1600), 
    zoom = 0.6, 
    solid = F
  )

Sys.sleep(0.2)
render_snapshot("snapshots/adelboden30_ol.png", clear=TRUE)

# Google Elevation 10m + geo.admin.ch
adelboden10_em %>% 
  sphere_shade(texture = "desert") %>% 
  add_overlay(adelboden_img_geoadmin, alphalayer = 0.99) %>%
  plot_3d(
    adelboden10_em, 
    zscale = 6, 
    fov = 30, 
    theta = -200, 
    phi = 15, 
    windowsize = c(2000, 1600), 
    zoom = 0.5, 
    solid = F
  )

Sys.sleep(1)
render_snapshot("snapshots/adelboden10_ol.png", clear=TRUE)

# Labels and Video ------------------------------------------------------------------------

# Plot
adelboden10_em %>% 
  sphere_shade(texture = "desert") %>% 
  add_overlay(adelboden_img_geoadmin, alphalayer = 0.99) %>%
  plot_3d(
    adelboden10_em, 
    zscale = 6, 
    fov = 30, 
    theta = -200, 
    phi = 15, 
    windowsize = c(2000, 1600), 
    zoom = 0.5, 
    solid = F
  )

# Define Labels
labs <- data.frame(
  text = c("Adelboden", "Hahnenmoospass", "Engstligenalp"),
  x = c(537, 56, 580),
  y = c(385, 821, 885),
  z = c(4500, 3750, 3900),
  textsize = c(4, 2, 2)
)

# Add labels
ray_labeler(
  data = labs,
  heightmap = adelboden10_em,
  zscale = 6,
  linewidth = 2,
  linecolor = "grey80", 
  freetype = T
  )

# Render video
render_movie("snapshots/adelboden2019.mp4")