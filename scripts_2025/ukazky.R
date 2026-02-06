xfun::pkg_attach2("tidyverse",
                  "arrow")

ts <- open_dataset("credit_homework/evaluation/hajnová/v1/parquet_vysledek")

ts |> 
  head(5) |> 
  collect()

ts |> 
  filter(year == 1957) |> 
  collect() |> 
  unnest(c(tscon_id, unit_id)) |> 
  mutate(unit_id = str_squish(unit_id),
         unit_id = if_else(unit_id == "", NA, unit_id))
