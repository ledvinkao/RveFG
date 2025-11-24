###
# R ve fyzické geografii
# lekce 05: Textové řetězce, regulární výrazy, faktory
# autor: O. Ledvinka
# datum: 2025-11-18
###


# Prerekvizity ------------------------------------------------------------

# platí stejné prerekvizity jako u lekce 01
# navíc se předpokládá, že pokračujeme v práci s naším R projektem založeným na začátku kurzu


# Načtení balíčků a metadat -----------------------------------------------

xfun::pkg_attach2("tidyverse",
                  "arrow") # protože metadata jsou v Apache Parquet souboru

# načteme 'geografická' metadata
meta1 <- open_dataset("metadata/wq_water_metadata1") |> 
  collect() # soubor není velký, takže si můžeme dovolit data sebrat do paměti

# načteme metadata vysvětlující význam měřených ukazatelů
meta2 <- open_dataset("metadata/wq_water_metadata2") |> 
  collect()

# prohlédneme začátky tabulek
meta1

meta2


# Základy textových řetězců -----------------------------------------------

# tvorba zcela nového vektoru s textovými řetězci
# klasicky používáme dvojité uvozovky (též je pak vidíme při tisku do konzole)
vek <- "Vltava"

# někdy jsme ale nuceni kombinovat dvojité uvozovky s jednoduchými uvozovkami
# to jsou případy, kdy chceme, aby uvozovky byly součástí řetězce
vek <- "'Vlatava'"

# funkce str_view() dopomáhá poodívat se na řetězec tak, jak je (tj. bez tzv. escapingu apod.)
vek |> 
  str_view() # mimochodem naprostá většina funkcí balíčku stringr, který v tidyverse používáme na řetězce, má název začínající na 'str_'

# když chceme dostat vektor s řetězci, klasicky jeho prvky poskládáme funkcí c()
vek <- c("Vltava",
         "Labe",
         "Morava")

# abychom se neupsali, někdy se hodí funkce rep(), pro opakování prvků
vek |> 
  rep(times = 20)

# zde je rozdíl mezi argumenty times a each
vek |> 
  rep(each = 20)

# chceme-li vektor kombinovat s jiným vektorek, nebo jen přidávat další prvky, lze volit následující strategii
# což tedy platí i u číselných a jiných vektorů
vek <- c(vek, "Úpa", "Metuje")

# podívejme se na výsledek
vek

# lze volit i jiné strategie, pokud chceme mít prvky vektoru uspořádány jinak
# pomáhají i hranaté závorky pro extrakci jednotlivých prvků vektoru
vek <- c("Vltava", # opět se vracíme ke starému vektoru vek
         "Labe",
         "Morava")

vek <- c(vek[1:2],
         "Úpa",
         "Metuje",
         vek[3])

vek

# samozřejmostí je se ptát na délku vektoru, a tedy na počet jeho prvků
vek |> 
  length()


# Funkce str_c() a str_glue() ---------------------------------------------

# tyto funkce mají podobný význam (slepují řetězce dohromady)
# dokonce lze využít recyklování vektoru s menším počtem prvků
# přístup těchto funkcí (a co pro získání stejného výsledku potřebujeme udělat) se ale liší
str_c("moje řeka má název ", vek)

# u funkce str_glue() si pomáháme složenými závorkami
# není ale potřeba psát čárky apod.
# sami zjistěte, co je pro vás výhodnější
str_glue("moje řeka má název {vek}")

# efektu těchto funkcí pak můžeme s výhodou využít při konstrukci nových tabulek
tibble(veta = str_c("moje řeka má název ",
                    vek))

# velmi často konstruujeme cesty k souborům, do kterých chceme ukládat svoje pracně vytvořená data
str_glue("{vek}.tif")

# str_glue() má i trochu jiný tisk do konzole a přidává i další třídu
str_glue("{vek}.tif") |> 
  class()

str_c(vek, ".tif")

str_c(vek, ".tif") |> 
  class()

# kniha R4DS o tom moc nehovoří, ale základní R přichází s příbuznými funkcemi paste() a paste0()
# paste() má argument sep, kterým určujeme, jaký oddělovač má být mezi řetězci
# paste() má též argument collapse, co je vlastně obdoba následující funkce str_flatten()
?paste

# paste0() je obdoba str_c(), tedy bez argumentu sep


# Funkce str_flatten() ----------------------------------------------------

# tato funkce tvoří vektor o jednom prvku tak, že všechny prvky slepí
# argument collapse určuje oddělovač mezi prvky půvoního vektoru
vek |> 
  str_flatten(collapse = ", ") # musíme pamatovat i na mezery za čárkou apod.

vek |> 
  str_flatten(collapse = ", ") |> 
  length()

vek |> 
  str_flatten(collapse = ", ") |> 
  class()

# k tomu, abychom získali stejné, co s argumentem collapse = ", " můžeme použít funkci str_flatten_comma()
# funkce zřejmě existuje z důvodu často vkládané čárky následované mezerou
vek |> 
  str_flatten_comma()

# u funkcí str_flatten() a str_flatten_comma() si také můžeme zvolit jiný oddělovač před posledním původním prvkem
vek |> 
  str_flatten_comma(last = " a ")


# Kombinace funkcí str_flatten() a funkce summarize() ---------------------

# budeme vycházet z tabulky v objektu meta2
# nejprve raději prohlédneme
meta2

# takto si lze např. sestavit seznamy ukazatelů se stejnými jednotkami
meta2 |> 
  group_by(unit_id) |> # nejprve seskupíme
  summarize(ukazatele = str_flatten_comma(tscon_id)) # pak slepíme identifikátory ukazatelů ve skupinách


# Délky řetězců -----------------------------------------------------------

# zde využíváme funkci str_length(), která vrací počty znaků v řetězcích (a tedy odlišuje se od funkce length())
# můžeme demonstrovat např. při konstrukci nové tabulky
tibble(vek = vek) |> 
  mutate(n = str_length(vek))


# Pozor na řazení řetězů na různých strojích s různě nastaveným OS --------

meta1

# zatímco základní funkce R, jako je funkce sort(), používají nastavení lokálního OS
reky <- meta1 |> 
  pull(stream_name) |> 
  unique() |> 
  sort()

# funkce světa tidyverse jsou standardně nastaveny na americkou angličtinu
reky2 <- meta1 |> 
  distinct(stream_name) |> 
  arrange(stream_name) |> 
  pull()

# proto se i počty znaků v jednotlivých řádcích tabulky budou lišit
# vektory jsou toziž seřazeny odlišně
tibble(reky = reky,
       reky2 = reky2) |> 
  mutate(n = str_length(reky),
         n2 = str_length(reky2))

# pozor! u počtu znaků můžeme klidně dostat odlišné odpovědi u řetězců obsahující písmena, které se někdy skládají ze několika znaků
# může se např. jednat o písmena s přehláskami, jako je ü


# Regulární výrazy --------------------------------------------------------

# pro detailnější popis viz kap. 15 knihy R4DS

# regulární výrazy pomáhají heldat přibližné shody a nenutí nás tedy záviset pouze na rovnostech
# existuje hned několik funkcí, které regulární výrazy akceptují - často tzv. pomocníci (helper functions)

# pomocník str_detect() se často vkládá do funkce filter() a docílíme tak efektivnějšího limitu na řádky
?str_detect

# vezměme si jako příklad tabulku v objektu meta1
meta1

# najděme např. všechny řádky, které obsahují ve sloupci stream_name slovo 'Labe' (s velkým L)
meta1 |> 
  filter(str_detect(stream_name, "Labe"))

# teď zkusme s malým počátečním písmenem
# někdy se tohle může hodit při odhalování chyby
# tady ale máme výsledkem prázdnou tabulku, takže zřejmě je vše v pořádku
meta1 |> 
  filter(str_detect(stream_name, "labe"))

# tohle je připomenutí, jak se ptáme na rovnost
# máme zde o jeden řádek méně, takže musí existovat řádek s ještě jinými znaky
meta1 |> 
  filter(stream_name == "Labe")

# zkusme se ptát na řetězce se slovem 'Labe' na začátku
# zde potřebujeme kotvičku ^ (musí být uvnitř uvozovek)
# ukazuje se tak, že řádek s dalšími znaky bude ten, který neobsahuje slovo 'Labe' na začátku
meta1 |> 
  filter(str_detect(stream_name, "^Labe"))

# funkce str_detect() a jí podobné mají také argument pro negaci
# takto se nám ale do výsledků připletou i řádky s jinými řekami
meta1 |> 
  filter(str_detect(stream_name, "^Labe",
                    negate = T))

# dotazy můžeme kombinovat
# a máme vyhráno
meta1 |> 
  filter(str_detect(stream_name, "^Labe",
                    negate = T), # zde opět můžeme použít čárku namísto znaku &
         str_detect(stream_name, "Labe"))

# kotvičkou $ nakonci hledaného řetězce (tedy opět uvnitř uvozovek) dáváme najevo, že právě hledáme znaky na konci


# Regulární řetězce a kvantifikátory --------------------------------------

# kvantifikátory umožňují hledat opakující se znaky
# ? je pro žádný nebo právě jeden výskyt
# + je pro jeden a více výskytů
# * je pro žádný a více výskytů
# dodejme, že znak . má svůj daný význam ve smyslu zástupného znaku (kvantifikátory říkáme, kolik jich může být)
# pokud se chceme ptát přesněji na počet opakujících se znaků, dáváme to najevo čísly ve složených závorkách (jedním přesný počet, dvěma oddělenými čárkou rozmezí)
meta1 |> 
  filter(str_detect(stream_name, "p.{3}k$")) # kvantifikátor (počet neznámých znaků daných tečkou je přesně 3)

# následující řádky mohou dávat, ale také nemusí dávat stejné výsledky
# naše tabulka je ale v tomto specifická a výsledky jsou stejné
meta1 |> 
  filter(str_detect(stream_name, "p.+k$"))

meta1 |> 
  filter(str_detect(stream_name, "p.*k$"))

meta1 |> 
  filter(str_detect(stream_name, "p.{3,5}k$"))

# na čísla se můžeme ptát takto
# hranaté závorky značí množiny znaků
meta1 |> 
  filter(str_detect(stream_name, "[0-9]"))

# u písmen rozlišujeme množinu malých a velkých
meta1 |> 
  filter(str_detect(stream_name, "[a-z]"))

meta1 |> 
  filter(str_detect(stream_name, "[A-Z]"))


# Regulární výrazy a pomocníci pro výběr sloupců --------------------------

# tady máme větší množství pomocníků, které vlastně dopomáhají hledat sloupce i bez regulárních výrazů
# máme zde např. funkce starts_with(), contains() a ends_with()
meta2 |> 
  select(starts_with("tscon"))

# ale komplexní je funkce matches(), která již akceptuje regulární výrazy
meta2 |> 
  select(matches("^tscon"))

# klidně zkusme její význam demonstrovat i ve funkci across(), u které již víme, že potřebuje nějaký výběr sloupců
meta2 |> 
  mutate(across(matches("^tscon"),
                str_flatten_comma))


# Nahrazování znaků -------------------------------------------------------

# i zde se dobře uplatňují regulární výrazy, ale často si vystačíme i bez nich
# zopakujeme si, co je uvnitř vektoru vek
vek

# funkce str_replace() nahrazuje první znak, který odpovídá podmínce hledaného výrazu
# v nápovědě vidíme, že existuje i varianta str_replace_all()
?str_replace

# demonstrujme nahrazení písmena 'a' spojovníkem
# nejprve pro všechny výskyty
str_replace_all(vek,
                "a",
                "-")

# poté pro pvní výskyt
str_replace(vek,
            "a",
            "-")

# protože časté je odstraňování znaků, jsou zde i speciální případy str_remove() a str_remove_all()
# všechny případy
str_remove_all(vek,
               "a")

# lze i kombinovat a zjišťovat nové počty znaků
str_remove_all(vek,
               "a") |> 
  str_length()

# první nalezený případ
str_remove(vek,
           "a")

# pro odstraňování znaků lze samozřejmě použít i funkce 'str_replace'
str_replace_all(vek,
                "a",
                "")

str_replace(vek,
            "a",
            "")


# Funkce měnící malá písmena na velká (a naopak) a jim podobné ------------

# mějme např. jednoprvkový vektor s řetězcem 'R for Data Science'
# a ten zkusme jednotlivými funkcemi modifikovat
nazev <- "R for Data Science"

# ponechá jen první písmeno velké
nazev |> 
  str_to_sentence()

# vše se konvertuje na malá písmena
nazev |> 
  str_to_lower()

# vše se konvertuje na velká písmena
nazev |> 
  str_to_upper()

nazev |> 
  str_to_camel()

nazev |> 
  str_to_kebab()

nazev |> 
  str_to_snake()


# Hledání souborů na disku ------------------------------------------------

# jak bylo naznačeno, práce s textovými řetězci často slouží k tvorbě názvů nových souborů
# ale můžeme tak i soubory hledat
# k získání seznamu souborů na nějakém místě slouží v základním R funkce list.files() nebo zkráceně dir()
?list.files

# vlastně se dostaneme do stejné nápovědy
?dir

# takto vytvoříme vektor cest (zde relativních) k souborům
soubory <- dir("metadata",
               recursive = T) # tento argument říká, že se chceme podívat i do podadresářů

soubory

soubory2 <- dir("metadata",
                recursive = T,
                full.names = T) # tento argument pak dává najevo, zda se chceme dívat na celé cesty

soubory2

# argument pattern je velmi důležitý hlavně z hlediska hledání souborů splňujících nějakou podmínku v názvu
soubory3 <- dir("metadata",
                pattern = "\\.parquet|\\.PARQUET", # argument pattern akceptuje i regulární výrazy
                recursive = T,
                full.names = T)

# názvy souborů lze samozřejmě modifikovat již známými funkcemi
# a tak si dopomáhat k efektnějšímu hledání souborů (např. aplikací funkce str_subset(), když argumentem pattern ve funkci dir() se nedostaneme ke kýženému výsledku)
soubory3 |> 
  str_to_upper() |> 
  str_subset("METADATA1")

soubory3 |> 
  str_to_upper() |> 
  str_subset("metadata1")


# Funkce str_sub() --------------------------------------------------------

# je rozdíl mezi str_subset() a str_sub()

# nejprve si opět zopakujeme, co je ve vektoru vek
vek

# funkce str_sub() akceptuje první a poslední index znaku, který z řetězce chceme vytáhnout
vek |> 
  str_sub(1, 2)

# čísla mohou být klidně stejná
vek |> 
  str_sub(1, 1)

# lze zadávat i záporná čísla, tj. pořadí znaku z konce
vek |> 
  str_sub(-2, -1)

vek |> 
  str_sub(-1, -1)


# Funkce str_split() a jí podobné -----------------------------------------

# tyto funkce jsou určené k trhání řetězce na více částí podle nějakého znaku či výrazu
str_split(vek,
          pattern = "a")

# standardně po aplikaci str_split() dostáváme seznam (list)
str_split(vek,
          pattern = "a") |> 
  class()

# abychom se seznamu zbavili (a vznikl tak opět obyčejný vektor), používáme funkci unlist()
str_split(vek,
          pattern = "a") |> 
  unlist()

# některé úkony extrahování částí řetězců jsou tak časté, že jim jsou věnovány speciální varianty této funkce
# ukažme příklad řetězců, kdy se může hodit speciální funkce str_split_i()
vek2 <- c("Vlatava_Vraňany",
          "Labe_Kostelec")

vek2

# extrahujeme vždy první část (jako oddělovač předpokládáme podtržítko)
reky3 <- str_split_i(vek2,
                     "_",
                     1)

# extrahujeme vždy druhou část
stanice <- str_split_i(vek2,
                       "_",
                       2)

# sestavme z extrahovaných částí novou tabulku
tab <- tibble(reky = reky3,
              stanice = stanice)

# podívejme se na výsledek
# existují i jiné fukce, které nám k tomu mohou dopomoci, ale tohle pro teď bude stačit
tab


# Faktory -----------------------------------------------------------------

# standardní R funkce k tvorbě faktorů je funkce factor()
?factor

# ukažme si ale, že je celkem nebezpečné se vázat na tuto funkci
# založme se vektor se zkratkami názvů jen vybraných měsíců
# schválně tyto měsíce uvedeme na přeskáčku
x <- c("Dec", "Apr", "Jan", "Mar")

x

# balíček forcats (který je součástí tidyverse) obsahuje mnohem lepší funkci fct()
# tou se dají různá úskalí pohlídat

# ukažme, jak se pomocí funkce forcats::fct() tvoří faktory z vektorů s textovými řetězci
x <- fct(x,
         levels = c("Jan", # právě toto je důležité (levely mohou být definovány i pro něco, co v původním vektoru být nemusí)
                    "Feb",
                    "Mar",
                    "Apr",
                    "May",
                    "Jun",
                    "Jul",
                    "Aug",
                    "Sep",
                    "Oct",
                    "Nov",
                    "Dec"))

# ukažme, co dělá základní funkce factor(), když jí naservírujeme překlep
x2 <- c("Dec", "Apr", "Jam", "Mar")

x2 <- factor(x2,
             levels = c("Jan",
                        "Feb",
                        "Mar",
                        "Apr",
                        "May",
                        "Jun",
                        "Jul",
                        "Aug",
                        "Sep",
                        "Oct",
                        "Nov",
                        "Dec"))

# funkce factor() neřekne zhola nic o tom, že máme v původním vektoru překlep a rovnou nám vloží namísto neexistujícího levelu znak NA
x2

# zkusme ještě jednou s funkcí fct()
x2 <- c("Dec", "Apr", "Jam", "Mar")

# zde dostáváme chybu - neexistuje mít překlepy ve vektorech!
x2 <- fct(x2,
          levels = c("Jan",
                     "Feb",
                     "Mar",
                     "Apr",
                     "May",
                     "Jun",
                     "Jul",
                     "Aug",
                     "Sep",
                     "Oct",
                     "Nov",
                     "Dec"))
