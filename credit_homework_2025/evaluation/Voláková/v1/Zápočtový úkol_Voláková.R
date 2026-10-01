# Zápočtový úkol z kurzu R ve fyzické geografii

# Autorka: Eliška Voláková
# Obor: 1.N-FGG

# Zadání úkolu ------------------------------------------------------------

# cílem je získat počty pozorování pro každý identifikátor jakosti povrchové vody (tscon_id) pro jednotlivá CHKO na území Česka
# podmínkou je vybrat pouze identifikátory, ke kterým lze získat jejich popis (tscon_ds)
# budeme vycházet ze známých Apache Parquet souborů (wq_water_data, wq_water_metadata1, wq_water_metadata2)
# každý student bude pracovat pouze s daty za přidělený rok podle přiložené tabulky v RDS souboru
# do Classroomu každý student, který usiluje o získání zápočtu, odevzdá funkční a okomentovaný R kript, který povede k zisku tabulky s četnostmi pozorování
# každý student také s R skriptem do Classroomu odevzdá výslednou tabulku s četnostmi ve formě RDS souboru


# Začátek vypracování a naznačení dalšího postupu -------------------------

# načteme balíčky
xfun::pkg_attach2("tidyverse",
                  "arrow",
                  "RCzechia") # pro získání polygonů CHKO

# načteme (lépe řečeno odkážeme se na) data a metadata
data <- open_dataset("wq_water_data/wq_water_data")

meta1 <- open_dataset("metadata/wq_water_metadata1")

meta2 <- open_dataset("metadata/wq_water_metadata2")

# nakonec také načteme potřebnou vektorovou vrstvu s CHKO
chko <- chr_uzemi() |> # jde o funkci balíčku RCzechia
  filter(TYP == "CHKO") |> 
  as_tibble() |> 
  st_sf()

# odteď každý student pracuje na svém výběru dat dle přiděleného roku, a tedy:
rozdeleni_roku_studentum <- readRDS("~/Vejška/M1. ročník/R ve FG/zapoctovy_ukol/rozdeleni_roku_studentum.rds")
view(rozdeleni_roku_studentum)
# Eliška Voláková: rok 1986

# 1) v tabulce s daty se omezí na řádky se svým rokem
muj_rok <- open_dataset("wq_water_data/wq_water_data") |> 
  filter(year == 1986) |>     # datasetu vyberu pouze můj rok
  collect()                   # uložení těchto dat

# 2) k takto omezeným datům přípojí metadata2, aby do výsledné tabulky přidal sloupce s popisem ukazatele (klíčem pro připojení je tcon_id)
meta2 <- open_dataset("metadata/wq_water_metadata2") |> 
  collect() # uložení dat do projektu
View(meta2) # když se chci podívat na celou tabulku

muj_rok <- muj_rok |> 
  left_join(meta2, # left_join(), protože chceme přidat sloupce z připojované tabulky vpravo
            join_by(tscon_id == tscon_id)) # propojení podle tscon_id


# 3) dále vybere jen řádky, kde je možné číst popis ukazatelů (tedy nechybí hodnoty ve sloupci tscon_ds)
rok_1986 <- muj_rok |> # vytvoření nové vyfiltrované tabulky
  filter(!is.na(tscon_ds)) # ! je negace, otočení příkazu => "Vyber řádky, kde není pravda, že hodnota chybí"
  # collect() už nemusím dávat, protože už mám tabulku načtenou

# 4) k výsledné tabulce připojí metadata1, obsahující souřadnice (geogr1 - zeměpisnou šířku, geogr2 - zeměpisnou délku; klíčem pro připojení je obj_id)
meta1 <- open_dataset("metadata/wq_water_metadata1") |> 
  collect() # uložení dat do projektu
View(meta1)

rok_1986 <- rok_1986 |> 
  left_join(meta1, # left_join(), protože chceme přidat sloupce z připojované tabulky vpravo
            join_by(obj_id == obj_id))

# 5) s využitím těchto souřadnic vytvoří bodovou vektorovou vrstvu, k čemuž slouží funkce sf::st_as_sf(coords = c("geogr2", "geogr1"), crs = 4326)
body <- rok_1986 |> 
  sf::st_as_sf(coords = c("geogr2", "geogr1"), crs = 4326)

# 6) s využitím funkce sf::st_join() propojí atributy objektů chko a doposud modifikované vektorové vrstvy
body <- body |> 
  sf::st_join(chko, join = st_within) # propojování prostorových dat, st_within => body musí být striktně někde uvnitř (mohlo by být i st_intersects)

# 7) ve výsledných atributech se omezí se na řádky, kde je možné hovořit o nechybějícím tscon_id
body_final <- body |> 
  filter(!is.na(tscon_id))

# 8) dále v atributech odstraní sloupec s geometrií - viz např. funkci st_drop_geometry()
body_final <- body_final |>
  sf::st_drop_geometry() # odstranění geometrie, v závorce nic nemusí být

# 9) pomocí funkce count() vytvoří ze zbývající tabulky novou tabulku s počty pozorování podle názvu CHKO a tscon_id
tab_final <- body_final |>
  count(NAZEV, tscon_id, name = "pocet_pozorovani") # spočítána pozorování a sloupec přejmenován
view(tab_final)

# 10) exportuje finální tabulku do RDS souboru
saveRDS(tab_final, file = "tab_final.rds") # export do složky, ve které pracuji
