# Rayshading Adelboden
Here you can find some code examples of my exploration of [Tyler Morgan-Wall's](https://twitter.com/tylermorganwall) amazing [rayshader package](https://www.rayshader.com/) for R. My approach was heavily inspired by Will Bishop's blog post [I can rayshade, and so can you](https://wcmbishop.github.io/rayshader-demo/).
 
<img src="https://github.com/zumbov2/rayshader-adelboden/blob/master/snapshots/Adelboden.gif" width="500">  

## Short version of ```code_adelboden.R```
### Goal ###
Creating a 3-dimensional image of my favourite ski holiday destination [Adelboden](https://de.wikipedia.org/wiki/Adelboden).

### Approach ###
- We download the latest shapefiles of the **municipal boundaries** from the website of the Swiss [Federal Statistical Office](https://www.bfs.admin.ch/bfs/de/home/dienstleistungen/geostat/geodaten-bundesstatistik/administrative-grenzen/generalisierte-gemeindegrenzen.html).
- We access different types of **elevation data**: [SRTM 90m](https://dwtkns.com/srtm/) and [SRTM 30m](https://dwtkns.com/srtm30m/) of NASA's [Shuttle Radar Topography Mission](https://www2.jpl.nasa.gov/srtm/) and we create an even more fine-grained elevation model (10m) with Google's [Elevation API](https://developers.google.com/maps/documentation/elevation/start) (5 USD per 1000 requests, total costs of ~ 25 USD).
- We use [rayshader](https://www.rayshader.com/) for a **three-dimensional spatial visualization** of Adelboden's 88,2 km<sup>2</sup>.

<img src="https://github.com/zumbov2/rayshader-adelboden/blob/master/snapshots/comb903010.png" width="800">  

- We download a suitable **aerial image** via the [ArcGIS REST API](https://utility.arcgisonline.com/arcgis/rest/services/Utilities/PrintingTools/GPServer/Export%20Web%20Map%20Task/execute) using Will Bishop's `get_arcgis_map_image` [function](https://github.com/wcmbishop/rayshader-demo/blob/master/R/map-image-api.R).
- We printscreen an **arial image** from the map of the [Swiss Federal Geoportal](https://map.geo.admin.ch), assign it georeferences and crop it to the appropriate size.
- We **overlay** the rayshaded 3D visualizations with the aerial images.

<img src="https://github.com/zumbov2/rayshader-adelboden/blob/master/snapshots/comb3010_ol.png" width="800">  

- We add georeferenced **labels** and render a **video** of the scenery.



<img src="https://github.com/zumbov2/rayshader-adelboden/blob/master/snapshots/Adelboden.gif" width="500">  



And...it's a wrap!