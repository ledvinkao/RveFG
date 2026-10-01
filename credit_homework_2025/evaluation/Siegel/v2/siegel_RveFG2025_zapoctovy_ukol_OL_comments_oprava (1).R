
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
data <- open_dataset("C:/Users/marta/Dokumenty/data/wq_water_data")

meta1 <- open_dataset("C:/Users/marta/Dokumenty/metadata/wq_water_metadata1")

meta2 <- open_dataset("C:/Users/marta/Dokumenty/metadata/wq_water_metadata2")

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

data_1992
#5

data_1992 <- st_as_sf(
  data_1992,
  coords = c("geogr2", "geogr1"), 
  crs = 4326
)   # Tento kód transformuje standardní tabulku dat do prostorového formátu bodů. Bere sloupce "geogr2" (Longitude) a "geogr1" (Latitude) a používá je k vytvoření geometrického bodu pro každý řádek

data_1992

data_1992 <- data_1992 |> 
  distinct(obj_id, .keep_all = TRUE)
# Vybereme pouze unikátní body podle ID objektu, aby se nekreslily duplicity
  
names(data_1992)
  
data_1992

tmap_mode("view") # Přepne do mapového modu
tm_shape(data_1992) +
  tm_symbols(size = 0.2, col = "blue", border.lwd = 0.5)  
# Samotné kreslení bez zbytečných mezer

#6


data_1992 <- st_join(data_1992, chko) # Jednodušší zápis - st_intersects je defaultní, výsledek je stejný
## kdybyste zde nenastavoval join = st_within, dostal byste stejný výsledek; rovněž si zkuste obrátit propojované objekty a sledujte, co se děje (jak je řešena geometrie, atributy apod.)
data_1992

experiment_chko <- st_join(chko, data_1992)
# Experiment: Prohodím pořadí objektů
# První argument je 'chko' (polygony), druhý 'data_1992' (body)

print(experiment_chko)

 
plot(st_geometry(experiment_chko)) # Vykreslí se polygony, ne body

#7

data_1992 <- data_1992 |>
  filter(!is.na(tscon_id)) # Tento kód filtruje datovou sadu data_1992 tak, aby v ní zůstaly pouze ty záznamy, které mají platnou hodnotu ve sloupci tscon_id. 

data_1992

#8

data_1992_no_geo <- st_drop_geometry(data_1992) # Tato funkce slouží k odstranění sloupce s geometrickými informacemi (bodů, linií nebo polygonů) z prostorového objektu třídy

data_1992_no_geo

#9 

pocty_pozorovani <- data_1992_no_geo |>
  count(tscon_id, NAZEV)
# Tento kód spočítá, kolikrát se vyskytuje každá kombinace identifikátoru (tscon_id) a názvu CHKO (NAZEV).

pocty_pozorovani

#10

pocty_pozorovani |> 
  write_rds("r_vysledna_tabulka/r_pocty_pozorovani_oprava.rds") # Tento kód uloží sumarizovanou tabulku pocty_pozorovani do binárního souboru s názvem r_pocty_pozorovani.rds ve specifikovaném adresáři.
