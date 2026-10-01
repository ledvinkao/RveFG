# Úvod
# Nejdříve jsem si načetl rds soubor, abych zjistil jaký rok mám zpracovávat
data1 <- readRDS("C:/Users/Vojtěch Novák/Desktop/Rko2025/rozdeleni_roku_studentum.rds")

str(data1)

# načetl jsem balíčky potřebné ve skriptu
xfun::pkg_attach2("tidyverse",
                  "arrow",
                  "RCzechia")

# odkázal jsem se na data a metadata podle návodu
data <- open_dataset("C:/Users/Vojtěch Novák/Desktop/Rko2025/data/wq_water_data")

meta1 <- open_dataset("C:/Users/Vojtěch Novák/Desktop/Rko2025/metadata/wq_water_metadata1")

meta2 <- open_dataset("C:/Users/Vojtěch Novák/Desktop/Rko2025/metadata/wq_water_metadata2")

# nahraji si vrstvu CHKO z RCzechia
chko <- chr_uzemi() |> 
  filter(TYP == "CHKO") |>
  as_tibble() |>
  st_as_sf()

# stáhnul jsem si data a přejmenoval si je

souradnice <- meta1 |> collect()
popisy <- meta2 |> collect()

# 3) vyberu jen řádky, kde je možné číst popis ukazatelů (tedy nechybí hodnoty ve sloupci tscon_ds)
## vybírám prázdné hodnoty pomocí filteru s !is.na

data_1997<- data |>
  filter(year == 1997) |>
  collect() |>
  left_join(popisy, by = "tscon_id") |>
  filter(!is.na(tscon_ds)) |> 
  left_join(souradnice, by = "obj_id")|>
  filter(!is.na(geogr1) & !is.na(geogr2))


# 5) vytvoření vektorové vrstvy a přiřazení souřadnicového systému
data_se_souradnicemi <- data_1997 |> 
st_as_sf(coords = c("geogr2", "geogr1"), crs = 4326)
         
# 4 + 6) zachovám pouze data uvnitř CHKO pomocí join
data_v_chko <- st_join(data_se_souradnicemi, chko, left = FALSE)


# 7 + 8 + 9) odstraním geometrii, ponechám si sloupce s názvem CHKO a s id a spočítám četnost měření za vybraný rok
vysledna_tabulka <- data_v_chko |>
  st_drop_geometry() |> 
  count(NAZEV, tscon_id, name = "pocet")

# 10) exportuji finální tabulku do RDS souboru
write_rds(vysledna_tabulka, "C:/Users/Vojtěch Novák/Desktop/Rko2025/vystup/vysledna_tabulka_1987.rds")
         