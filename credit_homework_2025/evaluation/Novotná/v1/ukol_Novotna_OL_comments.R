#načtení balíčků
xfun::pkg_attach2("tidyverse",
                  "arrow",
                  "RCzechia")

#odkazy na data, které budu používat
data <- open_dataset("data/wq_water_data")

meta1 <- open_dataset("data/wq_water_metadata1")

meta2 <- open_dataset("data/wq_water_metadata2")

#načtení potřebných vektorových vrstev s CHKO ## jedná se vlastně jen o jednu vektorovou vrstvu

chko <- chr_uzemi() |> 
  filter(TYP == "CHKO") |> 
  as_tibble() |> 
  st_sf()

# Bod č.1 -----------------------------------------------------------------

#Tabulka data > pouze můj zadaný rok 1996

view(data)
#Podívám se, jak je napsaný sloupeček "year", podle kterého budu vybírat hledaný rok 1996

colnames(data)

#Rok 1996 si uložím pod jméno "rok" a pomocí funkce collect se mi uloží do pravé horní lišty "Data"

rok<- open_dataset ("data/wq_water_data") |>  ## nedoporučuji uvádět mezery mezi názvem funkce a závorkou s argumenty; navíc bylo možné vycházet z objektu data bez nutnosti otevírat dataset znovu
  filter(year == 1996) |>    
  collect()  

#Podívám se, jak tabulka vypadá
View(rok)


# Bod č.2 -----------------------------------------------------------------

#Podívám se na tubulku, ze které budu připojovat sloupec
view(meta2)

#podívám se, jakého typu data jsou

class(meta2)

#jedná se o dataset, nicméně já potřebujhu tabulku
meta2_tabulka <- as_tibble(meta2) ## také jste mohla využít funkci collect(), ale v pořádku

#Propojení tabulek
rok <- rok |>
  left_join( meta2_tabulka |>  #použití funkce 'left_join' pro připojení tabulek
      select(tscon_id, tscon_ds), #kdy dojde k propojení sloupečků 'tscon_id a tscon_ds"
    by = "tscon_id")              #pro porpojení bude sloužit sloupečet 'tson_id! ## zkuste příště použít obecnější pomocnou funkci join_by(), argument by je zastaralý

view(rok)
#Tabulka, kde je již připojen sloupeček tscon_ds



# Bod č.3 -----------------------------------------------------------------
#Příkazem se zeptám na lokalizaci NA hodnot
rok |> 
  filter(is.na(tscon_ds))

#Pomocí funce suma zjistím, celkový počet řádků s NA hodnotou 
sum(is.na(rok$tscon_ds))

#Pomocí vykříčníku zneguji příkaz > vybere mi řádky s hodnotami 
rok_filtrovany <- rok |>
  filter(!is.na(tscon_ds))

#Raději se přesvědčím, že všechny sloupečky obsahují nějakou hodnotu 
sum(is.na(rok_filtrovany$tscon_ds))

view(rok_filtrovany)

# Bod č. 4 ----------------------------------------------------------------

#Předpokládádm, že meta1 budou stejně jako meta2 dataset, nikoliv tabulka
#Raději můj předpoklad ověřím
class(meta1)

#Proto meta1 převedu do tabulky

meta1_tabulka <- as.tibble(meta1) ## tady narážíte na varování, že používáte starou funkci as.tibble(), příště používejte funkci as_tibble(), tj. s podtržítkem


#Stejným způsobem, jako v roku 2, připojím tabulku
rok_filtrovany <- rok_filtrovany |>
  left_join( meta1_tabulka |>  
               select(obj_id, geogr1, geogr2), 
             by = "obj_id") 
#Tabulka, kde jsou připojené nové sloupečky se souřadnicemi
view(rok_filtrovany)


# Bod č. 5 ----------------------------------------------------------------

#podívám se do nápovědy
?st_as_sf

#Tvroba vektorové vrstvy s geometrií typu POINT
rok_filtrovany_sf <- st_as_sf(rok_filtrovany, coords = c("geogr2", "geogr1"), crs = 4326)


# Bod č.6 -----------------------------------------------------------------

?sf::st_join()

#Podívám se na souřadnicový systém vrstvy chko

st_crs(chko)

tabulka_propojeni <- st_join(rok_filtrovany_sf, chko) ## zkuste obrátit pořadí propojovaných objektů a sledujte, co se stane jak s atributy, tak s geometrií (třeba geometrie čeho je zachována?)

#Podívám se na tabulku
view(tabulka_propojeni)


# Bod č. 7 ----------------------------------------------------------------
#Znovu zkontroluji, že se v tabulce opravdu nevyskytují NA hodnoty
sum(is.na(tabulka_propojeni$tscon_id))

# Bod č. 8 ----------------------------------------------------------------

view(tabulka_propojeni)

?st_drop_geometry()

#Vymazání geometrie

tabulka_propojeni <- st_drop_geometry(tabulka_propojeni)


# BOD č. 9 ----------------------------------------------------------------

?count

#Vytvoření novétabulky
tabulka_count <- tabulka_propojeni |>
  filter(!is.na(NAZEV)) |>   # vyber jen řádky, kde je vyplněný CHKO ## skvělý tah, díky tomu, že jste se zaměřila na NAZEV, jste se vlastně vyhnula problému se záměnou objketů ve funkci st_join(); ale asi jste na to přišla náhodou díky tomu, že jste chybějící hodnoty viděla na začátku tabulky
  count(NAZEV, tscon_id)

#Nová tabulka

view(tabulka_count)

# BOD č.10 ----------------------------------------------------------------

tabulka_count |> 
  write_rds("Vysledna_tabulka.rds")


# BONUS -------------------------------------------------------------------

#Pro vytvoření vektoru hodnot, které se nevyskytují v tabulce 'tabulka_count', ale vyskytují se v tabulce 'chko'
#jsem použila funkce setdiff 
chko_bez_mereni <- setdiff(chko$NAZEV,
                           tabulka_count$NAZEV)

#Podívám se na výsledný vektor
chko_bez_mereni
