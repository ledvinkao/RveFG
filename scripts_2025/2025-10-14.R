###
# R ve fyzické geografii
# lekce 01: Základy práce v IDE RStudio, nápovědy k funkcím a třídy objektů
# autor: O. Ledvinka
# datum: 2025-10-14
###


# Prerekvizity ------------------------------------------------------------

# předpokládá se dobré připojení k internetu a také práce s co možná nejnovějšími verzemi R a RStudio


# Práce v RStudio ---------------------------------------------------------

# ukázali jsme si základní nabídky, nastavení a vysvětlili jsme si hned několik užitečných klávesových zkratek (např. pro pipe operátor |> , či přiřazovací operátor <- )
# pro klávesové zkratky viz též sdílený soubor v Classroomu, který stále rozvíjíme v průběhu našich sezení


# Práce s nápovědami ------------------------------------------------------

# existují určitě i tlačítkové alternativy, ale doporučuji naučit se rovnou zvyknout si na příkazovou řádku

?cor.test # toto funguje, známe li přesný název funkce (např. máme kód od zkušenějšího kolegy)

# pokud máme kód od zkušenějšího kolegy, existuje i pohodlnější způsob spuštění nápovědy
# stačí kurzorem najet na název funkce a stisknout F1

??Wilcoxon # tímto způsobem najdeme funkce (mezi nainstalovanými balíčky), které by mohly odpovídat slovu napsanému za dvěma otazníky


# Načítání balíčků klasicky -----------------------------------------------

library(sos) # umožňuje načítat balíčky po jednom (ty navíc musí být nainstalovány)

# Načítání balíčků funkcí xfun::pkg_attach2()

# umožňuje načíst více balíčků najenou
# je potřeba mít nainstalovaný jen balíček xfun, všechny ostatní balíčky se instalují, je-li zjištěna jejich absence
# balíček sos jsme tedy mohli také nainstalovat a načíst následovně
xfun::pkg_attach2("sos") # tady jsou uvozovky nutné


# Speciální nápovědy pro nenainstalované balíčky --------------------------

# toto je základní funkce pro hledání funkcí mimo nainstalované balíčky
findFn("{pycnophylactic interpolation}") # složené závorky značí, že totot je výraz o dvou slovech, u kterých striktně vyžadujeme, aby byly za sebou


# K zobrazování nápověd lze přistupovat i jinak ---------------------------

# pokud balíček nechceme načítat (máme jej však nainstalovaný), ale chceme rychle prohlédnout nápovědu k některé funkci z něho
# v tomto případě můžeme využít konstrukt se dvěma dvojtečkami (vlevo od nich je název balíčku, vpravo pak název funkce)
?purrr::map # tedy využíváme znalosti původu funkce a upřesňujeme název balíčku (tzv. namespacing se může hodit i při problémech s konflikty mezi názvy funkcí z různých balíčků)

# nápovědy přístupu tidyverse jsou tak šikovně napsány (a využívají k tomu i tzv. badge), že čtenář je (zatím) určitě napřed od odpovědí AI
?dplyr::mutate_if # toto je příklad funkce, která sice existuje, ale vývojáři ji již vyvíjet dále nebudou (jak píšou v nápovědě)

# zde si také můžeme povšimnout, že pod jednou nápovědou se může skrývat více variant funkce (zde mutate_all())


# Příklady dalšího využívání dvojtečkového konstruktu ---------------------

# zde stahujeme polygon hranic Česka, kód tedy bude fungovat jen s připojením k internetu
hranice <- RCzechia::republika()

# takto lze např. kreslit interaktivní mapy (jde o demonstraci kreslení v panelu Viewer namísto v panelu Plots)
mapview::mapview(hranice)


# Demonstrace významu pipu a psaní kódu -----------------------------------

# napřed načteme potřebný balíček
# jde jen o demonstraci, význam tohoto balíčku si vysvětlíme detailněji později
xfun::pkg_attach2("sf")

hranice |> # jsou původně staženy v CRS s EPSG 4326 (longlat)
  st_transform(32633) |> # potřebuji nejlépe rovinný CRS, např. s EPSG 32633, který se používá v Česku (používá jej i ĆHMÚ; blíže ke kódům viz např. web ČÚZK)
  st_buffer(units::set_units(-30, km)) |> # tvoříme buffer, který může být klidně záporný (využíváme balíček units, který ale v tomto případě musí být nainstalovaný předem)
  mapview::mapview() # ihned můžeme kreslit interaktivně

# kód píšeme, jako bychom chtěli psát normální text, u kterého chceme, aby byl dobře čitelný nejen pro nás
# vkládáme tedy mezery za čárky, mezerami oddělujeme operátory atp.
# pipe operátor je vhodný i proto, že za ním může být kód na nové řádce (podobně za operátorem + apod.) - vkládají se pak i lépe komentáře
# pipe operátor je vhodný i ztoho důvodu, že kód můžeme pouštět do konzole postupně, a tedy studovat, co se postupně vytváří


# Demonstrace načítání více balíčků najednou ------------------------------

# tohle budeme dělat velmi často na začátku skriptu, pokud dopředu víme, se kterými balíčky budeme pracovat dále
xfun::pkg_attach2("tmap", # asi nejlepší balíček pro kreslení map v R
                  "geodata") # balíček pro získávání geodat z internetu (podobně jako RCzechia, ale je zaměřený na globální datasety, ne jen na území Česka)


# Existují datasety přicházející přímo s R nebo s jeho balíčky ------------

# toto je příklad tabulky, která se skrývá v základním balíčku datasets
trees

# jde de facto o funkci, takže se lze dívat do patřičné nápovědy
?trees

# některé balíčky s sebou přináší datasety rovnou a není nutné z internetu nic stahovat
xfun::pkg_attach2("modeldata")

# zde je potřeba dataset nejprve přidat do globálního prostředí (Global Environment)
# není nutné mu přiřazovat nové jméno
# po odeslání následujícího kódu do konzole vidíme v globálním prostředí jakýsi <Promise>, tedy příslib
data(ames)

# až teprve po vytištění objektu (tabulky) v konzoli se data nahrají do paměti
ames

# používáme přitom funkci data, kteroul lze podobně použít i na objekt trees
# viz následující nápovědu
?data


# Každý objekt má svoji třídu ---------------------------------------------

# třídy objektů lze zkoumat funkcí class()
trees |> 
  class()

# zde jde speciálně o tzv. datový rámec (řekněme jednoduše tabulku), tedy třídu, se kteroubudeme pracovat asi nejvíce (třebaže někdy přeneseně)
# zde se můžeme speciálně ptát i na názvy sloupců, což pomáhá, když je jich hodně
trees |> 
  colnames()

trees$Girth |> 
  class()

# znakem $ si z tabulky sebereme vektor
trees$Volume |> # zde musíme dbát na přesný název sloupce, tedy i na velká a malá písmena
  class()

# alternativně, místo $, lze využít hranaté závorky a uvnitř nich název sloupce v uvozovkách, či dokonce jen číslo představující pozici sloupce
# schálně prozkoumejte, co je výsledkem třech následujících řádků
trees["Volume"]

trees[3]

trees[, 3] # tady dbáme dokonce na dimenze, a tedy neklademe omezení na řádky, ale na sloupce (dáváme to najevo čárkou uvnitř hranatých závorek)

# když nebudeme používat pipe, tak bude kód vypadat následovně
colnames(ames)

# schválně, co je lepší?
ames |> 
  colnames()

# v R se dbá na rozlišování textových řetězců (character strings) a tzv. faktorů
# faktory jsou zdánlivě také textové řetězce, ale textové řetězce se týkají tzv. levelů (samotný faktor pak do modelů vstupuje jako kódovaná veličina)
ames$Neighborhood |> 
  class()

ames$Neighborhood |> 
  levels() |> 
  class()


# Je tu velký rozdíl mezi tabulkou a maticí! ------------------------------

# zatímco tabulka může obsahovat sloupce různých tříd, matice nikoliv
# matice se musí skládat ze stejných tříd, např. čísel, textových řetězců a třeba i datumů

# demonstrujme např. jak tvořit aritmetickou posloupnost s diferencí 1 a jak z ní vytvořit matici
1:9

1:9 |> 
  matrix(ncol = 3) |> # druhá dimenze, tedy počet řádků se odhadne automaticky
  class()

# na dimenze matice (ale i tabulky) se dá dotazovat funkcí dim()
1:9 |> 
  matrix(ncol = 3) |> 
  dim()

# posloupnosti se obecně tvoří funkcí seq(), konstrukt s dvojtečkou je zkratka asi nejužívanějšího případu posloupnosti aritmetické s diferencí 1
seq(from = 1, # definujeme od
    to = 9, # definujeme do
    by = 1) # definujeme diferenci

# poznamenejme, že pokud dodržujeme pořadí argumentů, lze jejich názvy vynechávat (v některých případech lze jejich názvy zkracovat)
