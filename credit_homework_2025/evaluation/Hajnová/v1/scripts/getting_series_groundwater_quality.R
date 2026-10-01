xfun::pkg_attach2("tidyverse",
                  "rvest",
                  "arrow")

url <- "https://opendata.chmi.cz/hydrology/groundwater_quality/data/"

files <- read_html(url) |> 
  html_elements("a") |> 
  html_text() |> 
  str_subset("\\.json$")

tab <- tibble(files = files,
              url = url) |> 
  mutate(files2 = str_c(url, files))

mirai::daemons(0)

mirai::daemons(3)

mirai::require_daemons()

tictoc::tic(); walk(tab$files2,
                     in_parallel(\(i, j) {
                       xfun::pkg_attach("tidyverse",
                                        "arrow")
                       snip <- jsonlite::fromJSON(i)
                       tibble(obj_id = snip$objID,
                              dt = snip$sampleList$dt,
                              header = snip$sampleList$data$header,
                              values = snip$sampleList$data$values) |> 
                         mutate(values = map(values, as.data.frame),
                                values = map2(values,
                                              header,
                                              \(x, y) set_names(x, y |> 
                                                                  str_split_1(","))),
                                values = map(values, as_tibble)) |> 
                         select(-header) |> 
                         mutate(dt = ymd_hms(dt)) |> 
                         unnest(values) |> 
                         janitor::clean_names() |> 
                         mutate(value = as.numeric(value),
                                unit_id = str_squish(unit_id),
                                unit_id = if_else(unit_id == "", NA, unit_id)) |> 
                         filter(!is.na(value)) |> 
                         write_dataset(str_glue("credit_homework/evaluation/Hajnová/v1/results/{str_split_i(basename(i), '[.]', 1)}"))
                     })); tictoc::toc(); beepr::beep(3)

parq <- open_dataset("credit_homework/evaluation/Hajnová/v1/results")

parq |> 
  mutate(year = year(dt)) |> 
  group_by(year) |> 
  write_dataset("credit_homework/evaluation/Hajnová/v1/results2/series_groundwater_quality_pq_ptn")
