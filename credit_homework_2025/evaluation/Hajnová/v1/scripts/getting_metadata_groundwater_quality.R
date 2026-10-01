xfun::pkg_attach2("tidyverse",
                  "arrow")

url1 <- "https://opendata.chmi.cz/hydrology/groundwater_quality/metadata/meta1.json"

meta1 <- jsonlite::fromJSON(url1)

meta1 <- meta1$data$data$values |> 
  as.data.frame() |> 
  set_names(meta1$data$data$header |> 
              str_split_1(",")) |> 
  as_tibble() |> 
  janitor::clean_names() |> 
  mutate(across(geogr1:altitude, as.numeric))

write_dataset(meta1,
              "c:\\Users\\ledvinka\\Documents\\RProjects\\RveFG\\credit_homework\\evaluation\\Hajnová\\v1\\results2\\geog_groundwater_quality_pq")

url2 <- "https://opendata.chmi.cz/hydrology/groundwater_quality/metadata/meta2.json"

meta2 <- jsonlite::fromJSON(url2)

meta2 <- meta2$data$data$values |> 
  as.data.frame() |> 
  set_names(meta2$data$data$header |> 
              str_split_1(",")) |> 
  as_tibble() |> 
  janitor::clean_names() |> 
  mutate(across(unit_id:unit_ds,
                \(x) if_else(x == "", NA, x)))

write_dataset(meta2,
              "c:\\Users\\ledvinka\\Documents\\RProjects\\RveFG\\credit_homework\\evaluation\\Hajnová\\v1\\results2\\metaindication_groundwater_quality_pq")
