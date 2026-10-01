
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
                  "RCzechia",
                  "tmap") # pro získání polygonů CHKO

# načteme (lépe řečeno odkážeme se na) data a metadata
data <- open_dataset("data/wq_water_data")

meta1 <- open_dataset("metadata/wq_water_metadata1")

meta2 <- open_dataset("metadata/wq_water_metadata2")

# nakonec také načteme potřebnou vektorovou vrstvu s CHKO
chko <- chr_uzemi() |> # jde o funkci balíčku RCzechia
  filter(TYP == "CHKO") |> 
  as_tibble() |> 
  st_sf()

# odteď každý student pracuje na svém výběru dat dle přiděleného roku, a tedy:

# 1) v tabulce s daty se omezí na řádky se svým rokem
# 2) k takto omezeným datům přípojí metadata2, aby do výsledné tabulky přidal sloupce s popisem ukazatele (klíčem pro připojení je tcon_id)
# 3) dále vybere jen řádky, kde je možné číst popis ukazatelů (tedy nechybí hodnoty ve sloupci tscon_ds)
# 4) k výsledné tabulce připojí metadata1, obsahující souřadnice (geogr1 - zeměpisnou šířku, geogr2 - zeměpisnou délku; klíčem pro připojení je obj_id)
# 5) s využitím těchto souřadnic vytvoří bodovou vektorovou vrstvu, k čemuž slouží funkce sf::st_as_sf(coords = c("geogr2", "geogr1"), crs = 4326)
# 6) s využitím funkce sf::st_join() propojí atributy objektů chko a doposud modifikované vektorové vrstvy
# 7) ve výsledných atributech se omezí se na řádky, kde je možné hovořit o nechybějícím tscon_id
# 8) dále v atributech odstraní sloupec s geometrií - viz např. funkci st_drop_geometry()
# 9) pomocí funkce count() vytvoří ze zbývající tabulky novou tabulku s počty pozorování podle názvu CHKO a tscon_id
# 10) exportuje finální tabulku do RDS souboru

# bonusem může být vytvoření vektoru s názvy CHKO, pro které nebylo nalezeno žádné pozorovní v daném roce

#1 Vyberu si ze souboru pouze svůj zadaný rok

data_1992 <- data |>
  filter(year==1992) |>
  collect()

data_1992 # Tento kód vybere (filtruje) všechna data z roku 1992 z původní datové sady (data) a uloží je do nového datového objektu s názvem data_1992.

#2 

metadata2 <- meta2 |> # Přidává se informace k popisu ukazatele metadata2 a nahraje se do paměti
  collect()

metadata2 # Zobrazím si přidané informace



data_1992 <- data_1992 |>
  left_join(metadata2,
            join_by(tscon_id == tscon_id)) # Kód rozšiřuje data z roku 1992 (data_1992) o doplňující informace z datové sady metadata2 tak, že je spojí podle společného identifikačního sloupce (tscon_id). Zachovány jsou přitom všechny původní řádky z data_1992.

data_1992

#3

data_1992 <- data_1992 |>
  filter(!is.na(tscon_ds)) # Tento kód odstraní (filtruje) všechny řádky z datové sady data_1992, které mají chybějící hodnotu (NA) ve sloupci tscon_ds. Zůstanou pouze řádky s platnými hodnotami v tomto sloupci.

data_1992  

#4 

metadata1 <- meta1 |> 
  collect() # Přidává se informace k popisu ukazatele metadata1 a nahraje se do paměti

metadata1

data_1992

data_1992 <- data_1992 |>
  left_join(metadata1,
            join_by(obj_id == obj_id)) # Kód rozšiřuje datovou sadu data_1992 o nové sloupce obsažené v metadata1 tak, že je spojí podle společného identifikátoru obj_id. Všechny původní řádky z data_1992 jsou zachovány.

#5

data_1992 <- st_as_sf(
  data_1992,
  coords = c("geogr2", "geogr1"), # Tento kód transformuje standardní tabulku dat do prostorového formátu bodů. Bere sloupce "geogr2" (Longitude) a "geogr1" (Latitude) a používá je k vytvoření geometrického bodu pro každý řádek
  crs = 4326)

data_1992

tm_shape(data_1992) + # Načte prostorovou datovou sadu s názvem data_1992, která musí obsahovat bodovou geometrii.Vytvoří mapu, kde jsou tato bodová data vizualizována pomocí jednoduchých, neškálovaných symbolů (bodů)

  tm_symbols()

#6

data_1992 <- st_join(data_1992, chko, join = st_within) # Tento kód provádí klíčovou operaci v prostorové analýze, známou jako prostorové spojení (spatial join). Používá funkci st_join() z balíčku sf pro přiřazení atributů z jedné prostorové vrstvy k prvkům v druhé vrstvě na základě jejich vzájemného geometrického vztahu.

data_1992

#7

data_1992 <- data_1992 |>
  filter(!is.na(tscon_id)) # Tento kód filtruje datovou sadu data_1992 tak, aby v ní zůstaly pouze ty záznamy, které mají platnou hodnotu ve sloupci tscon_id. Nebylo potřeba, jelikož všechny záznamy mají hodnotu platnou

data_1992

#8

data_1992 <- st_drop_geometry(data_1992) # Tato funkce slouží k odstranění sloupce s geometrickými informacemi (bodů, linií nebo polygonů) z prostorového objektu třídy

data_1992

#9 

pocty_pozorovani <- data_1992 |>
  group_by(tscon_id) |> # Tato funkce seskupuje řádky v datové sadě data_1992 podle unikátních hodnot ve sloupci tscon_id.
  count(NAZEV) # Seskupuje data podle sloupce NAZEV. Spočítá  počet řádků (pozorování) v každé vytvořené skupině.


pocty_pozorovani

#10

pocty_pozorovani |>
  saveRDS("r_vysledna_tabulka/r_pocty_pozorovani.rds") # Tento kód uloží sumarizovanou tabulku pocty_pozorovani do binárního souboru s názvem r_pocty_pozorovani.rds ve specifikovaném adresáři.
