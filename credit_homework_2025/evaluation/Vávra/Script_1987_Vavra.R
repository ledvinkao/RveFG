# Autor: Martin Vávra
# Vybraný rok: 1987

# 1. NAČTENÍ BALÍČKŮ
# Použiji funkci, která balíčky načte a pokud chybí, tak doinstaluje
xfun::pkg_attach2("tidyverse", 
                  "arrow", 
                  "RCzechia", 
                  "sf")
# tidyverse (základní balíček), arrow (čtení parquet formátu), RCzechia (administrativní a prostorové objekty ČR), sf (pro identifikaci prostorových dat)

# 2. NAČTENÍ DAT
# Odkážu se na data a metadata ve složce a přiřadím si k nim názvy
data <- open_dataset("wq_water_data")
meta1 <- open_dataset("wq_water_metadata1")
meta2 <- open_dataset("wq_water_metadata2")

# Stáhnu si metadata k sobě a přiřadím si k tabulkám názvy
tabulka_popisy <- meta2 |> collect()
tabulka_souradnice <- meta1 |> collect()

# 3. PŘÍPRAVA HLAVNÍ TABULKY
moje_data <- data |>  # šáhnu si do dat
  filter(year == 1987) |>  # vyfitruji si rok 1987
  collect() |>  # stáhnu si data k sobě, abych měl tabulku
  left_join(tabulka_popisy, by = "tscon_id") |>  # připojím si metadata s popisy do tabulky
  filter(!is.na(tscon_ds)) |>  # vyhodím řádky kde není možné číst popis
  left_join(tabulka_souradnice, by = "obj_id")|>  # připojím si metadata se souřadnicemi do tabulky
  filter(!is.na(geogr1), !is.na(geogr2)) # vyhodím řádky kde nejsou souřadnice

# 4. PŘIŘAZENÍ PROSTOROVÝCH DAT
# Vytáhnu si z RCzechia (z chráněných území) CHKO
chko <- chr_uzemi() |> 
  filter(TYP == "CHKO") |>
  as_tibble() |>
  st_as_sf() 

# Vytvořím si vektorovou vrstvu z mých dat a stanovím si souřadnicový systém
data_s_GPS <- moje_data |> 
  st_as_sf(coords = c("geogr2", "geogr1"), crs = 4326)

# Zahodím data, které leží mimo CHKO
data_v_chko <- st_join(data_s_GPS, chko, left = FALSE)

# 5. VÝSLEDEK
# Odstraním geomrtry, ponechám si sloupce s názvem CHKO + ukazatelem a spočítám si četnost měření za rok 1987
finalni_tabulka <- data_v_chko |>
  st_drop_geometry() |> 
  count(NAZEV, tscon_ds, name = "pocet")

# Nakonec si tabulku uložím do rds formátu
saveRDS(finalni_tabulka, "Finalni_tabulka_1987.rds")


# 6. Kde se nic neměřilo? 

vsechny_chko <- chko$NAZEV  # získám si názvy všech CHKO

obsazene_chko <- unique(finalni_tabulka$NAZEV)  # získám seznam CHKO, které mám ve výsledné tabulce

chybejici_chko <- setdiff(vsechny_chko, obsazene_chko)  # vyselektuji si CHKO, které nemám ve výsledné tabulce

tabulka_chybejicich <- tibble(NAZEV = chybejici_chko)  # uložím si to jako tabulku a exportuji do rds formátu

saveRDS(tabulka_chybejicich, "chybejici_chko_1987.rds")

