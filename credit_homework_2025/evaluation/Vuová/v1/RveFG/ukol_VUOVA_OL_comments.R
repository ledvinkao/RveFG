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

#nahraji rozdeleni_roku_studentum

rozdeleni_roku_studentum <- readRDS("rozdeleni_roku_studentum.rds") ## místo funkce readRDS() můžete používat i funkci read_rds()

#do konzole si vytisknu tabulku se jmény a roky pro zjištění požadovaného roku

rozdeleni_roku_studentum

#mým zadaným rokem je rok 1985, ten si pro jistotu uložím pod muj_rok

muj_rok <- 1985

#zobrazení tabulek pro přehled
view(data)
view(meta1)
view(meta2)

# Otevření datasetu s filtrováním 

# year == 2008 vybere pouze rok 2008
# tscon_id == "CA0005" vybere konkrétní lokalitu
# collect() načte data do R jako tibble (ale už do paměti)

tabulka_1985 <- open_dataset("data/wq_water_data") |> 
  filter(year == 1985) |> 
  collect() #načte mi data do paměti

#zobrazím si tabulku
view(tabulka_1985)

# Převedení meta2 do tibble
meta2_tibble <- meta2 |> 
  collect()

#propojení tabulek (levá - tabulka, do které chci data připojit (tabulka_1985))
tabulka_s_popisem <- tabulka_1985 |> 
  left_join(meta2_tibble, by = "tscon_id") # Klíč pro připojení je tscon_id ## snažte se pro příště přejít na pomocnou funkci join_by()

#zobrazím
view(tabulka_s_popisem)

# Vyberu jen řádky, kde je možné číst popis ukazatelů (tedy nechybí hodnoty ve sloupci tscon_ds - opustím od těch, kde je NA)
tabulka_tscon_ds <- tabulka_s_popisem |> 
  tidyr::drop_na(tscon_ds)

#zobrazím
view(tabulka_tscon_ds)


# Počet řádků před filtrací tscon_ds
print(nrow(tabulka_s_popisem)) 

# Počet řádků po filtraci
print(nrow(tabulka_tscon_ds))

# Převedení meta1 do tibble
meta1_tibble <- meta1 |> 
  collect()
view(meta1_tibble)


#připojím tabulku meta - obsahující souřadnice
tabulka_souradnice <- tabulka_tscon_ds |> 
  left_join(meta1_tibble, by = "obj_id") 


#zobrazím a zkontroluji, zda jsou přidané sloupce se souřadnicemi 'geogr1' a 'geogr2'
view(tabulka_souradnice)

#vytvořím bodovou vektorovou vrstvu
vektorova_vrstva_body <- tabulka_souradnice |> 
  sf::st_as_sf( ## není nutné používat konstrukt s dvojtečkou, protože balíček sf je načten společně s RCzechia
    coords = c("geogr2", "geogr1"), # geogr2 = zeměpisná délka (X), geogr1 = zeměpisná šířka (Y)
    crs = 4326                      # WGS84
  )

#propojím s chko

data_s_propojenym_chko <- sf::st_join(vektorova_vrstva_body, chko) ## zkuste propojované objekty obrátit a sledujte, co se děje s atributy a geometrií (a také, která geometrie je výsledkem - bod nebo polygon?)

#zobrazím
view(data_s_propojenym_chko)

#Odstraním sloupce s geometrií
data_bez_geo <- data_s_propojenym_chko |> 
  sf::st_drop_geometry()

#zobrazím
view(data_bez_geo)

# Vytvořím tabulku četností 
tabulka_cetnosti <- data_bez_geo |> 
  count(NAZEV, 
        tscon_id,
        name = "pocet_pozorovani") 

view(tabulka_cetnosti)

#celou tabulku exportuji do formátu s koncovkou .rds

tabulka_cetnosti |> 
  write_rds("finalni_tabulka_cetnosti.rds")
