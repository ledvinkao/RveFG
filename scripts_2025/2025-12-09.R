###
# R ve fyzické geografii
# lekce 08: Vektorová a rastrová geodata v R, jejich interakce a vykreslování
# autor: O. Ledvinka
# datum: 2025-12-09
###


# Prerekvizity ------------------------------------------------------------

# platí stejné prerekvizity jako u lekce 01
# navíc se předpokládá, že pokračujeme v práci s naším R projektem založeným na začátku kurzu
# stále také platí, že je nutné dobré internetové připojení, jelikož si opět budeme brát (geo)data z internetu


# Načtení potřebných balíčků ----------------------------------------------

# načteme balíčky, jejichhž funkce budeme potřebovat pro následující práci 
# rovnou načteme i balíček pro práci s rastrovými geodaty
# a další balíček pro případnou kresbu situace
xfun::pkg_attach2("tidyverse",
                  "RCzechia", # důležitý balíček pro vektory sf se načítá automaticky s tímto
                  "terra", # balíček pro rastry (ale umí i vektory)
                  "tmap") # balíček pro kreslení map


# Tvorba vektorových geodat od geometrie po sf collection -----------------

# existují funkce pro tvorbu geometrie z vektoru nebo matice se souřadnicemi
# zkusme vektor s nějakou zeměpisnou délkou a šířkou (musí být v tomto pořadí!)
bod <- st_point(c(15, 50)) # podívejte se do dokumentace, které ještě podobné funkce v balíčku sf existují

# co je výsledkem?
bod

bod |> 
  class()

# takto převedeme třídu sfg (simple feature geometry) na třídu sfc (simple feature column)
bod <- bod |> 
  st_sfc(crs = 4326) # rovnou můžeme i specifikovat crs (coordinate reference system)

# tady jsme crs specifikovali pomocí EPSG kódu
# při volbě jiné autority jejiž nutné zadávat řetězec ve formě AUTORITA:KÓD, např. 'ESRI:54024'

# prozkoumejme, co vzniklo
bod

# funkce st_crs() se ptá na crs
# výsledek dostaneme v podobě poměrně dlouhého řetězce
bod |> 
  st_crs()

# ještě se zeptejme na třídu
bod |> 
  class()

# pokud existuje sloupec, ve kterém lze nalézt geometrii, můžeme rovnou aplikovat funkci st_sf() pro konverzi na sf collection
# sf collection je obdobou tabulky, do které lze přidávat sloupce s atributy
bod <- bod |> 
  st_sf()

# prozkoumejme
bod |> 
  class()

bod

# geometrický sloupec přejmenováváme funkcí st_set_geometry(), pokud chceme používat pipy
bod <- bod |> 
  st_set_geometry("geometry")

# teď je sloupec již přejmenovaný
bod

# pokud někdo nemá rád pipy, může použít i funkci st_geometry()
st_geometry(bod) <- "geom"

bod

# ještě jednou přejmenujeme, ať máme hezčí název:-)
bod <- bod |> 
  st_set_geometry("geometry")

# pozor! geometrický sloupec nepřejmenováváme funkcí rename(), dokud není sf collection konvertována na obyčejnou tabulku
# že máme tabulku namísto sf collection poznáme i tak, že nad tabulkou není typická hlavička (někdy se při zpracování může ztratit)

# přidejme nějaké atributy
bod <- bod |> 
  mutate(nm = "Kouřim")

bod


# Konverze sf collection na tabulku ---------------------------------------

bod <- bod |> 
  as_tibble()

# vidíme, že se hlavička ztratila
bod

# a přišli jsme tedy o třídu sf
bod |> 
  class()

# jestliže tabulka obsahuje sloupec s geometrií, lze ji na sf collection převést zpět obyčejnou funkcí st_sf()
bod <- bod |> 
  st_sf()

bod


# Jednoduché kreslení funkcemi balíčku tmap -------------------------------

# balíček tmap umožňuje kreslit jak statické mapy, tak dynamické (interaktivní) mapy
# následujícím přepneme na dynamické mapy
tmap_mode("view")

# následujícím opět na statické mapy
# nové verze tmap dokonce nabádají k použití funkce ttm() k přepínání mezi módy
tmap_mode("plot")

# schválně zůstaňme v dynamickém módu a sledujme, co se děje
tmap_mode("view")

# každé tmap kreslení začíná definicí nějaké vrstvy funkcí tm_shape()
# pak následuje způsob vykreslení
tm_shape(bod) + 
  tm_symbols() # protože neexistuje funkce tm_points(), namísto toho jsou tady funkce tm_symbols() apod. s různými defaultně nastavenými argumenty (viz nápovědu)

# ukažme, jak tohle pak vypadá ve statickém pojetí
tmap_mode("plot")

# tohle by si jistě ještě zasloužilo kreslit souřadnicovou síť apod.
tm_shape(bod) + 
  tm_symbols()


# Přilepená geometrie -----------------------------------------------------

# i když funkcí select() nebyvereme geometrii, geometrie pořád zůstává
# říkáme, že jde o tzv. 'sticky geometry'
bod |> 
  select(nm)

# geometrie se zbavujeme funkcí st_drop_geometry()
bod |> 
  st_drop_geometry()

# existuje ale i delší strategie přes konverzi na tabulku
bod |> 
  as_tibble() |> 
  select(-geometry)


# Konverze tabulky se souřadnicemi na bodovou vrstvu ----------------------

# mějme např naši metadatovou tabulku se stanicemi povrchových vod měřícími množství
# tabulku již načíst z JSON souboru umíme
url <- "https://opendata.chmi.cz/hydrology/historical/metadata/meta1.json"

meta <- jsonlite::fromJSON(url)

meta <- meta$data$data$values |> 
  as.data.frame() |> 
  as_tibble() |> 
  set_names(meta$data$data$header |> 
              str_split(",") |> 
              unlist()) |> 
  janitor::clean_names() # tímhle si jen upravujeme názvy sloupců, které jsme sebrali z hlavičky (headeru) na lepší názvy

# prohlédneme
meta

# vidíme, že vše včetně souřadnic máme teď uvedeno jako textové řetězce
# budeme potřebovat aplikovat funkci st_as_sf(), která ale chce souřadnice jako čísla
# takže nejprve konvertujeme sloupce se souřadnicemi na čísla
# a teprve pak aplikujeme funkci st_as_sf()
meta <- meta |> 
  mutate(across(starts_with("geogr"),
                as.numeric)) |> 
  st_as_sf(coords = c("geogr2", "geogr1"), # tady pozor na záměnu pořadí souřadnic
           crs = 4326)

# protože se chceme zaměřit na geometrický sloupec, raději vybereme jen některé, abychom geometrii viděli
meta |> 
  select(dbc:stream_name)

# přepněme opět na dynamické kreslení
tmap_mode("view")

# a kresleme celou tuto novou bodovou vrstvu
tm_shape(meta) + 
  tm_symbols()


# Predikáty a funkce st_crop() a st_intersection() ------------------------

# pro demonstraci si vezmeme na pomoc vrstvu 14 krajů Česka
kraje <- kraje()

kraje

# situaci si nakreslíme
# když chceme kreslit více vrstev najednou, musíme kreslení každé uvést funkcí st_shape()
tm_shape(kraje) + # pozor na změnu operátoru, podobně, jako u ggplot2 zde máme operátor + (a ne pipe)
  tm_borders() + 
  tm_shape(meta) + 
  tm_symbols()

# demonstrujme význam výběru bodů v uvnitř polygonu na pomocí predikátu st_intersects()
# vezmeme z krajů např. polygon Prahy
praha <- kraje |> 
  filter(NAZ_CZNUTS3 == "Hlavní město Praha")

# skutečně zde máme už jen jeden řádek
praha

# ještě jendou se podíváme na objekt meta
meta

# funkce st_intersects() je jedním z celé řady predikátů, které se využívají v jiných funkcích
# dokonce ani často nevíme, že takové funkce využíváme
?st_intersects

# což může být i případ výběrů pomocí hranatých závorek
# v následujícím se vlastně zaměříme jen na řádky tabulky meta, které spadají dovnitř polygonu praha
stations_praha <- meta[praha,]

# vykreslíme
tm_shape(stations_praha) + 
  tm_symbols()

# protože máme u obou vektorových vrstev stejný crs, není třeba transformovat
# v opačném případě by bylo nutné situaci napravit funkcí st_transform()

# jiný predikát již musíme specifikovat argumentem op
stations_nepraha <- meta[praha, op = st_disjoint]

# opět kreslíme
tm_shape(stations_nepraha) + 
  tm_symbols()

# tyto výběry bodů se moc neliší od výsledků získaných pomocí kombinace funkcí st_crop() a st_intersection()
# ale v případě linií a polygonů bychom již rozdíly určitě nalezli (schválně vyzkoušejte sami doma)

# demonstrujme nejprve funkci st_crop()
# opět zde platí nutnost mít stejné crs
# varování ignorujeme, souvisí se vztahy mezi atributy a geometrií, které jsme při stavění vrstvy meta neurčili
stations_cropped <- st_crop(meta, praha)

# vykreslíme situaci
tm_shape(stations_cropped) + 
  tm_symbols()

# funkce st_intersection() pracuje podobně jako clipping známý z GIS softwaru
# tato funkce ale ještě pracuje s atributy
# opět narážíme na známé varování, ale to můžeme ignorovat
stations_clipped <- st_intersection(stations_cropped, praha)

# vykreslíme
tm_shape(stations_clipped) + 
  tm_symbols()


# Význam funkce st_join() -------------------------------------------------

# funkce st_join() funguje podobně jako připojování tabulek podle klíčových sloupců, jenom namísto klíčů pracuje na bázi prostorových vztahů, tedy predikátů
# takto např. můžeme zjistit, kolik vodoměrných stanic máme v jednotlivých krajích
meta |> 
  st_join(kraje |> 
            select(NAZ_CZNUTS3)) |> # defaultně je nastaven vztah st_intersects() a připojování doleva, které také určuje, jak bude reprezentována geometrie ve výsledku (viz nápovědu k st_join())
  select(dbc, NAZ_CZNUTS3) |> # temto řádek kódu je vlastně zbytečný, ale můžeme se díky němu postupně dívat, co vzniká
  st_drop_geometry() |> # když již geometrii nepotřebujeme, je vhodné ji zahodit, aby nsledující operace netrvala příliš dlouho
  count(NAZ_CZNUTS3) # funkce count() je zkratka kombinace funkcí group_by(), summarize() a n()


# Jak načítáme vektorová geodata ze souboru? ------------------------------

# viz funkce st_read() a read_sf()
# všechny formáty, které podporuje knihovna GDAL, by mělo jít načíst
# je zde poporováno i tzv. řetězení (chains), takže existují i případy, kdy není nutné soubory rozbalovat
# řetízky umožňují načíst soubory (nebo třeba jen odkazy na ně) klidně i rovnou z internetového odkazu
?read_sf

# řetězení odkazu na soubor je pak detailně ukázáno v následující části již věnované rastrům


# Rastrová geodata - začátek ----------------------------------------------

# nejprve demonstrujme načítání rastrových geodat pomocí výše zmíněného řetězení odkazu na ně (umožněno ve funkci rast(), která také využívá knihovny GDAL)
# na interentu existují výsledky projektu PERUN, kterými jsou často právě rastrové vrstvy související s klimatickými scénáři modelu ALADIN-CLIMATE/CZ
# vybereme pouze teplotu vzduchu a pouze scénář SSP2-4.5
# víme, že na odkaze https://www.perun-klima.cz/scenare/data/SSP245_T_year_asc.zip najdeme ZIP soubor se čtyřmi rastrovými soubory (v ASC formátu)
# názvy souborů uvnitř ZIP souboru můžeme zjistit po stažení a nahlédnutí do ZIP souboru
r1 <- rast("/vsizip/vsicurl/https://www.perun-klima.cz/scenare/data/SSP245_T_year_asc.zip/SSP245_T_2021-2040_year.asc")

r2 <- rast("/vsizip/vsicurl/https://www.perun-klima.cz/scenare/data/SSP245_T_year_asc.zip/SSP245_T_2041-2060_year.asc")

r3 <- rast("/vsizip/vsicurl/https://www.perun-klima.cz/scenare/data/SSP245_T_year_asc.zip/SSP245_T_2061-2080_year.asc")

r4 <- rast("/vsizip/vsicurl/https://www.perun-klima.cz/scenare/data/SSP245_T_year_asc.zip/SSP245_T_2081-2100_year.asc")

# funkcí c() můžeme vrstvy spojit, jako bychom tvořili vektor nebo seznam
r <- c(r1, r2, r3, r4)

# podíváme se jak vypadá hlavička objektu při tisku do konzole
# chybí zde crs, tak si jej raději přidáme
r

# zde musíme vždy používat řetězce typu 'AUTORITA:KÓD' (nebo celé WKT řetězce definující crs)
# podobně jako je funkce st_crs() při práci s vektory, zde existuje funkce crs()
crs(r) <- "EPSG:32633" # kód lze vyčíst z webové stránky https://www.perun-klima.cz/scenare/index.php

# teď již crs nastaven máme
r

# funkcí crs() se lze také na crs ptát
r |> 
  crs() |> 
  cat() # funkci cat() nebo třeba i str_view() zde používáme jen z důvodu, že původní tisk WKT řetězce je jaksi rozházený
