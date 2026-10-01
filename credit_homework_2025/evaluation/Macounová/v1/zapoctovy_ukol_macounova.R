
# načteme balíčky
xfun::pkg_attach2("tidyverse",
                  "arrow",
                  "RCzechia") # pro získání polygonů CHKO

# načteme (lépe řečeno odkážeme se na) data a metadata
data <- open_dataset("data/wq_water_data")

meta1 <- open_dataset("metadata/wq_water_metadata1")

meta2 <- open_dataset("metadata/wq_water_metadata2")

# nakonec také načteme potřebnou vektorovou vrstvu s CHKO
chko <- chr_uzemi() |> # jde o funkci balíčku RCzechia
  filter(TYP == "CHKO") |> 
  as_tibble() |> 
  st_sf()

# 1) vymezení na rok 1998
muj_rok <-  1998

data_1998 <- data |>
  filter(year == muj_rok) |> #tady chci jen roky 1998
  collect()

data_1998

# 2)připojení metadat
data_1998_meta2 <- data_1998 |>
  left_join(
    meta2 |> collect(),
    by = "tscon_id")

data_1998_meta2

# 3)dále vybereme jen řádky, kde je možné číst popis ukazatelů
data_1998_meta2_ok <- data_1998_meta2 |>
  filter(!is.na(tscon_ds))

data_1998_meta2_ok

# 4) k výsledné tabulce připojí metadata1, obsahující souřadnice 
#(geogr1 - zeměpisnou šířku, geogr2 - zeměpisnou délku; klíčem pro připojení je obj_id)
data_1998_meta2_ok_meta1 <- data_1998_meta2_ok |> 
  left_join(
    meta1 |> collect(),
    by = "obj_id" )

data_1998_meta2_ok_meta1

#přejmenování souboru
data_all <- data_1998_meta2_ok_meta1

# 5) s využitím těchto souřadnic vytvoří bodovou vektorovou vrstvu (sf), 
# k čemuž slouží funkce sf::st_as_sf(coords = c("geogr2", "geogr1"), crs = 4326)

data_sf <- data_all |> 
  filter(!is.na(geogr2),!is.na (geogr1)) |> # nejdřív zase musím vyfiltrovat hodnoty, které jsou NA
  sf::st_as_sf(
    coords = c("geogr2", "geogr1"), 
    crs = 4326)

data_sf

class(data_sf)

# 6) s využitím funkce sf::st_join() propojí atributy objektů chko a doposud modifikované vektorové vrstvy
?st_join

data_chko <- sf::st_join(
  data_sf, #borové vrstvy dat
  chko, #polygonové vrstvy CHKO
  join = st_within) #chci když je bod uvnitř 

data_chko

# 7) ve výsledných atributech se omezí na řádky, kde je možné hovořit o nechybějícím tscon_id

data_chko_ok <- data_chko |> 
  filter(!is.na(tscon_id), !is.na(NAZEV)) #chci odstranit i hodnoty, které neleží v žádném CHKO

data_chko_ok

# 8) dále v atributech odstraní sloupec s geometrií - viz např. funkci st_drop_geometry()

data_bez_geometrie <- data_chko_ok |> 
  st_drop_geometry()

data_bez_geometrie

# 9) pomocí funkce count() vytvoří ze zbývající tabulky novou tabulku s počty pozorování podle názvu CHKO a tscon_id
?count

cetnosti_CHKO <- data_bez_geometrie |>
  count(
    NAZEV,
    tscon_id,
    name = "n_pozorovani") #přejmenuji si sloupec s hodnotami

cetnosti_CHKO

# 10) exportuje finální tabulku do RDS souboru
saveRDS(
  cetnosti_CHKO,
  file = "cetnosti_CHKO_1998.rds")

# bonus -------------------------------------------------------------------
#vytvoření vektoru s názvy CHKO, pro které nebylo nalezeno žádné pozorovní v daném roce


# získáme všechny názvy CHKO
vsechny_CHKO <- chko |> 
  st_drop_geometry() |>  # odstraníme geometrii
  pull(NAZEV)            # vezmeme jen sloupec s názvem

vsechny_CHKO

# zjistíme, které CHKO nemají žádné pozorování
#setdiff vezme všechna x, která nejsou v y
chko_bez_pozorovani <- setdiff(
  vsechny_CHKO,              # x - všechny CHKO
  unique(data_bez_geometrie$NAZEV))  # y - CHKO, kde máme měření (unique odstraní duplicitní názvy CHKO)

chko_bez_pozorovani

# výpis výsledku
chko_bez_pozorovani

# uložím to do textového souboru
writeLines(chko_bez_pozorovani, "CHKO_bez_pozorovani_1998.txt")




