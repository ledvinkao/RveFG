###
# R ve fyzické geografii
# lekce 09: Rastry a jejich interakce s vektorovými geodaty
# autor: O. Ledvinka
# datum: 2025-12-16
###

# Prerekvizity ------------------------------------------------------------

# platí stejné prerekvizity jako u lekce 01
# navíc se předpokládá, že pokračujeme v práci s naším R projektem založeným na začátku kurzu
# stále také platí, že je nutné dobré internetové připojení, jelikož si budeme brát (geo)data z internetu


# Načtení potřebných balíčků a rastrových geodat --------------------------

# zde načítáme balíček sf namísto balíčku RCzechia
# jelikož jsme nakonec potřebovali nějaká geodata stáhnout i funkcemi balíčku RCzechia, použili jsme na patřičných řádcích konstrukt se dvěma dvojtečkami
xfun::pkg_attach("tidyverse",
                 "sf", # zopakujme, že tento balíček je načítán kvůli vektorovým geodatům
                 "terra",
                 "tidyterra", # pomáhá kreslit rastry ve smyslu ggplot2 a také podporuje tidyverse slovesa a pipy
                 "tmap") # umí kreslit i rastry díky funkci tm_raster()

# vraťme se na konec naší předchozí lekce a načtěme (odkažme se) na čtyři rastrové soubory s teplotou vzduchu klimatického scénáře SSP2-4.5 modelu ALADIN-CLIMATE/CZ
r1 <- rast("/vsizip/vsicurl/https://www.perun-klima.cz/scenare/data/SSP245_T_year_asc.zip/SSP245_T_2021-2040_year.asc")

r2 <- rast("/vsizip/vsicurl/https://www.perun-klima.cz/scenare/data/SSP245_T_year_asc.zip/SSP245_T_2041-2060_year.asc")

r3 <- rast("/vsizip/vsicurl/https://www.perun-klima.cz/scenare/data/SSP245_T_year_asc.zip/SSP245_T_2061-2080_year.asc")

r4 <- rast("/vsizip/vsicurl/https://www.perun-klima.cz/scenare/data/SSP245_T_year_asc.zip/SSP245_T_2081-2100_year.asc")


# Sloučení a základy práce s rastrovými geodaty ---------------------------

# funkcí c() můžeme vrstvy spojit, jako bychom tvořili vektor nebo seznam
r <- c(r1, r2, r3, r4)

# podíváme se jak vypadá hlavička objektu při tisku do konzole
r

# objekt r nemá crs, tak jej přiřadíme funkcí crs()
# zde již musíme crs definovat textovými řetězci typu AUTORITA:KÓD
crs(r) <- "EPSG:32633" # lze psát i "epsg:32633"; jinak kód jsme vyčetli na stránkách s klimatickými scénáři

# teď už crs máme i v hlavičce objektu
r

# crs pak můžeme zpětně prohlížet opět funkcí crs()
# protože se toto info ne úplně nejlépe tiske do konzole, kombinujeme s funkcí cat() nebo str_view() 
crs(r) |> 
  cat()

crs(r) |> 
  str_view()

# objektu lze přiřadit i nové názvy vrstev
# viz funkci names(), kde počet prvků vektoru s názvy musí odpovídat počtu vrstev
names(r) <- c("period_2021_2040",
              "period_2041_2060",
              "period_2061_2080",
              "period_2081_2100")

# teď se na jednotlivé vrstvy můžeme zaměřit jejich výběrem pomocí dvojitých hranatých závorek
# vzpomeňme na zacházení se seznamy, tady je to podobné
r[[1]]

# jelikož jednotlivé vrstvy mají jména, můžeme se odkazovat i na jména
# jednak v hranatých závorkách
r[["period_2021_2040"]]

# jednak pomocí operátoru $
r$period_2021_2040

# podívejte se také na funkci terra::subset()

# kromě názvů vrstev můžeme nastavovat i čas
time(r) <- c(2021,
             2041,
             2061,
             2081)

# díky tomu se pak můžeme v hranatých závorkách odkazovat na časové komponenty a podle toho konkrétní vrstvy vybírat
r[[time(r) == 2081]]

# demonstrujme ještě s trochu jinak nastaveným časem
time(r) <- as_date(seq(ymd(20210101),
                       ymd(20810101),
                       "20 years")) # u časových sekvencí lze argument by nastavovat i takto

r

r[[year(time(r)) == 2021]]

# existují tu různé dotazovací funkce na vlastnosti rastrového objektu
nlyr(r)

ncol(r)

nrow(r)

res(r)


# Extent rastrového objektu -----------------------------------------------

# počínaje funkcí ext(), což je obdoba funkce st_bbox() u vektorových geodat lze získat polygon (rámeček) zájmového území a ten pak aplikovat dál třeba ve stahovacích službách
ext(r)

bbox <- ext(r) |> 
  vect() |> # převádíme extent na vektor (nativní vektorovou třídu balíčku terra s názvem SpatVector)
  st_as_sf() |> # když neumíme pracovat s třídou SpatVector, lze ji převést na sf collection funkcí st_as_sf()
  st_set_crs(32633) # jaksi se vytrácí informace o crs, tak ji dodáme

# a můžeme situaci vykreslit
tm_shape(bbox) + 
  tm_graticules() + # tato funkce přidává souřadnicovou síť
  tm_borders()


# Kreslení rastrů funkcemi balíčku tmap -----------------------------------

# základem je funkce tm_raster()
tm_shape(r[[1]]) + # pozor! vybíráme pro kreslení pouze první vrstvu, abychom nekreslili vše
  tm_raster()

# výsledkem je vykreslení rastru s intervalovou legendou
# je vhodné přepnout na vykreslování spojitých veličin a také změnit barvu (když máme po ruce teplotu vzduchu)
tm_shape(r[[1]]) + 
  tm_raster(col.scale = tm_scale_continuous(values = "brewer.reds")) # barevná paleta pochází z balíčku cols4all a konkrétně ze sady americké geografky Brewerové (viz https://en.wikipedia.org/wiki/Cynthia_Brewer)

# takto lze vyhledávat např. vhodné palety pro vykreslování terénu
cols4all::c4a_palettes(type = "seq") |> 
  str_subset("terrain")

# demonstrujme na dem Česka
# nejprve jej musíme stáhnout
dem <- RCzechia::vyskopis("actual")

tm_shape(dem) + 
  tm_raster(col.scale = tm_scale_continuous(values = "matplotlib.terrain"))


# Matematické operace s rastry - funkce app() a podobné -------------------

# funkce terra::app() a její obdoby, jako terra::mean(), počítají s vektory reprezentovanými buňkami rastru napříč vrstvami
# dejme tomu, že chceme počítat průměrnou teplotu vzduchu za období 2021-2100
# správně bychom měli počítat vážené průměry a vahami by měly počty dnů v jednotlivých obdobích
# váhy již získat umíme, zaměstnejme např. intervaly
vahy <- c(ymd(20210101) %--% ymd(20410101),
          ymd(20410101) %--% ymd(20610101),
          ymd(20610101) %--% ymd(20810101),
          ymd(20810101) %--% ymd(21010101)) / days(1)

vahy

# teď můžeme aplikovat funkci terra::weighted.mean()
tavg <- weighted.mean(r, w = vahy) |> 
  round(1) # lze i zaokrouhlovat (teplotu nemá smysl uvádět na víc jak jedno desetinné místo)

tavg

# takto zjistíme, pro kolik vektorů celkem tato funkce musela vážený průměr počítat
ncell(r)

# obecně tedy máme funkci terra::app(), kam můžeme vkládat vlastně jakoukoliv funkci (včetně anonymních)
# funkce terra::app() je obdobou základní funkce apply()
?app

# podobně v balíčku terra existuje i funkce lapp(), která je obdobou základní funkce lapply()
?lapp


# Funkce crop() a mask() --------------------------------------------------

# demonstrujme tyto funkce na polygonu Prahy
# nejprve musíme stáhnout polygony všech krajů
kraje <- RCzechia::kraje()

# protože si nepamatujeme přesné názvy sloupců (abchyom mohli řádky filtrovat), zobrazme si je
colnames(kraje)

# filtrujme na řádek Prahy
praha <- kraje |> 
  filter(NAZ_CZNUTS3 == "Hlavní město Praha")

# zde bychom správně měli transformovat crs vektorových geodat na crs rastrových geodat
# i když dnešní funkce balíčku terra tohle již umí dělat za nás, pokud zapomeneme (upozorní nás, že k transformaci crs došlo)
praha_t <- praha |> 
  st_transform(32633)

# a nyní aplikujme nejprve crop() a pak mask()
r_cropped_masekd <- crop(r, # lze provádět s více vrstvami najednou
                         praha_t,
                         mask = T) # maskovat lze i ve funkci crop(), pokud používáme stejný polygon, jinak je tu samostatná funkce mask()

tavg_cropped_masked <- crop(tavg, # i s naším novým rastrem průměrné teploty vzduchu
                         praha_t,
                         mask = T)

# nakresleme situaci
tm_shape(tavg_cropped_masked) + 
  tm_raster(col.scale = tm_scale_continuous(values = "brewer.reds"))


# Funkce extract() --------------------------------------------------------

# význam funkce terra::extract() je v extrahování hodnot buněk pro pozice vektorových geodat (bodů - nepotřebuje argument fun, linií - potřebuje argument fun, polygonů - potřebuje argument fun)

# demonstrujme na všech krajích
kraje <- kraje |> 
  select("NAZ_CZNUTS3") # vybíráme sloupec jen z důvodu přehlednosti

kraje <- extract(r, # lze provádět pro více vrstev najednou
                 kraje |> 
                   st_transform(crs(r)), # opět by měl být crs stejný
                 bind = T, # tímto připojujeme k atributové tabulce vektorových geodat
                 fun = mean) |> # jde o polygony, a tudíž musíme specifikovat, co se má stát s hodnotami buněk do polygonů spadajících
  st_as_sf() |> # výsledkem je SpatVector, který převádíme na sf collection
  as_tibble() |> # kosmetickými úpravami pak dodáváme ještě třídu tibble
  st_sf() # a převádíme zpět na sf collection

# podíváme se na výsledek
kraje

# jak by bylo možné zaokrouhlit všechny výsledné hodnoty na jedno desetinné místo?

# pro dálkový průzkum viz https://rspatial.org/rs/index.html, kde si lze napřed stáhnout data z družice Landsat a procvičovat na nich
