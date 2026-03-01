# ogeokódovat a zakreslit na mapě lokalitu členské schůze 2026
library(sf)
library(dplyr)
library(ggplot2)

# konkrétní data - schůze 2026 geokódovaná
statspol26 <- tidygeocoder::geo("Na padesátém 81, Praha 10",
                            method = "google") %>% 
   sf::st_as_sf(coords = c("long", "lat"), crs = 4326)

# obecná data - hranice ČR jako celku, low resolution pro zjednodušení
hranice <- RCzechia::republika(resolution = "low")

# rychlý náhled interaktivní
mapview::mapview(statspol26)

# statická mapa - schůze 2026 v kontextu ČR jako celku
ggplot() +
   geom_sf(data = hranice, fill = NA, size = 1) +
   geom_sf(data = statspol26, pch = 4, color = "red", stroke = 2) +
   geom_sf_text(data = statspol26, label = "Členská schůze 2026", hjust = -.10) +
   theme_void() 

# alternativní pohled - schůze 2026 v kontextu Hlavního města Prahy
ggplot() +
   geom_sf(data = RCzechia::reky("Praha"), color = "steelblue", size = 1) +
   geom_sf(data = subset(RCzechia::kraje(), KOD_CZNUTS3 == "CZ010"), fill = NA, size = 1) +
   geom_sf(data = statspol26, pch = 4, color = "red", stroke = 2) +
   geom_sf_text(data = statspol26, label = "Členská schůze 2026", hjust = -.10) +
   theme_void() 