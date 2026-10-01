#Úkol-Michaela Slaninová

# Zadání úkolu: -----------------------------------------------------------

# cílem je získat počty pozorování pro každý identifikátor jakosti povrchové vody (tscon_id) pro jednotlivá CHKO na území Česka
# podmínkou je vybrat pouze identifikátory, ke kterým lze získat jejich popis (tscon_ds)
# budeme vycházet ze známých Apache Parquet souborů (wq_water_data, wq_water_metadata1, wq_water_metadata2)
# každý student bude pracovat pouze s daty za přidělený rok podle přiložené tabulky v RDS souboru
# do Classroomu každý student, který usiluje o získání zápočtu, odevzdá funkční a okomentovaný R kript, který povede k zisku tabulky s četnostmi pozorování
# každý student také s R skriptem do Classroomu odevzdá výslednou tabulku s četnostmi ve formě RDS souboru

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

# Vypracování úkolu: ------------------------------------------------------

#Načtení balíčků:

xfun::pkg_attach2("tidyverse",
                  "arrow",
                  "RCzechia") # pro získání polygonů CHKO

#Načtení dat a metadat:
data <- open_dataset("data/wq_water_data")

meta1 <- open_dataset("metadata/wq_water_metadata1")

meta2 <- open_dataset("metadata/wq_water_metadata2")

#Načtění vektorové vrstvy s CHKO
chko <- chr_uzemi() |> 
  filter(TYP == "CHKO") |> 
  as_tibble() |> 
  st_sf()

#Data si dám do paměti
data <- open_dataset("data/wq_water_data") |> 
  collect() ## tohle vřele nedoporučuji dělat hned, pokud jde o rozsáhlé časové řady; přesně z tohohle důvodu existují soubory typu .parquet - nejprve je vhodnější si připravit podmnožinu dat (např. funkcí filter()) a pak teprve sbírat je do paměti

meta1 <- open_dataset("metadata/wq_water_metadata1") |> 
  collect()

meta2 <- open_dataset("metadata/wq_water_metadata2") |> 
  collect()

#Omezení tabulky na data s rokem 1990
data_1990 <- data |> 
  filter(year == 1990)

#Připojení metadat 2 (ukazatele)
data_1990 <- data |> 
  filter(year == 1990) |> # není třeba řádky opakovat, když už jednou tuhle operaci máte hotovou
  left_join(meta2, 
            join_by(tscon_id)) #klíčem je sloupec tscon_id
  
#Ptám se na NA hodnoty
is.na(data_1990) #True mi říká, že tu NA hodnoty opravdu jsou

#Omezím se na řádky bez NA hodnot ve sloupci ukazatelů (takže chci ty kde není NA hodntoa-proto negace)
data_1990_bezNA <- data_1990 |> 
  filter(!is.na(tscon_ds))

#Připojení metadat1 (souřadnic)
data_1990_komplet <- data_1990_bezNA |> 
  left_join(meta1, 
            join_by(obj_id)) #klíčem je sloupec obj_id

#Vykreslení vektorové bodové vrstvy ## tady nejde o kreslení, nýbrž o vytvoření vektorové vrstvy
?st_as_sf

data_1990_sf <- data_1990_komplet |>
  sf::st_as_sf(coords = c("geogr2", "geogr1"), crs = 4326) #souřadnicový systém WGS 84 ## není třeba používat konstrukt se dvěma dvojtečkami, protože balíček sf je načtený rovnou s balíčkrm RCzechia

#Zkusím si vykreslit vrstvu dle tscon_id
plot(data_1990_sf["tscon_id"]) ## ještě by to chtělo kreslit mapy pro unikátní lokality a unikátní identifikátory

#Propojím atributy chko a bodovou vektorovou vrstvu 
data_1990_propojeno <- data_1990_sf |>
  sf::st_join(chko) ## opět tady není nutné používat dvojtečku; navíc zkuste obrátit propojované objekty a sledujte, co se stane jak s atributy, tak s geometrií (např. která bude preferovába - body nebo polygony?)

#Omezím se na řádky bez chybějících hodnot v tscon_id
data_1990_propojeno_bezNA <- data_1990_propojeno |> 
  filter(!is.na(tscon_id)) ## zmenšil se počet řádků?

#Odstraním sloupec s geometrií
data_1990_bezgeometrie <- data_1990_propojeno_bezNA |>
  sf::st_drop_geometry()

#Vytvořím tabulku s počty pozorování
tabulka_cetnosti <- data_1990_bezgeometrie |>
  count(NAZEV, tscon_id, name = "pocet_pozorovani")

#Mám vypsaných 11 chko + jednu nepojmenovanou, protože body leží i mimo chko->mohu se omezit jen na chko s NAZVEM:
tabulka_cetnosti <- data_1990_bezgeometrie |>
  filter(!is.na(NAZEV)) |> ## skvělé, tímto jste vyřešila problém obráceného pořadí objektů ve funkci st_join()
  count(NAZEV, tscon_id, name = "pocet_pozorovani")

# Uložení výstupu ---------------------------------------------------------

#Uložím si tabulku do rds souboru
write_rds(tabulka_cetnosti,
          "vysledky/tabulka_cetnosti.rds")


# Bonus -------------------------------------------------------------------

#Z tabulky četností, kterou jsem vytvořila si nechám vypsat názvy chko, kde proběhlo pozorování
chko_s_pozorovanim <- tabulka_cetnosti |> 
  distinct(NAZEV) #název chko se mi vždy objeví pouze jednou

chko_bez_pozorovani <- chko |> 
  anti_join(chko_s_pozorovanim, by = "NAZEV") #vrátí mi názvy, které se v chko_s_pozorováním neobjevily ale v základní tabulce chko ano
## tady jste také mohla využít pomocnou funkci join_by() namísto zastaralého argumentu by

#Vytvořím si vektor ze sloupce NAZEV
chko_bez_pozorovani_vektor <- chko_bez_pozorovani |> 
  pull(NAZEV)


# Kontrola ----------------------------------------------------------------
#Vypíši si počet řádků chko v základní tabulce se všemi chko, poté počet chko z tabulky s pozorování a nakonec chko z tabulky bez pozorování
#Součet pozorovaných a bez pozorování musí souhlasit s počtem všech chko
vsechny_n <- chko |> 
  distinct(NAZEV) |> ## tady nebylo nutné používat funkci distinct()
  nrow()

vsechny_n

pozorovane_n <- chko_s_pozorovanim |>
  nrow()

pozorovane_n

bez_pozorovani_n <- chko_bez_pozorovani |> 
  nrow()

bez_pozorovani_n

## ještě mě napadá, že byste mohla provést kontrolu pomocí spojení objektů chko_s_pozorovanim a chko_bez_pozorovani pomocí bind_rows() a porovnáním počtu řádků tohoto celého objektu s počtem řádků objektu chko
