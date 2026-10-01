
#ZADÁNÍ ÚKOLU:

# cílem je získat počty pozorování pro každý identifikátor jakosti povrchové vody (tscon_id) pro jednotlivá CHKO na území Česka
# podmínkou je vybrat pouze identifikátory, ke kterým lze získat jejich popis (tscon_ds)
# budeme vycházet ze známých Apache Parquet souborů (wq_water_data, wq_water_metadata1, wq_water_metadata2)
# každý student bude pracovat pouze s daty za přidělený rok podle přiložené tabulky v RDS souboru
# do Classroomu každý student, který usiluje o získání zápočtu, odevzdá funkční a okomentovaný R kript, který povede k zisku tabulky s četnostmi pozorování
# každý student také s R skriptem do Classroomu odevzdá výslednou tabulku s četnostmi ve formě RDS souboru

#--------------------------------------------------

#VYPRACOVÁNÍ: 

# načteme balíčky
xfun::pkg_attach2("tidyverse",
                  "arrow",
                  "RCzechia") # pro získání polygonů CHKO

# načteme (lépe řečeno odkážeme se na) data a metadata
data <- open_dataset("C:/Users/Jana/Desktop/projekt R/ukol/projekt/zapocet_ukol/wq_water_data")

meta1 <- open_dataset("metadata/wq_water_metadata1")

meta2 <- open_dataset("metadata/wq_water_metadata2")

# nakonec také načteme potřebnou vektorovou vrstvu s CHKO
chko <- chr_uzemi() |> # jde o funkci balíčku RCzechia
  filter(TYP == "CHKO") |> 
  as_tibble() |> 
  st_sf()

# ČÁST 1:
  #v tabulce s daty se omezí na řádky se svým rokem 

#byl mi přiřazen rok 1994

library(dplyr) ## balíček je již načtený (dplyr je součástí tidyverse), takže jde o zbytečný řádek

names(data) #abych zjistila, jak se jmenují jednotlivé sloupce, podle kterých bych mohla filtrovat -> budu filtrovat podle sloupce year

data_1994 <- data |> 
  filter(year == 1994)

# ČÁST 2:  
    #k takto omezeným datům přípojí metadata2, aby do výsledné tabulky přidal sloupce s popisem ukazatele (klíčem pro připojení je tcon_id)

#nejdříve je třeba podívat se, jestli je identifikátor v obou tabulkách stejný 
names(data)
names(meta2)
#je stejný -> použiji ,,tscon_id"

data_1994 <- data_1994 |> 
  left_join(meta2, by = "tscon_id") ## příště adaptujte svůj kód na pomocnou funkci join_by(), argument by je zastaralý

# ČÁST 3:
  #dále vybere jen řádky, kde je možné číst popis ukazatelů (tedy nechybí hodnoty ve sloupci tscon_ds)
names(data_1994)
data_1994 <- data_1994 |> 
  filter(!is.na(tscon_ds))

# ČÁST 4:
  #k výsledné tabulce připojí metadata1, obsahující souřadnice (geogr1 - zeměpisnou šířku, geogr2 - zeměpisnou délku; klíčem pro připojení je obj_id)

data_1994 <- data_1994 |> 
  left_join(meta1, by = "obj_id")

names(data_1994) #podívám se, co všechno v nové tabulce je

# ČÁST 5:
  #s využitím těchto souřadnic vytvoří bodovou vektorovou vrstvu, k čemuž slouží funkce sf::st_as_sf(coords = c("geogr2", "geogr1"), crs = 4326)
library(sf) ## balíček sf není nutné načítat, je již načten s balíčkem RCzechia

data_1994 <- data_1994 |> collect() #slouží k načtení dat do paměti a vytvoření tabulky typu tibble -> abych s daty mohla dále pracovat

vector_vrstva <- st_as_sf(data_1994, coords = c("geogr2", "geogr1"), crs = 4326) #z každé řádky (díky přiřazeným souřadnicím) se vytvoří bod s určitými vlastnostmi

# ČÁST 6:
  #s využitím funkce sf::st_join() propojí atributy objektů chko a doposud modifikované vektorové vrstvy

vector_vrstva2 <- st_join(vector_vrstva, chko) ## zkuste také obrátit pořadí propojovaných objektů a sledovat, co se stane s atributy a geometrií (např. jaká geometrie ve výsledném objektu zůstane apod.)

# ČÁST 7:
 #ve výsledných atributech se omezí se na řádky, kde je možné hovořit o nechybějícím tscon_id
vector_vrstva2 <- vector_vrstva2  |> 
  filter(!is.na(tscon_id)) ## nakonec žádné chybějící hodnoty nalezeny nebyly; zkuste přemýšlet proč se to stalo

# ČÁST 8:
  #dále v atributech odstraní sloupec s geometrií - viz např. funkci st_drop_geometry()
data_1994_2 <- st_drop_geometry(vector_vrstva2) #z vrstvy s geometrií se zpět stane tabulka

# ČÁST 9: 
  #pomocí funkce count() vytvoří ze zbývající tabulky novou tabulku s počty pozorování podle názvu CHKO a tscon_id
names(chko) #abych věděla, jak je označen sloupeček pro název CHKO

pocet_pozorovani <- data_1994_2 |>  
  count(NAZEV, tscon_id)

pocet_pozorovani #kontrola seznamu, jestli se vše přiřadilo tak, jak mělo 
tail(pocet_pozorovani) #na konci seznamu se nacházejí hodnoty, kterým nebyl přidělen název -> třeba vymazat

pocet_pozorovani <- pocet_pozorovani |>
  filter(!is.na(NAZEV)) ## skvělé, svůj kód jste správně adaptovala na obrácené pořadí objektů ve funkci st_join() nahoře

tail(pocet_pozorovani) #teď již bez řádků, které neamjí vyplněný název 

# ČÁST 10:
 #exportuje finální tabulku do RDS souboru
saveRDS(pocet_pozorovani, "pocet_pozorovani.rds") ## namísto saveRDS() můžete také používat write_rds(), pokud máte načtený tidyverse

RDS_tab <- readRDS("pocet_pozorovani.rds") #načtení tabulky pro kontrolu ## namísto readRDS() můžete také používat read_rds()

#BONUS:
 #bonusem může být vytvoření vektoru s názvy CHKO, pro které nebylo nalezeno žádné pozorovní v daném roce
vsechny_chko <- unique(chko$NAZEV) #vektor názvů CHKO, bez duplicit 

pozorovane_chko <- unique(pocet_pozorovani$NAZEV) #vektor CHKO, kde byla alespoň jedna pozorování, bez duplicit

chko_bez_pozorovani <- setdiff(vsechny_chko, pozorovane_chko) #vytvoří vektor všech CHKO, které nejsou obsaženy ve vektoru observed_CHKO ## pozor na odkazy na správné objekty v komentářích

str(chko_bez_pozorovani) #zjišťuji jaká je struktura dat -> jedná se o vektor -> potřebuji převést na tabulku 

chko_bez_pozorovani <- data.frame(NAZEV = chko_bez_pozorovani) #převod na tabulku ## mohla jste také tabulku stavět pomocí funkce tibble()

str(chko_bez_pozorovani) #ano, už je to tabulka

saveRDS(chko_bez_pozorovani, "chko_bez_pozorovani.rds") #uložení tabulky 

RDS_tab_2 <- readRDS("chko_bez_pozorovani.rds") #načtení tabulky, zda se uložila správně

