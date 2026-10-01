# Úvod
## Nejdříve jsem si načetl rds soubor, abych zjistil jaký rok mám spracovávat
  data1 <- readRDS("C:/Users/Vojtěch Novák/Desktop/Rko2025/rozdeleni_roku_studentum.rds")
  
  str(data1)
  
## načetl jsem balíčky potřebné ve skriptu
  xfun::pkg_attach2("tidyverse",
                    "arrow",
                    "RCzechia")
  
# odkázal jsem se na data a metadata podle návodu
  data <- open_dataset("data/wq_water_data")
  
  meta1 <- open_dataset("metadata/wq_water_metadata1")
  
  meta2 <- open_dataset("metadata/wq_water_metadata2")
  
## načetl jsem potřebnout vrstvu
  chko <- chr_uzemi() |>
    filter(TYP == "CHKO") |> 
    as_tibble() |> 
    st_sf()


# 1) v tabulce s daty se omezí na řádky se svým rokem
# 2) k takto omezeným datům přípojí metadata2, aby do výsledné tabulky přidal sloupce s popisem ukazatele (klíčem pro připojení je tcon_id)


## zjistil jsem, jak se jmenují sloupce, abych mohl data propojit s metadaty2
  colnames(meta2)
  colnames (data)


## dále jsem si vybral pouze daný rok podle přiloženého souboru, tedy 1997 pomocí filteru
## poté jsem použil funkci join_by(), abych připojil metadata k datům. Pro propojení jsem si zvolil sloupec "tscon_id", jak bylo v zadání

  
  data <- open_dataset("data/wq_water_data") |> 
    mutate(year_num = as.integer(year)) |> 
    filter(year_num == 1997,
           tscon_id == "CA0005") |> 
    collect() |> 
    select(-year_num) |> 
    left_join(meta2 |> collect(),
              join_by(tscon_id == tscon_id))
  

  ## pomocí glipse jsem si zobrazil strukturu dat abych viděl, zda selekce roku proběhla v pořádku
  data |> glimpse()


# 3) dále vybere jen řádky, kde je možné číst popis ukazatelů (tedy nechybí hodnoty ve sloupci tscon_ds)
  ## vybral tedy pomocí filteru s !is.na prázdné hodnoty

  data <- data |> 
   filter(!is.na(tscon_ds) & tscon_ds != "")


# 4) k výsledné tabulce připojí metadata1, obsahující souřadnice (geogr1 - zeměpisnou šířku, geogr2 - zeměpisnou délku; klíčem pro připojení je obj_id)
  ## v tomto kroku jsem připojil metadata1 stejným způsobem jako metadata2
  
  ### zde mám dotaz ohledně skriptů obecně. Nefungoval mi samostatně join, takže jsem sem vložil celý řetězec a fungovalo to, předpokládám, že ideální způsob je asi všechny tyto kroky skládat do jednoho řetězce pod sebe za open dataset a neopakovat tento příkaz znovu. Ale nechtěl jsem to předělávat, jelikož jsem měl už předchozí kroky okomentované 

  data <- open_dataset("data/wq_water_data") |> 
    mutate(year_num = as.integer(year)) |> 
    filter(year_num == 1997, tscon_id == "CA0005") |> 
    collect() |> 
    select(-year_num) |> 
   left_join(meta2 |> collect(), join_by(tscon_id == tscon_id)) |> 
    filter(!is.na(tscon_ds)) |> 
    left_join(meta1 |> collect(), join_by(obj_id == obj_id)) |>  # krok 4, viz poznámka ###
   select(-unit_id.x, -unit_id.y, -aspect)

  
  ## zjistil jsem kolik dat jsem vyfiltroval, jedná se tedy o 3408 měření v roce 1997
  data |> count(tscon_id)
  data |> distinct(obj_id, geogr1, geogr2) |> nrow()

  data |> 
   select(obj_id, geogr1, geogr2) |>  # šířka, délka
    distinct() |>  # unikátní stanice
    head()


# 5) s využitím těchto souřadnic vytvoří bodovou vektorovou vrstvu, k čemuž slouží funkce sf::st_as_sf(coords = c("geogr2", "geogr1"), crs = 4326)
  ## pomocí funkce v zadání jsem vytvořil bodovou vrstvu stanic
  
  stanice_sf <- data |>
    distinct(obj_id, geogr1, geogr2) |>
   st_as_sf(coords = c("geogr2", "geogr1"), crs = 4326)

  ## podíval jsem se, jak vypadá atributová tabulka
  nrow(stanice_sf)
  stanice_sf |> head()

  ## ověřil jsem, že se počet snížil, měl bych mít tedy 3408 měření celkem na 285 stanicích a otevřel jsem si jejich tabulku
  data |> distinct(obj_id, geogr1, geogr2) |> nrow()
  nrow(stanice_sf)

  view(stanice_sf)


# 6) s využitím funkce sf::st_join() propojí atributy objektů chko a doposud modifikované vektorové vrstvy
  ## propojil jsem stanice s chko pomocí join s podmínkou uvnitř a zjistil, kolik stanic se nachází v chráněných krajiných oblastech (26)

  stanice_chko <- st_join(
   stanice_sf,
   chko,
   join = st_within)
  
  stanice_chko |>
  summarise(pocet_v_chko = sum(!is.na(TYP)))
  
  ## přidal jsem novou složku stanice v chko a vykreslil jsem si graf pomocí ggplot2, abych se mohl podívat na data v mapě
  stanice_v_chko <- stanice_chko |> 
  filter(!is.na(TYP))
 
  stanice_chko <- st_join(stanice_sf, chko, join = st_within)
  
  stanice_chko <- stanice_chko |>
    mutate(v_chko = !is.na(TYP))
   
  library(ggplot2)
  
  ggplot() +
    geom_sf(data = chko, fill = NA, color = "darkgreen") +
    geom_sf(data = stanice_chko,
            aes(color = v_chko),
            size = 1.5) +
    scale_color_manual(values = c("FALSE" = "red", "TRUE" = "blue"),
                       labels = c("FALSE" = "mimo CHKO", "TRUE" = "v CHKO"),
                       name = "Stanice") +
    theme_minimal()
  
# 7) ve výsledných atributech se omezí se na řádky, kde je možné hovořit o nechybějícím tscon_id
  ## provedl jsem filtraci dat a zbavil nechtěných informací
  data <- data |>
    filter(!is.na(tscon_id) & tscon_id != "")

# 8) dále v atributech odstraní sloupec s geometrií - viz např. funkci st_drop_geometry()
  ## odstranil jsem geometrii jak bylo řečeno v zadání
  
  atributy <- stanice_chko |>
    st_drop_geometry() |>
  select(obj_id, NAZEV, TYP)
  
  data_chko <- data |>
    left_join(atributy, by = "obj_id")
  

# 9) pomocí funkce count() vytvoří ze zbývající tabulky novou tabulku s počty pozorování podle názvu CHKO a tscon_id
  ## jelikož jsem se trošku zamotal v tabulkách, tak jsem musel napojovat nějaká data k nově vzniklým tabulkám znovu a pak jsem vypočetl počet pomocí count
  
  chko_atributy <- stanice_chko |>
    st_drop_geometry() |>
    select(obj_id, NAZEV) |>
    distinct()
  
  data_chko <- data |>
    left_join(chko_atributy, by = "obj_id")
  
  tab_pocty <- data_chko |>
    filter(!is.na(NAZEV)) |>
    count(NAZEV, tscon_id, name = "pocet_pozorovani")
  
# 10) exportuje finální tabulku do RDS souboru
  saveRDS(tab_pocty, file = "vystup/tab_pocty_chko_tscon.rds")
  
  
# bonusem může být vytvoření vektoru s názvy CHKO, pro které nebylo nalezeno žádné pozorovní v daném roce
  ## bonus jsem tentokrát vynechal :)