
# cílem je získat počty pozorování pro každý identifikátor jakosti povrchové vody (tscon_id) pro jednotlivá CHKO na území Česka


# načtení potřebných balíčků
xfun::pkg_attach2("tidyverse",
                  "arrow",
                  "RCzechia")

# Odkázání se na datat a příslušná metadata k nim
data <- open_dataset("Data/wq_water_data")

meta1 <- open_dataset("metadata/wq_water_metadata1")

meta2 <- open_dataset("metadata/wq_water_metadata2")

meta1
meta2

# Vektorová vrstva CHKO z balíčku RCzechia
chko <- chr_uzemi() |> # jde o funkci balíčku RCzechia
  filter(TYP == "CHKO") |> 
  as_tibble() |> 
  st_sf()

# Načtu RDS tabulku s přiřazenými roky pro studenty
tab <- read_rds("zapoctovy_ukol/rozdeleni_roku_studentum.rds")

tab

# Můj rok: 13 Beata Ouhrabková 1995

#1, 2, 3
# výber dat
data2 <-  data |> 
  filter (year == 1995) |>       # omezení dat na rok 1995
  left_join(meta2,               # připojení metadat 2
            join_by(tscon_id)) |> 
  filter(!is.na(tscon_ds))   # vyboresu řádky kde nechybí data ve sloupcích tscon_ds (popis ukazatelů)
  

# kontrola jestli v datech nejsou hodnoty NA 
any(is.na(data2)) ## tímto jste nic nezjistila, ukazuje Vám to FALSE, i když chybějící hodnoty v datech jsou

# kontorla tříd
class(data2)
class (meta1b) ## objekt neexistuje, takže se na něj nelze ani odkazovat ve funkci
class(meta2)
class(data3) ## tento objekt opět neexistuje
class(body) # vektorová vrstrva = mí třídu "sf" a "data.frane" ## objekt neexistuje
class(chko) # vektorová vrstrva = mí třídu "sf" a "data.frane"


#4
# join hlásil chybu proto jsem meta1 převedla na tibble a provedla join
meta1b <- meta1 |> 
  as_tibble()

# připojuji metadata1 s informacemi o souřadnicích
data3 <- data2 |>
  left_join(meta1b,
            join_by(obj_id)) |> 
  collect()

#5
# vytvoření bodové vektorové vrstvy
body <-  data3 |> 
  sf::st_as_sf(coords = c("geogr2", "geogr1"), crs = 4326)
## tady jste nemusela specifikovat původ funkce st_as_sf(), protože balíček sf je načten od začátku společně s balíčkem RCzechia

body

# pokus o vykreslení bodů

xfun::pkg_attach2("tmap")

tmap_mode("view")

tm_shape(body) + # nejprve definujeme novou vrstvu
  tm_symbols() # pak způsob kreslení
## tohohle se příště vyvarujte, pokud máte tak velké množství bodů
## obyčejně se kreslí unikátní body, ne všechno, co je způsobené duplicitami kvůli nutnosti mít v tabulce časové řady
# 6

chko
class(chko)

#připojení atributů chko a vektorové vrstvy
join1 <- sf::st_join(body, chko)
## zde jste opět nemusela specifikovat původ funkce st_join()
## zkuste také obrátit pořadí propojovaných objektů ve funkci st_join() a sledovat, co se bude dít s geometrií a počty řádků

# vykreslení chko a bodů
tm_shape(chko) + tm_polygons() +
  tm_shape(body) + tm_dots()
## opět nedoporučuji všechny body takto kreslit


#7
# kontrola jestli v datech nejsou hodnoty NA ..... nejosu
any(is.na(join1$tscon_id))

# omezit se na řádky kde nechybí hodnoty tscon_id .... nemusela bych, ale pro jistotu provedu omezení
join2 <- join1 |> 
  filter(!is.na(tscon_id))

class(join2)

#8
#zbavím se geometrie
join3 <- join2 |> 
  st_drop_geometry()

class(join3)

#9
#tabulka s počty pozorování v jednotlivých chko
pocet <- join3 |> 
  count(NAZEV,tscon_id)

## následující krok je velmi chytrý kvůli zisku správné tabulky
## ale zajímavé je, že vůbec nepíšete, proč jste to provedla
pocet1 <- pocet |> 
  filter(!is.na(NAZEV))


#10
#export
saveRDS(pocet1, "pozorovani_v_chko.rds")
## namísto saveRDS() jste také mohla použít funkci write_rds()
## s tidyverse máte totiž načtený i balíček readr, který funkci write_rds() obsahuje

#bonus
prazdne <- sf::st_join(chko, body) |> 
  filter(is.na(tscon_id)) |> 
  collect() ## tuto funkci jste vůbec nemusela na konci použít

prazdne

