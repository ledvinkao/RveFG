
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


# Vypracování úkolu -------------------------------------------------------

# Bod 1 -------------------------------------------------------------------


data <- data |> 
  as_tibble() #zde jsem si data převedla na tibble, aby se mi ukázala tabulka

data #tímto jsem si tabulku otevřela a prohlídla si ji

data1 <- data |> 
  filter(year==1999) # nyní jsem si odfiltrovala pomocí funkce filter() z celého souboru pouze na můj přidělený rok

# Bod 2 -------------------------------------------------------------------


meta2 <- meta2 |> 
  as_tibble() #opět jsem si převedla metadata2 na tibble (pokud jsem to neudělala tak mi to nešlo)

meta2 #prohléhla jsem si tabulku metadata2

data1 <- data1 |> 
  left_join(meta2,
            join_by(tscon_id ==tscon_id)) #timto krokem jsem připojila ke svým datum sloupeček s popisem ukayatele z metadat2 pomocí kódu tscon_id
#v zadání byl napsaný jiný kód, ale ukazovalo to error, podle popisu z erroru jsem kód upravila a přidala písmenko)

data1 #opět jsem si data prohlédla, co mi join udělal 

# Bod 3-------------------------------------------------------------------


data1 <- data1 |> 
  filter(!is.na(tscon_ds)) #tady jsem si odfiltrovala hodnoty pouze na ty, kde nechyběly hodnoty 

data1


# Bod 4 -------------------------------------------------------------------


meta1 <- meta1 |> 
  as_tibble() #metadata1 jsem si opět převedla na tibble

meta1

data1 <- data1 |> 
  left_join(meta1,
            join_by(obj_id == obj_id)) # zde jsem připojila souřadnice pomocí sloupečku geogr1 a geogr2 z metadat1

data1

# Bod 5 -------------------------------------------------------------------


data1 <- data1 |> 
sf::st_as_sf(coords = c("geogr2", "geogr1"), crs = 4326) #vytvořila jsem bodovou vektorovou vrstvu, díky vámi napovězenému kódu

data1

# Bod 6 -------------------------------------------------------------------


?sf::st_join() #zde jsem se koukla na nápovědu, jak se tento příkaz používá 

data1 <- data1 |> 
  sf::st_join(chko,
              data1) #nefungovalo, radila jsem se s chatem gpt
  
class(data1) #kontrolovala jsem ,co je to za třidu, zda je to sf

data1 <- sf::st_join(data1, chko) # napojení chko s mýma upravenýma datama roku 1999(data1)

data1 #prohlídnutí výsledné tabulky

# Bod 7 -------------------------------------------------------------------


data1 <- data1 |> 
  filter(!is.na(tscon_id)) #vybrání řádku kde nechybí hodnoty k tscon_id - všechny hodnoty maji data (zjistila jsem to podle počtu před a po odfiltrování)

data1

# Bod 8 -------------------------------------------------------------------


data1 <- data1 |> 
  st_drop_geometry() #tímto krokem jsem odstranila sloupec s geometri, zůstali pouze atributová data

data1

# Bod 9 -------------------------------------------------------------------


?count # opět jsem se koukala do nápovědy, jak se tato funce správně používá

výsledek <- data1 |> 
  count(NAZEV, tscon_id) #vytvoření nové tabulky, tabulka pouze s názvem chko, id a počet pozorování
# vytořila jsem si novou proměnou pojmenovanou výsledek - to je právě tato osekaná tabulka

výsledek # tady jsem si prohlédla nově vytvořenou tabulku

# Bod 10 - výsledek -------------------------------------------------------

výsledek |> 
  write_rds("outputs/zapoctovy_ukol.rds") # tímto krokem jsem vyexportovala konečnou tabulku - výsledek do souboru .rds, která se mi uložila do složky outputs
# tímto jsem získala konečný výsledek úkolu, vyexporovaný soubor si mohu otevřít jako list v eRstudiu
