###
# R ve fyzické geografii
# lekce 02: Základy načítání a ukládání tabulkových dat
# autor: O. Ledvinka
# datum: 2025-10-21
###


# Prerekvizity ------------------------------------------------------------

# platí stejné prerekvizity jako u lekce 01
# navíc se předpokládá, že pokračujeme v práci s naším R projektem založeným na začátku kurzu


# Počáteční načtení balíčků -----------------------------------------------

# načteme potřebné balíčky, o nichž dopředu víme, najednou
xfun::pkg_attach2("tidyverse", # budeme načítat vždy
                  "arrow", # kvůli práci s Apache Parquet soubory
                  "modeldata") # jen pro opětovnou ukázku načítání dat přicházejících s balíčky


# Odbočka k dalším klávesovým zkratkám ------------------------------------

# stříšku pro umocňování lze získat zkratkou ALTGR + 3 (musíme ale za ní stisknout mezerník)
9 ^ 2

# kdo nechce psát stříšky, může namísto ní psát dvě hvězdičky (asterisks)
9 ** 2

# dataset ames pochází z balíčku metadata
# existuje k němu i jeho vlsatní nápověda
data(ames)


# Tibble je základem tidyverse --------------------------------------------

# funkcí as_tibble() převádíme obyčejný datový rámec (data frame) na tibble
ames |> 
  as_tibble()


# Je rozdíl mezi textovým řetězcem a faktorem -----------------------------

# levely faktoru mohou být definovány, ale v reálných datech se některý z levelů nemusí vyskytnout vůbec
ames$Neighborhood |> 
  levels()


# Když chceme obejít konflikty funkcí nebo jsme líní ----------------------

stats::filter()


# Načtení Apache Parquet souboru ------------------------------------------

# soubor s metadaty není velký, takže si dovolíme jej načít rovnou i do paměti (tj. globálního prostředí)
# předpokládá se, že metadata máme uložena ve složce metadata našeho projektu
meta1 <- open_dataset("metadata/wq_water_metadata1") |> 
  collect() # tímto sbíríme data do paměti

# prohlížíme
meta1

# můžeme se dotazovat i na dimenze tabulky
ncol(meta1) # počet sloupců

nrow(meta1) # počet řádků

# pro zisk názvů sloupců
colnames(meta1)

# tyto dotazy lze pak kombinovat např. s tvorbou posloupnosti
1:ncol(meta1)

# tisk více řádků objektu tibble
meta1 |> 
  print(n = 20)

# jiný zápis tohoto tisku, tentokrát bez pipu
print(meta1,
      n = 20)

# můžeme si prohlédnout začátek a konec tabulky, která je v souboru obsažena
head(meta1)

tail(meta1)


# Zápisy tabulek do běžnějších souborů a jejich znovunačítání -------------

# předpokládáme, že pro ukládání výstupů z R máme v projektu založenou složku outputs a můžeme se odkazovat relativně, pokud jde o cestu k souboru

# k ukládání XLSX souborů zde máme např. funkci writexl::write_xlsx()
writexl::write_xlsx(meta1,
                    "outputs/metadata1.xlsx")

# naopak pro načítání těchto souborů můžeme využít funkci readxl::read_xlsx()
meta1b <- readxl::read_xlsx("outputs/metadata1.xlsx")

# přesvědčíme se, že jsme skutečně soubor načetli
meta1b

# studujeme dokumentaci funkcí pro čtení CSV souborů a jiných textových souborů
?read.delim

?read_delim

# jaké argumenty mají naopak funkce pro zápis?
?write_delim

# zapisujeme klasický CSV soubor bez udání dalších nastavení
meta1 |> 
  write_csv("outputs/metadata1.csv")

# znovu načteme tento zapsaný CSV soubor bez udání dalších nastavení
meta1c <- read_csv("outputs/metadata1.csv")

# po prostudování dalších argumentů u funkce pro zápis si dovolíme nastavit i jiné argumenty
?read_csv

# takto CSV soubor načteme stejně jako dříve
# protože jsme však specifikovali typy sloupců, nekukazuje se žádná hláška upozorňující nás o odhadu těchto typů
meta1c <- read_csv("outputs/metadata1.csv",
                   col_types = "cccccdd") # při definici typů sloupců lze použít i zkratky (viz písmenka v nápovědě)

# podtržítka znamenají vynechání sloupce
meta1c2 <- read_csv("outputs/metadata1.csv",
                    col_types = "ccccc__")

# schválně, co se stalo
meta1c2

# při studiu argumentů načítacích funkcí lze využít i napídky Import Dataset pod panelem Environment (vpravo nahoře)
# takto lze např. interaktivně získat kód pro načtení našeho CSV souboru
meta1c3 <- read_csv("outputs/metadata1.csv", 
                    col_types = cols(geogr1 = col_skip(), # máme zde i jiné argumenty, které dopomáhají zbavit se některých sloupců
                                     geogr2 = col_skip()))

# výsledek je stejný jako u objektu meta 1c2
meta1c3

# příznivci R také velmi hojně využívají možnosti ukládání (serializování) objektů z globálního prostředí do tzv. RDS souborů
# existují base-R funkce pro ukládání a načítání takových souborů, ale tidyverse má svoje funkce s podtržítky v názvech
meta1 |> 
  write_rds("outputs/metadata1.rds",
            compress = "gz") # zde je možné nastavit i typ komprese (klidně i žádnou, která je defaultní)

# takto se naopak uložený soubor načítá
meta1d <- read_rds("outputs/metadata1.rds")

# prohlédneme výsledek
meta1d

# k poznámce o dočasných souborech viz nápovědu k funkci writexl::write_xlsx()
?writexl::write_xlsx
