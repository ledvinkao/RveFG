# NAČTENÍ BALÍČKŮ A DAT ---------------------------------------------------

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

?read_rds

rozdeleni_roku_studentum <- read_rds("rozdeleni_roku_studentum.rds") ## místo funkce readRDS() můžete používat i funkci read_rds()

#do konzole si vytisknu tabulku se jmény a roky pro zjištění požadovaného roku

rozdeleni_roku_studentum

#mým zadaným rokem je rok 1985, ten si pro jistotu uložím pod muj_rok

muj_rok <- 1985

#zobrazení tabulek pro přehled
view(data)
view(meta1)
view(meta2)


# VÝBĚR DAT V ROCE 1985 ---------------------------------------------------

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


# PROPOJENÍ TABULEK -------------------------------------------------------

#propojení tabulek (levá - tabulka, do které chci data připojit (tabulka_1985))
tabulka_s_popisem <- tabulka_1985 |> 
  left_join(meta2_tibble, 
            by = join_by(tscon_id)) # Klíč pro připojení je tscon_id ## snažte se pro příště přejít na pomocnou funkci join_by(); v join_by() není nutné psát uvozovky kolem názvů sloupců

#zobrazím
view(tabulka_s_popisem)


# ODSTRANĚNÍ NA HODNOT ----------------------------------------------------

# Vyberu jen řádky, kde je možné číst popis ukazatelů (tedy nechybí hodnoty ve sloupci tscon_ds - opustím od těch, kde je NA)
tabulka_tscon_ds <- tabulka_s_popisem |> 
  drop_na(tscon_ds) ## balíček tidyr je načtený, takže jej není nutné specifikovat

#zobrazím
view(tabulka_tscon_ds)

#zkontroluji počet NA hodnot ve sloupci tscon_ds -> vidím, že výsledek je 0 = žádné NA 
sum(is.na(tabulka_tscon_ds$tscon_ds))

# Počet řádků před filtrací tscon_ds
print(nrow(tabulka_s_popisem)) 

# Počet řádků po filtraci
print(nrow(tabulka_tscon_ds))


# PŘEVEDENÍ META1 NA TIBBLE A PROPOJENÍ META -----------------------------------------------

# Převedení meta1 do tibble
meta1_tibble <- meta1 |> 
  collect()

#můžu si opět zobrazit
view(meta1_tibble)

#připojím tabulku meta - obsahující souřadnice
tabulka_souradnice <- tabulka_tscon_ds |> 
  left_join(meta1_tibble, 
            by = join_by(obj_id)) ## v join_by() není nutné psát uvozovky kolem názvů sloupců

view(tabulka_souradnice)

# OPRAVA - PROPOJENÍ POUZE GEOGR ------------------------------------------
#V předchozím kroku jsem zbytečně propojovala tabulku se všemi hodnotami, pokusím se propojit pouze sloupce nesoucí informace o souřadnicích
#přidám do výrazu select

tabulka_souradnice <- tabulka_tscon_ds |>
  left_join(
    meta1_tibble |> select(obj_id, geogr1, geogr2),
    join_by(obj_id))

view(tabulka_souradnice)

#nyní vidím, že zde již nejsou přebytečné sloupečky jako např. dbc, nebo chmi_id z tabulky meta1_tibble

#zobrazím a zkontroluji, zda jsou přidané sloupce se souřadnicemi 'geogr1' a 'geogr2'

view(tabulka_souradnice)


# VYTVOŘENÍ BODOVÉ VEKTOROVÉ VRSTVY ---------------------------------------

#vytvořím bodovou vektorovou vrstvu
vektorova_vrstva_body <- tabulka_souradnice |> 
  st_as_sf( ## není nutné používat konstrukt s dvojtečkou, protože balíček sf je načten společně s RCzechia
    coords = c("geogr2", "geogr1"), # geogr2 = zeměpisná délka (X), geogr1 = zeměpisná šířka (Y)
    crs = 4326                      # WGS84
  )

#propojím s chko

data_s_propojenym_chko <- sf::st_join(vektorova_vrstva_body, chko) ## zkuste propojované objekty obrátit a sledujte, co se děje s atributy a geometrií (a také, která geometrie je výsledkem - bod nebo polygon?)

  # v tomto pořadí je vidět, že se v geometrii tvoří body, tedy - POINT (souřadnice) a zachovají se atributy CHKO
  # atributy z CHKO jsou přiřazeny k bodu - body "ví do kterého CHKO spadají"

data_s_propojenym_chko_opacne <- sf::st_join(chko, vektorova_vrstva_body) 

  # v tomto pořadí se v geometrii tvoří polygon 
  # atributy z bodů se připojí k polygonům
# výsledným závěrem je pro mne, že st_join() zachovává geometrii prvního zadaného prvku ## vše ve finále záleží také na nastavení argumentu left

#zobrazím
view(data_s_propojenym_chko)
view(data_s_propojenym_chko_opacne)

#Odstraním sloupce s geometrií
data_bez_geo <- data_s_propojenym_chko |> ## zkuste dále pracovat s tím druhým objektem, nebo si následně před ukládáním do souboru pohrát s chybějícími hodnotami
  st_drop_geometry()

#zobrazím
view(data_bez_geo)

# OPRAVA ------------------------------------------------------------------
#při detailnějším prohlédnutí tabulky jsem si všimla, že v některých případech chybí název CHKO
#upustím tedy od těchto řádků podobně jako na začátku

data_bez_geo <- data_bez_geo |> 
  drop_na(NAZEV)

#zkontroluji zda opravdu už zde nejsou hodnoty NA
sum(is.na(data_bez_geo$NAZEV))

#zkotroluji i tscon_id

sum(is.na(data_bez_geo$tscon_id)) #0 - velmi důležité, na tetno ukazatel se soustředíme, ostatní mohou být i NA 


# TABULKA ČETNOSTÍ --------------------------------------------------------

# Vytvořím tabulku četností 
tabulka_cetnosti <- data_bez_geo |> 
  count(NAZEV, 
        tscon_id,
        name = "pocet_pozorovani") 

view(tabulka_cetnosti)

#pro jistotu znovu ověřím
sum(is.na(tabulka_cetnosti$NAZEV))
sum(is.na(tabulka_cetnosti$tscon_id))

#celou tabulku exportuji do formátu s koncovkou .rds

tabulka_cetnosti |> 
  write_rds("finalni_tabulka_cetnosti.rds")
