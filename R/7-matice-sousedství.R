# pokračování problému "kapr" technikami prostorové statistiky

library(tidyverse) # protože dplyr, ggplot2 a spol.
library(RCzechia) # česká geodata
library(sf)

# Průměrné spotřebitelské ceny vybraných výrobků - potravinářské výrobky
kapr <- czso::czso_get_table("012052", dest_dir = "./data")  %>% 
   filter(reprcen_txt %in% c("Kapr živý [1 kg]")   # relevantní cenový reprezentant,
          & uzemi_txt != "Česká republika"         # pouze regionální hodnoty (tj. ne ČR jako celek)
          & obdobiod >= "2018-12-01" 
          & obdobido <= "2019-01-01") %>% 
   rename(cena_kapra = hodnota)

chrt_src <- RCzechia::kraje("low") %>% 
   inner_join(kapr, by = c("KOD_KRAJ" = "uzemi_kod"))

# pro připomenutí...
ggplot(data = chrt_src) +
   geom_sf(aes(fill = cena_kapra)) +
   geom_sf_label(aes(label = cena_kapra)) +
   theme_minimal() +
   theme(axis.title = element_blank()) +
   labs(title = "Cena kapra za kilo")

# je cena kapra rozmístěna náhodně?
library(spdep)

# pomocné objekty v rovinném CRS
kraje_krovak <- chrt_src %>% 
   st_geometry() %>% 
   st_transform(5514)

stredobody <- st_centroid(kraje_krovak)

# vlastní matice
matice <- kraje_krovak %>% 
   poly2nb() %>%  # z polygonů na sousedy
   nb2listw()     # ze sousedů na matici

# vizualizace matice 
plot(kraje_krovak, border = "gray25")
plot(matice, coords = stredobody,
     pch = 19, col = "red", add = T)

# vlastnosti matice
sapply(matice$weights, sum) # řádkový součet = 1
sum(sapply(matice$weights, sum)) # součet součtů = 14 (čiliže n)

# Moranův test s přijetím předpokladů™
moran.test(chrt_src$cena_kapra, matice, alternative = "two.sided")

# Moranův test technikou Monte Carlo / 9999 uvařených bramboraček ze factorial(14) teoreticky možných
bramboracka <- moran.mc(chrt_src$cena_kapra, matice, nsim = 9999, alternative = "two.sided")

bramboracka

hist(bramboracka$res)
abline(v = bramboracka$statistic, col = "red", lwd = 3)

# model - cena kapra jako fce kupní síly a vzdálenosti od Třeboně

# mediánový plat přes kraje v roce 2018
platy <- czso::czso_get_table("110080", dest_dir = "./data") %>% 
   filter(rok == 2018 & is.na(POHLAVI_kod) & SPKVANTIL_txt == "medián") %>% 
   select(uzemi_kod, median_mezd = hodnota)

# pupek rybnikářského světa
pupek <- tidygeocoder::geo("Rybník Svět, Třeboň",
                            method = "osm") %>% 
   sf::st_as_sf(coords = c("long", "lat"), crs = 4326)

model_src <- chrt_src %>% 
   inner_join(platy, by = c("KOD_KRAJ" = "uzemi_kod")) %>% 
   mutate(vzdalenost = st_distance(st_centroid(.), pupek)[,1])

# prostý model
model_kapra <- lm(data = model_src,
                  formula = cena_kapra ~ median_mezd + vzdalenost)

summary(model_kapra)

# pohled zpět
model_src$resids <- model_kapra$residuals

ggplot(data = model_src) +
   geom_sf(aes(fill = resids)) +
   geom_sf_label(aes(label = round(resids, 2))) +
   scale_fill_viridis_c() +
   theme_minimal() +
   theme(axis.title = element_blank()) +
   labs(title = "Rezidua z modelu")