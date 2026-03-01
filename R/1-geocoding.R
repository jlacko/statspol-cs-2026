# ogeokódovat a zakreslit na mapě lokalitu Robust 2026

library(sf)
library(dplyr)
library(ggplot2)

# konkrétní data - Robust 2026 geokódovaný
robust <- tidygeocoder::geo("Hotel Vydra, Srní",
                            method = "osm") %>% 
   sf::st_as_sf(coords = c("long", "lat"), crs = 4326)

# obecná data - hranice ČR jako celku, low resolution pro zjednodušení
hranice <- RCzechia::republika(resolution = "low")

# rychlý náhled interaktivní
mapview::mapview(robust)

# statická mapa - Robust v kontextu republiky jako celku
ggplot() +
   geom_sf(data = hranice, fill = NA, lwd = 2/3) +
   geom_sf(data = robust, pch = 4, color = "red", stroke = 2) +
   geom_sf_text(data = robust, label = "Robust 2026", hjust = -.15) +
   theme_void() 


# jiný pohled na statickou mapu
voda <- RCzechia::reky() %>% 
   subset(NAZEV %in% c("Vydra",
                       "Vchynicko-tetovský kanál",
#                       "Otava",
                       "Křemelná"))
          
ggplot() +
   geom_sf(data = voda,
           aes(color = NAZEV),
           lwd = 1,
           key_glyph = "path") +
   geom_sf(data = robust, pch = 4, color = "red", stroke = 2) +
   theme_void() +
   labs(title = "Lokalita Robust 2026",
        subtitle = "v kontextu místních vodních toků...",
        color = "Vodní tok:")