
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
data <- open_dataset("data/wq_water_data")

meta1 <- open_dataset("metadata/wq_water_metadata1")

meta2 <- open_dataset("metadata/wq_water_metadata2")

# nakonec také načteme potřebnou vektorovou vrstvu s CHKO
chko <- chr_uzemi() |> # jde o funkci balíčku RCzechia
  filter(TYP == "CHKO") |> 
  as_tibble() |> 
  st_sf()

chko # zobrazení tabulky CHKO

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


# zpracování úkolu --------------------------------------------------------
 
data_2000 <- data |> # vybrání pouze roku 2000 (funkce filter), který mi byl přiřazen v zadání úkolu
   filter(year == 2000)

data_2000 <- data_2000 |> # načtení vyfiltrovaných dat jako tabulka, použita funkce collect() namísto funkce as_tibble()
  collect()

data_2000 # zobrazení tabulky vyfiltrovaných dat pro zadaný rok
 
meta2 <- meta2 |> # načtení metadat2 jako tabulka, opraveno z as_tibble()
  collect()
 
meta2

data_2000 |> # kontrola názvů sloupečků u filtrovaných dat i metadat - kontola podle kterého sloupečku budu napojovat
   colnames()
 
meta2 |> 
   colnames()
 
data_2000 <- data_2000 |> # napojení tabulek metadat a mé vyfiltrované tabulky (klíč k napojení je tscon_id)
   left_join(meta2,
             join_by(tscon_id == tscon_id))
 
head(data_2000) # zobrazení začátku tabulky - zde zobrazené hodnoty ve sloupci tscon_ds pouze NA (pro kontrolu hodnot jsem zobrazila i poslední řádky tabulky)
tail(data_2000) # zobrazení konce tabulky pro kontrolu hodnot obsažených ve sloupci tscon_ds
 
data_2000 <- data_2000 |> # vybrání pouze řádků, kde tscon_ds není hodnota NA (pomocí negace funkce is.na)
  filter(!is.na(tscon_ds))

data_2000 # zobrazení tabulky bez hodnot NA ve sloupečku tscon_ds

meta1 <- meta1 |> # zobrazení metadat1 jako tabulky
  as_tibble()

meta1

data_2000 <- data_2000 |> # připojení tabuklky meta1 k již výše vytvořené tabulce -> připojení sloupců geogr1 a geogr2 (klíčem byl sloupec obj_id)
  left_join(meta1,
            join_by(obj_id == obj_id))

data_2000

data_2000 <- data_2000 |> # připojení hlavičky sf s informacemi o geometrii
  st_as_sf(coords = c("geogr2", "geogr1"), crs = 4326)

data_2000

chko # zobrazení tabulky chko

data_2000 |> # zobrazení jaký formát má dosavadní tabulka data_2000
  class()
 
?st_join # nápověda pro funkci st_join

data_2000 <- st_join(data_2000, chko) # napojení tabulky data_2000 a tabulky chko v tomto pořadí připojí informace z chko na konec tabulky data_2000

data_2000 # zobrazení výsledku

data_2000 <- st_join(chko, data_2000) # napojení v opačném pořadí, tedy chko a data_2000, připojí informace z dat_2000 do tabulky chko

data_2000 # zobrazení a porovnáí s předchozím napojením

data_2000 <- data_2000 |> # vybrání pouze řádků, kde tscon_id není hodnota NA (pomocí negace funkce is.na) a zobrazení výsledků
  filter(!is.na(tscon_id))

data_2000

data_2000 <- data_2000|> # funkce st_drop_geometry pro odstranění sloupce s geometrií
  st_drop_geometry()

data_2000

?count # zobrazení nápovědy pro fukci count pro zjištění oddělovače jednotlivých vstupů (,)

# výsledný krok úkolu -----------------------------------------------------

vysledek <- data_2000 |> # vytvoření nové tabulky s názvem CHKO a počtem pozorování
  count(NAZEV.x,tscon_id)

vysledek

vysledek|> 
  write_rds("outputs/zapoctovy_ukol_kanevova_oprava.rds")

