library(sf) # for spatial data handling
library(dplyr) # for general data frame processing
library(leaflet) # to show data interactively
library(hereR) # interface to routing engine
library(TSP) # to solve TSP

# 14 krajských statistických úřadů (respektive 13 :)
stataky <- readr::read_csv2("./data/krajske-spravy-czso.csv") %>% 
   tidygeocoder::geocode(address = adresa, method = "google") %>% 
   sf::st_as_sf(coords = c("long", "lat"), crs = 4326)
   
# show results
leaflet(stataky) %>% 
  addProviderTiles("CartoDB.Positron") %>% 
  addCircleMarkers(fillColor = "red",
                   radius = 5,
                   stroke = F,
                   fillOpacity = .75,
                   label = ~ nazev)

# a sample of locations to make the matrix fit a page
vzorek <- stataky %>% 
  slice_sample(n = 5)

# a fancy icon for nicer display
stats_icon <- makeAwesomeIcon(
  icon = "calculator",
  iconColor = "black",
  markerColor = "blue",
  library = "fa"
)

# a quick overview of our selection
leaflet(vzorek) %>% 
  addProviderTiles("CartoDB.Positron") %>% 
  addAwesomeMarkers(data = vzorek,
                    icon = stats_icon, # the awesome icon declared earlier
                    label = ~nazev)

# distance matrix "as the crow flies"
crow_matrix <- st_distance(vzorek,
                           vzorek)

# naming the dimensions for easier orientation
rownames(crow_matrix) <- vzorek$mesto
colnames(crow_matrix) <- vzorek$mesto

# a visual check; note that the matrix has a {units} dimension
crow_matrix


# solve the TSP via {TSP}
crow_tsp <- crow_matrix %>% 
  units::drop_units() %>%  # get rid of unit dimension
  # declaring the problem as a symmetric TSP
  TSP() %>%
  solve_TSP()

# the tour (crawl) as sequence of locations
vzorek$mesto[as.numeric(crow_tsp)]


stops <- as.numeric(crow_tsp) # sequence of "cities" as indices

# locations in sequence, with the first repeated in last place
crow_result <- vzorek[c(stops, stops[1]), ] %>%
  st_combine() %>% # combined to a single object
  st_cast("LINESTRING") # & presented as a route (a line)

# present the as-the-crow-flies based route in crimson color
leaflet(crow_result) %>% 
  addProviderTiles("CartoDB.Positron") %>% 
  addPolylines(color = "crimson",
               popup = "as the crow flies...") %>% 
  addAwesomeMarkers(data = vzorek,
                    icon = stats_icon, # the awesome icon declared earlier
                    label = ~mesto)


# set the HERE API key; mine is stored in an envir variable
hereR::set_key(Sys.getenv("HERE_API_KEY"))

# a full set of all combinations - 5 × 5 = 25 rows
indices <- expand.grid(from = seq_along(vzorek$mesto), 
                       to = seq_along(vzorek$mesto))

tictoc::tic()

# call routing API for all permutations & store for future use
for (i in seq_along(indices$from)) {
  
  active_route <- hereR::route(origin = vzorek[indices$from[i], ],
                               destination = vzorek[indices$to[i], ],
                               transport_mode = "car") %>% 
    # technical columns for easier use and presentation
    mutate(idx_origin = indices$from[i],
           idx_destination = indices$to[i],
           route_name = paste(vzorek$mesto[indices$from[i]],
                        ">>",
                        vzorek$mesto[indices$to[i]])) %>% 
    relocate(idx_origin, idx_destination, route_name) %>% 
    st_zm() # drop z dimension, as it messes up with leaflet viz
  
  if (i == 1) {
    # if processing the first sample = initiate a result set
    routes <- active_route 
  } else {
    # not processing the first sample = bind to the existing result set
    routes <- routes %>% 
      bind_rows(active_route)
  }
  
}

tictoc::toc()

# a quick overview of structure of the routes data frame
glimpse(routes)

# distance matrix based on actual distances
distance_matrix <- matrix(routes$distance,
                          nrow = nrow(vzorek),
                          ncol = nrow(vzorek))

# naming the dimensions for easier orientation
rownames(distance_matrix) <- vzorek$mesto
colnames(distance_matrix) <- vzorek$mesto

# a visual check; the units are meters (distance)
distance_matrix

# solve the TSP via {TSP}
distance_tsp <- distance_matrix %>% 
  # declaring the problem as asymmetric TSP
  ATSP() %>%
  solve_TSP()

# the tour (crawl) as sequence of locations
vzorek$mesto[as.numeric(distance_tsp)]

stops <- as.numeric(distance_tsp) # sequence of "cities" as indices

# a route as a set of origin & destination pairs, as indexes,
# destination is offset by one from start (last destination = first start)
distance_route <- data.frame(idx_origin = stops,
                             idx_destination = c(stops[2:(nrow(vzorek))],
                                                 stops[1]))

# amend the origin & destination indexes by actual routes
distance_result <-  distance_route %>% 
  inner_join(routes,
             by = c("idx_origin", "idx_destination")) %>% 
  st_as_sf() 

# present the distance based route in goldenrod color
leaflet(distance_result) %>% 
  addProviderTiles("CartoDB.Positron") %>% 
  addPolylines(color = "GoldenRod",
               popup = ~route_name) %>% 
  addAwesomeMarkers(data = vzorek,
                    icon = stats_icon, # the awesome icon declared earlier
                    label = ~mesto)

# distance matrix based on travel time
duration_matrix <- matrix(routes$duration,
                          nrow = nrow(vzorek),
                          ncol = nrow(vzorek))

# names make the distance matrix easier to interpret
rownames(duration_matrix) <- vzorek$mesto
colnames(duration_matrix) <- vzorek$mesto

# a visual check; the units are seconds (time)
duration_matrix

# solving using the same pattern as distance based TSP
duration_tsp <- duration_matrix %>% 
  ATSP() %>% 
  solve_TSP() 

# the tour (crawl) as sequence of locations
vzorek$mesto[as.numeric(duration_tsp)]

# the same steps as for distance based matrix
stops <- as.numeric(duration_tsp)

duration_route <- data.frame(idx_origin = stops,
                             idx_destination = c(stops[2:(nrow(vzorek))],
                                                 stops[1]))
# again, the same as for distance based calculation
duration_result <-  duration_route %>% 
  inner_join(routes,
             by = c("idx_origin", "idx_destination")) %>% 
  st_as_sf() 

# present the duration based route in light blue color
leaflet(duration_result) %>% 
  addProviderTiles("CartoDB.Positron") %>% 
  addPolylines(color = "cornflowerblue",
               popup = ~route_name) %>% 
  addAwesomeMarkers(data = vzorek,
                    icon = stats_icon,
                    label = ~ mesto)
