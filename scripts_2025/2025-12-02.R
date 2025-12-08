###
# R ve fyzické geografii
# lekce 07: Interentové stránky jako zdroj dat; základy funkcionálního programování
# autor: O. Ledvinka
# datum: 2025-12-02
###

# Prerekvizity ------------------------------------------------------------

# platí stejné prerekvizity jako u lekce 01
# navíc se předpokládá, že pokračujeme v práci s naším R projektem založeným na začátku kurzu
# více než kdy jindy platí, že je nutné dobré internetové připojení, jelikož budeme pracovat s daty a odkazy na ně na internetu


# Načtení balíčků ---------------------------------------------------------

# pro turo lekci budeme potřebovat tidyverse a balíček rvest; dále se počítá s nainstalovanými balíčky jsonlite a janitor
# rvest je určen k tzv. web scrapingu a tedy pro případy, kdy data potřebujeme tzv. harvestovat z internetu jinými způsoby, když nejsou data klasicky ke stažení v souboru
# někdy se funkce balíčku rvest hodí i v případě existují-li soubory ke stažení, ale je jich mnoho na to, abychom je stahovali ručně
xfun::pkg_attach("tidyverse",
                 "rvest")


# Zisk tabulek a odkazů prostřednictvím funkcí rvest ----------------------

# nejpre jako příklad jedna tabulka, která se nachází v katalogu dat nahraných na Google Earth Engine
# odkaz ukládáme jako textový řetězec
url <- "https://developers.google.com/earth-engine/datasets/catalog/ESA_WorldCover_v100"

# tabulek získáme nejprve více, proto pro objekt vybíráme název tabs
tabs <- url |> # vycházíme z odkazu (v textové podobě)
  read_html() |> # takto načítáme stránku z url
  html_table() # takto ze stránky získáme vše, co je prezentováno jako tabulka

# prohlédneme
# výsledkem je seznam (list), který ovšem nemá jména elementů
tabs

# na druhou tabulku, kterou potřebujeme extrahovat, aplikujeme tedy výběr dvojitými hranatými závorkami
tab <- tabs[[2]]

# prohlédneme
# teď již máme klasicky objekt třídy tibble
# a to už jde ukládat třeba i do Excelu
tab

# demonstraci získávání odkazů k souborům ke stažení demonstrujme např. na polských hydrologických datech
url2 <- "https://danepubliczne.imgw.pl/data/arch/ost_hydro/"

# tohle už vypadá složitěji, ale ve skutečnosti jen v druhém případě trochu kód kopírujeme
tab2 <- tibble(path1 = str_c(url2, # tady je snahou slepit základní odkaz s tím, co by mělo následovat
                             url2 |> # takže ze základní stránky získáváme odkazy a zpracováváme je dál do textu
                               read_html() |> 
                               html_elements("a") |> # odkazy často hledáme u HTML znaku 'a'
                               html_text() |> # sebereme odkazy jako text
                               str_subset("^[0-9]"))) |> # regulárním výrazem se zaměříme jen na řetězce, které začínají číslem
  mutate(path_final = map(path1, # funkci map() vysvětlíme později
                          \(x) str_c(x,
                                     x |> 
                                       read_html() |> 
                                       html_elements("a") |> 
                                       html_text() |> 
                                       str_subset("\\.zip$")))) |> # tady potřebujeme ZIP soubory, proto aplikujeme opět regulární výraz; znaky \\ znamenají tzv. escape, protože tečka je speciální znak
  unnest(path_final) |> # funkce unnest() odhnízdí zahnízděné odkazy v seznamu (který může tvořit klidně sloupec tabulky)
  select(-path1) # zbavujeme se nepotřebného sloupce

# prohlédneme výsledek
# máme zde sloupec s odkazy na ZIP soubory, které je již možné stáhnout
tab2

# schválně prostudujte nápovědu k funkci download.file() a zjistěte, co k takovému stažení souborů potřebuje
# jinak web scrapingem se podrobněji v knize R4DS zabývá kap. 24


# Hierarchická data -------------------------------------------------------

# viz také kap. 23 v knize R4DS

# JSON soubory, které dnes nabízí ČHMÚ v rámci svých otevřených dat, jsou klasickým příkladem hierarchických dat
# jde vlastně také o zahnízděná data, jenom s více stupni zahnízdění
# a k tomu potřebujeme funkce, které potřebná data z hloubky vytahují

# zkusme jednoduchý příklad s metadaty stanic (měřících množství) na povrchových vodách
# nejprve odkaz
url3 <- "https://opendata.chmi.cz/hydrology/historical/metadata/meta1.json"

# funkce fromJSON() z balíčku jsonlite se snaží vytvořit z JSON uspořádání vytvořit seznam, z nichž některé prvky jsou matice, některé vektory a některé opět seznamy
# původně jde výhraně o text
meta <- jsonlite::fromJSON(url3)

# můžeme se podívat na názvy prvků seznamu, ze kterého potřebujeme data vyseparovat
meta |> 
  names()

# nás zajímá prvek data
# a pak opět data a pak values, když se chceme dostat k nejdůležitější matici
# operátor $ lze použít máme-li prvky seznamu pojmenovány

# pro pojmenování výsledných sloupců přicházejících s maticí se naopak potřebujeme dostat k tzv. headeru (hlavičce)
jsonlite::fromJSON(url3)$data$data$header |> 
  str_split(",") |> # funkce str_split() tvoří seznam
  unlist() # funkcí unlist() jej převedeme na vektor

# celkově máme tedy
# klidně starý objekt meta přepíšeme, věříme-li si
meta <- jsonlite::fromJSON(url3)$data$data$values |> 
  as.data.frame() |> # na tibble nepřevádíme rovnou kvůli názvům sloupců, s jejichž opravami bychom se jen zbytečně zdržovali
  as_tibble() |> 
  set_names(jsonlite::fromJSON(url3)$data$data$header |> # funkce set_names() pochází z balíčku purrr a tady nastavuje jména sloupcům (která si tvoříme s headeru)
              str_split(",") |> unlist()) |> 
  janitor::clean_names() # tímto už jen názvy sloupců upravujeme na vhodnější

# prohlédneme výslednou tabulku
meta

# co by bylo potřeba ještě udělat?


# K anonymním funkcím -----------------------------------------------------

# takto bylo možné (a stále je) definovat nové funkce
# za slovíčkem function máme v oblých závorkách její argumenty (tyto mohou mít nastaveny defaultní hodnoty)
# za definicí argumentů můžeme psát tělo funkce ve složených závorkách, pokud je funkce složitější
kruh <- function(r = 5) {pi * r**2}

# odteď je funkce v globálním prostředí a můžeme ji volat
# klidně i bez značení argumentu (ten je tady jasný)
kruh(10)

# v součanosti lze ale definici funkce s argumenty začínat jen zpětným lomítkem
# jednoduchá funkce ani nepotřebuje složené závorky
kruh2 <- \(r) pi * r^2

kruh2(50)

# když funkci nepřiřadíme k žádnému objektu, kterým bychom ji pojmenovali, jde pak o tzv. anonymní funkci
# anonymní funkce využíváme velice často při tzv. funkcionálním programování


# Funkcionální programování -----------------------------------------------

# funkcionální programování v kódu poznáme podle využití funkcí jako map(), map(), pmap(), walk(), walk2(), pwalk() a dalších variant, které mohou vrátit jednodušší třídu objektu, než je seznam (např. map_chr())

# vraťme se k našim metadatům, která jsme dostali z internetu
meta

# aplikujme např. funkci map2(), abychom spojili textové řetezce ze dvou sloupců (tedy ze dvou argumentů)
# již víme, že sloupec tabulky může klidně obsahovat i seznam, takže funkce map() se může vyskytovat uvnitř funkce mutate()
meta <- meta |> 
  mutate(spojeno = map2(station_name, stream_name, # nastavujeme sloupce přes které chceme nějakou funkci aplikovat (může jít o vektory, seznamy nebo jejich kombinace)
                        \(x, y) str_c(x, # tady již nastavujeme aplikovanou funkci (třeba i anonymní)
                                      y, # máme dva sloupce, tak musíme nastavit dva argumenty (zde vybráno x a y, ale může být klidně pejsek a kocicka)
                                      sep = "_"))) # funkce str_c() už akceptuje i argument pro separátor, tak třeba volíme podtržítko

# podíváme se, co vzniklo
meta |> 
  select(obj_id:stream_name, # pro zobrazení vybíráme jen důležitější sloupce
         spojeno) |> 
  unnest(spojeno) # funkcí unnest() se zbavíme seznamu ve sloupci a vzniká tak obyčejný vektor (tedy zde, jidny situace může být složitější)

# pro zjednodušení výsledku, lze postupovat i takto
meta <- meta |> 
  mutate(spojeno = map2_chr(station_name, stream_name,
                            \(x, y) str_c(x,
                                          y,
                                          sep = "_")))

# a podíváme se na výsledek znovu
meta |> 
  select(obj_id:stream_name,
         spojeno)

# pro slučování tabulek v seznamu dnes máme
# vidíme, že existuje i funkce pro slučování do vektoru apod.
?list_rbind

# pro paralelní zpracování se dnes experimentálně využívá funkce in_parallel(), která obepíná aplikované funkce (třeba i anonymní)
# napřed ale musíme nastavit tzv. daemony pomocí funkce mirai::daemons()
# viz dokumentaci k funkci in_parallel()
?in_parallel

# když existuje funkce unnest() existuje i funkce nest()
?nest

# viz též
vignette("nest")

# varování spojeno s nepojmenováním nového sloupce
meta <- meta |> 
  nest(spojeno)

# ale automaticky se vytvořil sloupec data
colnames(meta)

# funkcí pluck() se můžeme dívat do seznamů blíže
meta |> pluck("data", 10) # tady se díváme do 10. prvku

# výběrem patřičných sloupců zjistíme, že jsme do seznamu takto dostali tabulku namísto vektoru
meta |> 
  select(obj_id:stream_name,
         data)

# aplikací funkce unnest() dostaneme vše do původního stavu
meta <- meta |> 
  unnest(data)

# máme tedy tabulku s normáními sloupci
meta |> 
  select(obj_id:stream_name,
         spojeno)

# funkcionálním programováním se blíže zabývá kap. 26 v knize R4DS
