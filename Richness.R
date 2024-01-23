Forest_Poly |> as.data.frame()

MoreThan2 <- Forest_Poly[Forest_Poly$Ha > 2,]

MoreThan2DF <- as.data.frame(MoreThan2)
MoreThan2DF$Richness <- NA

Species <- list()

for(i in 1:nrow(MoreThan2DF)){
  try({
    WKT <- MoreThan2[i,]|>
      terra::convHull() |>
      terra::project("epsg:4326") |>
      st_as_sf() |>
      st_as_sfc() |>
      st_as_text()

    Test <- rgbif::occ_count(hasCoordinate = T,
                             geometry = WKT,
                             year = '1999,2023',
                             facet="scientificName", facetLimit=10000)

    Species[[i]] <- SDMWorkflows::Clean_Taxa(Taxons = Test$scientificName) |>
      dplyr::select(phylum, class, family, genus, species) |>
      dplyr::distinct()

    Species[[i]]$ID <- i
    MoreThan2DF[i,]$Richness <- nrow(Species[[i]])
    message(paste(i, "of", nrow(MoreThan2DF) ,"ready", Sys.time()))
    if((i %% 50) == 0){
      readr::write_csv(MoreThan2DF[1:i,], "Richness.csv")
    }

  })


}


