library(sf)
library(dplyr)
library(giscoR)
library(ggplot2)

# celý svět...
svet <- gisco_get_countries(resolution = 1) %>% 
   rmapshaper::ms_simplify(keep = 1/100, keep_shapes = T) # zjednodušit pro zrychlení

# (dánské) Grónsko a (belgické) Kongo
glmd <- svet %>% 
   filter(CNTR_ID %in% c('GL', 'CD'))

# podíl plochy Grónska a Konga
st_area(subset(glmd, CNTR_ID == 'GL')) / st_area(subset(glmd, CNTR_ID == 'CD')) 

# web mercator = default na google maps
ggplot() +
   geom_sf(data = glmd, fill = "red", color = NA) +
   geom_sf(data = svet, fill = NA, color = "gray45") +
   coord_sf(crs = st_crs("EPSG:3857"),
            ylim = c(-20e6, 20e6))

# Mollweide - equal area
ggplot() +
   geom_sf(data = glmd, fill = "red", color = NA) +
   geom_sf(data = svet, fill = NA, color = "gray45") +
   coord_sf(crs = st_crs("ESRI:53009"))

# inž. Křovák - specializováno na Československo
ggplot() +
   geom_sf(data = glmd, fill = "red", color = NA) +
   geom_sf(data = svet, fill = NA, color = "gray45") +
   coord_sf(crs = st_crs("EPSG:5514"))

# inž. Křovák - detail Československa
ggplot() +
   geom_sf(data = filter(svet, CNTR_ID %in% c("CZ", "SK")), fill = NA, color = "gray45") +
   coord_sf(crs = st_crs("EPSG:5514"))

# Mercator - detail Československa
ggplot() +
   geom_sf(data = filter(svet, CNTR_ID %in% c("CZ", "SK")), fill = NA, color = "gray45") +
   coord_sf(crs = st_crs("EPSG:3857"))

# pro frajery za plusové body - ortho projekce / kosmonauti hledící na kouli...

# projection string used for the polygons & ocean background
crs_string <- "+proj=ortho +lon_0=13.47672 +lat_0=49.09548"

# background for the globe - center buffered by earth radius
ocean <- st_point(x = c(0,0)) %>%
  st_buffer(dist = 6371000) %>%
  st_sfc(crs = crs_string)

viditelny_svet <- svet %>% 
  st_intersection(ocean %>% st_transform(4326)) %>% # select visible area only
  st_transform(crs = crs_string) # reproject to ortho

ggplot(data = viditelny_svet) +
  geom_sf(data = ocean, fill = "deepskyblue", color = NA) + # background first
  geom_sf(data = viditelny_svet, fill = "khaki", color = "gray45") +
  geom_sf(data = glmd, fill = "red", color = "gray45") +
  coord_sf(crs = crs_string) +
  theme_void()