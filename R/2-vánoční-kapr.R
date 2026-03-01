# úkol = zakreslit kartogram [CZE] / choropleth map [ENG]
# ceny vánočního kapra v roce 2018 (poslední známý) po krajích

library(tidyverse) # protože dplyr, ggplot2 a spol.
library(RCzechia) # česká geodata
library(leaflet)  # pro fancy dynamické overview

# podkladová data - ceny potravin (spotřební koš ČSÚ) v regionech a čase
kapr <- czso::czso_get_table("012052", dest_dir = "./data") %>% 
   filter(reprcen_txt %in% c("Kapr živý [1 kg]")   # relevantní cenový reprezentant,
          & uzemi_txt != "Česká republika"         # pouze regionální hodnoty (tj. ne ČR jako celek)
          & obdobiod >= "2018-12-01" 
          & obdobido <= "2019-01-01") 

chrt_src <- RCzechia::kraje("low") %>% 
   inner_join(kapr, by = c("KOD_KRAJ" = "uzemi_kod"))

# co máme?
chrt_src

# statický obrázek basic
plot(chrt_src["hodnota"])

# statický obrázek fancy
ggplot(chrt_src) +
   geom_sf(aes(fill = hodnota)) +
   geom_sf_label(aes(label = hodnota), fill = "white") +
   scale_fill_viridis_c(labels = scales::label_number(suffix = " Kč"),) +
   theme_void() +
   labs(title = "Vánoční kapr",
        subtitle = "v posledním roce fyzického výběrového šetření (2018)",
        fill = "Cena v Kč",
        caption = "zdroj dat: ČSÚ")

# dynamincké overview basic
mapview::mapview(chrt_src, zcol = "hodnota")

# dynamické overview fancy
barvy <- colorNumeric(palette = "RdYlGn",
                      reverse = T,
                      domain = chrt_src$hodnota)

leaflet(data = chrt_src) %>% 
   addProviderTiles("CartoDB.Positron") %>%  # https://leaflet-extras.github.io/leaflet-providers/preview/
   addPolygons(fillColor = ~ barvy(hodnota),
               fillOpacity = 1/2,
               stroke = F,
               label = ~paste(hodnota, "Kč za kilo kapra"))

