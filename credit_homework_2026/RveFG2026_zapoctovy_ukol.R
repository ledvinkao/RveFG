# Zadání úkolu -----------------------------------------------------------

# cílem každého studenta je graficky vizualizovat průběh časové řady
# časová řada reprezentuje celkové množství odebrané podzemní vody (v m3/s)
# zkoumané období jsou jednotlivé měsíce let 2015 až 2025
# každý student pracuje s objekty odběrů podzemní vody ve vybrané obci s rozšířenou působností

# Začátek vypracování a naznačení dalšího postupu ------------------------

# nejprve načteme potřebné balíčky
xfun::pkg_attach2(
  # xfun musí být naintalovaný, zbytek ošetřujeme funkcí pkg_attach2()
  "tidyverse", # klasika
  "units", # pro přidání jednotek do sloupců tabulek
  "ggforce", # aby lépe fungovalo vykreslování grafů s jednotkami
  "arcgis", # metabalíček usnadňující načítat geografické vrstvy z internetu
  "RCzechia" # načítá i podpůrný balíček sf
)

# načteme vrstvu s ORP
orp <- orp_polygony()

# načteme vrstvu s odběry podzemní vody za období 2015-2025
# odkaz bereme z vodohospodářského portálu https://voda.gov.cz/
opod <- arc_read(
  "https://agrigis.gov.cz/public/rest/services/ISVS_Voda/odbery_podzemnich_vod/FeatureServer/13"
) |>
  as_tibble() |> # převedeme na třídu tibble
  st_sf() # převedeme opět na třídu sf (simple feature collection)

# s využitím funkce st_intersection() nebo funkce st_join() zaměříme práci na vybraný polygon ORP
# alternativně lze použít funkci arc_open() s výše uvedeným odkazem a následně se rovnou zaměřit na vybraný polygon ORP ve funkci arc_select()
# v každém případě teď vycházíme z toho, že nyní máme připojen nějaký identifikátor ORP k atributům vrstvy odběrů
# anebo vybrané řádky, které patří objektům uvnitř jednoho polygonu ORP

# Samostatná práce -------------------------------------------------------

# nyní postupujeme dle následujících bodů
# 1) vyberte u odběrů jen řádky, kde atribut 'NAD_0_5' je pravda (tedy jde o objekty s odběrem v alespoň jednom měsíci v roce na 500 m3)
# 2) vyberte z atributů sloupce CISLOVHB, ROK, MNOZ_01:MNOZ_12
# 3) jestliže již nepotřebujete geometrii (už jsme ji využili pro přiřazování objektů odběrů k ORP), zahoďte ji
# 4) natáhněte tento široký formát tabulky do dlouhého tak, aby vznikly nové sloupce pro měsíc a množství
# 5) proměnnou reprezentující měsíc modifikujte tak, aby v ní byla pouze čísla pro jednotlivé měsíce
# 6) tabulku grupujte podle roku a měsíce a následně sečtěte množství (výsledkem jsou sumy za jednotlivé měsíce let 2015-2025)
# 7) množství je uvedeno v tisících m3 za měsíc; přiřaďte správně jednotky a převeďte na m3/s, ať máte lepší představu o teoretickém odebraném průtoku v ORP
# 8) vytvořte proměnnou, která bude reprezentovat datum (vždy začátek měsíce); vycházeje ze sloupců pro rok a měsíc
# 9) sestavte graf získané časové řady (liniový, sloupcový nebo jiný vhodný typ), kde na ose x bude vyneseno datum a na ose y bude vynesen průtok (se správnými jednotkami)
# 10) okomentovaný R skript (soubor.R) a graf (soubor .png) odevzdejte do Classroomu k ohodonocení

# přidělení ORP studentům uvádí přiložený soubor 'rozdeleni_orp_studentum.rds'
