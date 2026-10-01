# řešení úkolu z předmětu R ve fyzické geografii
# 2025
# Kateřina Tichá

# můj přidělený rok: 1988


# Zadání ----
# 1) v tabulce s daty se omezí na řádky se svým rokem
# 2) k takto omezeným datům přípojí metadata2, aby do výsledné tabulky přidal 
    # sloupce s popisem ukazatele (klíčem pro připojení je tcon_id)
# 3) dále vybere jen řádky, kde je možné číst popis ukazatelů (tedy nechybí 
    # hodnoty ve sloupci tscon_ds)
# 4) k výsledné tabulce připojí metadata1, obsahující souřadnice (geogr1 - 
    # zeměpisnou šířku, geogr2 - zeměpisnou délku; klíčem pro připojení je obj_id)
# 5) s využitím těchto souřadnic vytvoří bodovou vektorovou vrstvu, k čemuž 
    # slouží funkce sf::st_as_sf(coords = c("geogr2", "geogr1"), crs = 4326)
# 6) s využitím funkce sf::st_join() propojí atributy objektů chko a doposud 
    # modifikované vektorové vrstvy
# 7) ve výsledných atributech se omezí se na řádky, kde je možné hovořit o 
    # nechybějícím tscon_id
# 8) dále v atributech odstraní sloupec s geometrií - viz např. funkci 
    # st_drop_geometry()
# 9) pomocí funkce count() vytvoří ze zbývající tabulky novou tabulku s počty 
    # pozorování podle názvu CHKO a tscon_id
# 10) exportuje finální tabulku do RDS souboru

# bonusem může být vytvoření vektoru s názvy CHKO, pro které nebylo nalezeno 
    # žádné pozorovní v daném roce


# Vypracování ----

# načtu balíčky
xfun::pkg_attach2("tidyverse",
                  "arrow",
                  "RCzechia") # pro získání polygonů CHKO

# načtu data a metadata
dataukol <- open_dataset("data/wq_water_data")

meta1ukol <- open_dataset("metadata/wq_water_metadata1")

meta2ukol <- open_dataset("metadata/wq_water_metadata2")

# načtu chko
chko <- chr_uzemi() |> # funkce balíčku RCzechia
  filter(TYP == "CHKO") |> 
  as_tibble() |> 
  st_sf()


# 1) načtu moji časovou řadu, tedy rok 1988
dataukol <- open_dataset("data/wq_water_data") |> 
  filter(year == 1988) |>
  collect()


# 2) načtu metadata s popisem ukazatele
meta2ukol <- open_dataset("metadata/wq_water_metadata2") |> 
  collect()

# prohlédnu tabulku
dataukol

# propojím tabulky dataukol s meta2ukol pomocí tscon_id
dataukol <- dataukol |> 
  left_join(meta2ukol,
            join_by(tscon_id == tscon_id))

# prohlédnu
dataukol
# povedlo se, v tabulce mám teď navíc tři sloupečky tscon_ds, unit_id.y a unit_ds,
    # což jsou ty, kde jsou pospány ukazatele


# 3) odstraním řádky, které mají ve sloupci tscon_ds NA hodnotu

# zjistím kolik NA hodnot se v tabulce ve sloupci tscon_ds vyskytuje 
dataukol |> 
  filter(is.na(tscon_ds))
# hodně, je jich 9 082

# vytvořím si novou tabulku, tu upravím
dataukol2 <- dataukol

# pomocí ! jako negace vyberu všechny řádky, kde NEJSOU NA a odstraním tak 
    # všechny řádky, kde chybí hodnota ve sloupci tscon_ds
dataukol2 <- dataukol |> 
  filter(!is.na(tscon_ds))

# podívám se na tabulku
dataukol2
# z tabulky jsem odstranila řádky, kde chybí hodnota tscon_id


# 4) spojím tabulku dataukol2 a tabulku metaukol1 k sobě podle obj_id

meta1ukol <- open_dataset("metadata/wq_water_metadata1") |> 
  collect()

# propojím tabulky dataukol2 s meta1ukol1 pomocí obj_id
dataukol3 <- dataukol2 |> 
  left_join(meta1ukol,
            join_by(obj_id == obj_id))

dataukol3
# v dataukol3 mám teď sloučené tabulky s daty a metadaty1, kde jsou informace 
    # o geografickém umíštění (geografické souřadnice, název toku, název profilu)


# 5) vytvořím bodovou vektorovou vrstvu

bodyukol <- dataukol3 |> 
  sf::st_as_sf(coords = c("geogr2", "geogr1"), crs = 4326)

bodyukol
# v tabulce mám teď místo sloupců geogr1 a geogr2 (zeměpisné souřadnice),
  # sloupec geometry

# načtu balíček tmap
xfun::pkg_attach2("tmap")

# takhle vykreslíme celou bodovou vrstvu (chvíli to trvá, těch bodů je hodně)
tm_shape(bodyukol) + 
  tm_symbols()


# 6) propojíme tabulku CHKO s vektorovou vrstvou bodů (bodyukol)

# propojím pomocí funkce st_join()
chkoabody <- bodyukol |> 
  sf::st_join(chko)

# zobrazím
chkoabody


# 7) vyberu pouze řádky, kde nechybí tscon_id
chkoabody |> 
  filter(is.na(tscon_id))
# nevybralo nic, tscon_id nemá chybějící hodnoty v žádném řádku


# 8) v atributech odstraním sloupec s geometrií

# geometrii odstraním pomocí funkce st_drop_geometry()
bezgeometrie <- chkoabody |> 
  st_drop_geometry()
# z tabulky jsem odstranila sloupec geometry


# 9) vytvořím novou tabulku s počty pozorování podle názvu CHKO a tscon_id

# pomocí funkce count()
pozorovani <- bezgeometrie |> 
  count(NAZEV,
        tscon_id)


# 10) exportuju tabulku do RDS souboru
pozorovani |> 
  write_rds("outputs/cetnostipozorovani.rds")
