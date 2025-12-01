###
# R ve fyzické geografii
# lekce 06: Datum a čas; další speciální konstanty; propojování tabulek
# autor: O. Ledvinka
# datum: 2025-11-25
###


# Prerekvizity ------------------------------------------------------------

# platí stejné prerekvizity jako u lekce 01
# navíc se předpokládá, že pokračujeme v práci s naším R projektem založeným na začátku kurzu
# k lekci máme přiložen nový datový soubor, kterým je Apache Parquet s časovými řadami ukazateů jakosti povrchových vod


# Načtení balíčků a dat ---------------------------------------------------
xfun::pkg_attach2("tidyverse",
                  "arrow")

# funkce arrow::open_dataset() ve skutečnosti odkazuje na soubor, nenačítá data do paměti
# zde používíme název objektu nasyceni, protože se následně opravdu omezíme jen na nasycení kyslíkem
nasyceni <- open_dataset("data/wq_water_data")

# zkoumáme názvy sloupců a jejich typy pouhým tiskem do konzole
nasyceni

# názvy sloupců lze zkoumat i jinak
colnames(nasyceni)

# zjistěme, jaký identifikátor má nasycení kyslíkem
meta2 |> 
  filter(str_detect(tscon_ds, "^nasycení"))

# načítáme časové řady (ale omezujeme se na rok 2008 a ukazatel CA0005, tedy nasycení kyslíkem)
nasyceni <- open_dataset("data/wq_water_data") |> 
  filter(year == 2008,
         tscon_id == "CA0005") |> 
  collect() # až teprve touto funkcí dostaneme data do paměti

# rovnou načteme i metadata2 (s popisem ukazatelů)
meta2 <- open_dataset("metadata/wq_water_metadata2") |> 
  collect()

# prohlédneme začátek tabulky s časovými řadami
nasyceni


# Základy práce s datumy a časy -------------------------------------------

# tohle fungike, protože máme načtený balíček lubridate
# lubridate je balíček ze světa tidyverse, který je určen právě pro práci s datumem a časem
today()

today() |> 
  class()

# funkce now() přidá navíc ještě čas
now()

# výsledkem je objekt, který se v tabulkách označuje jako <dttm>
now() |> 
  class() # po zeptání se na třídu vektoru ale můžeme vidět POSIXct

# všimněte si také pořadí jednotlivých komponent (zleva doprava se jde od největších po nejmenší, což je důsledek respektování normy)


# Extrahování komponent ---------------------------------------------------

# rok dostaneme funkcí year()
now() |> 
  year()

# rok je pak 'numeric'
# tedy očekává se, že může obsahovat desetinný znak a desetinná místa
# může to být kvůli označování kvartálů
now() |> 
  year() |> 
  class()

# měsíc dostaneme funkcí month()
now() |> 
  month()

# u dnů existuje hned několik variant
# toto je den v měsíci
now() |> 
  mday()

# toto je pořadí dne v roce (v angličtině označováno jako juliánský den)
now() |> 
  yday()

# toto je pořadí dne v týdnu
now() |> 
  wday(week_start = 1) # kdybychom tohle nenastavili, dny by se počítaly od neděle

# pro hodiny máme funkci hour()
now() |> 
  hour()

# pro minuty máme funkci minute()
now() |> 
  minute()

# pro sekundy (vteřiny) je zde funkce second()
now() |> 
  second()

# názvy všech těchto extrahovacích funkcí jsou v jednotném čísle


# Stavění datumů a časů z textových řetězců -------------------------------

# pro tento účel existuje obecná funkce lubridate::as_date(), která připomíná funkci základního R as.Date()
# často si ale vystačíme s funkcemi, jejichž název lze odvodit z počátečních písmen slov znamenajících časové komponenty
# např. pro řetězec, který časové komponenty obsahuje v pořadí rok-měsíc-den zde existuje funkce ymd()
c("2025-11-25", "2025-11-26") |> # samozřejmě může být i vektor řetězců, proto nejprve spojujeme funkcí c()
  ymd()

c("2025-11-25", "2025-11-26") |> 
  ymd() |> 
  class()

# z knihy R4DS lze odvodit, že funkce akceptuje i zapeklitější řetězce
"2025 Jan 1" |> 
  ymd()

# takto můžeme postupovat, když zaměníme pořadí
"1 Nov 2024" |> 
  dmy()

# pro jiný tisk do konzole a i do souborů si pak můžeme vzít na pomoc funkci format()
"1 Nov 2024" |> 
  dmy() |> 
  format(format = "%d.%m.%Y")

# ve skutečnosti pak ale vzniká textový řetězec, ne datum nebo datum s časem
"1 Nov 2024" |> 
  dmy() |> 
  format(format = "%d.%m.%Y") |> 
  class()

# zkusme ještě formát, který často používají v USA
# zde máme na prvním místě měsíc, pak den a nakoned rok
"11/25/25" |> 
  mdy()

# když se v řetězci navíc vyskytuje ještě čas, tak můžeme použít funkci ymd_hms() a jí poobné
"11/25/25 09:16" |> # zde je akceptován dvoumístný rok, ale obecně se dvoumístné roky nedoporučují, jelikož mohou způsobovat zmatení
  mdy_hm() # když nespecifikujeme časovou zónu, automaticky se přidá UTC

# též funkce pro zkrácené řetězce existují
"2025-11" |> 
  ym()

# takže při generování posloupností nemusíme psát vše
# dny se v následujícím doplní samy (vždy začátek měsíce)
seq(ym("2025-01"),
    ym("2025-12"),
    "month") # kromě čísel můžeme dát slovně

# lze zadávat i celá čísla připomínající datumy
# lze tedy postupovat i bez textových řetězců, kdyby se někomu nechtělo psát uvozovky
ym(202511)

# pro specifikaci časové zóny, ještě musíme zaměstnat argument tz
"11/25/25 09:16" |> 
  mdy_hm(tz = "Europe/Prague")


# Tvorba datumů a časů z jednotlivých komponent ---------------------------

# když si vystačíme s datumem, tak využíváme make_date()
?make_date

# když potřebujeme k datumu ještě čas, tak využíváme make_datetime()
?make_datetime

# komponenty mají své názvy v argumentech
# pokud respektujeme jejich pořadí, není názvy argumentu potřeba psát
make_date(year = 2025,
          month = 11,
          day = 25)

make_date(year = 2025,
          month = 11,
          day = 25) |> 
  class()

# tady už se vyplatí zapisovat s argumenty, protože komponenty máme na přeskáčku
make_date(month = 11,
          day = 25,
          year = 2025)

# zde je možné názvy argumentů vynechat
make_date(2025,
          11,
          25)

# co se děje, když nějaké komponenty nespecifikujeme?
make_date(2025)

make_date(2025,
          11)

# vždy se vytvoří datum k začátku roku, k začátku měsíce atp.

# takto to vypadá, když k datumu máme ještě čas
make_datetime(2025,
              11,
              25,
              9,
              26,
              tz = "Europe/Prague")

make_datetime(2025,
              11,
              25,
              9,
              26,
              tz = "Europe/Prague") |> 
  class()


# Práce s datumy a časy v tabulkách ---------------------------------------

# funkcí mutate() můžeme vytvořit nové sloupce obsahující jednotlivé komponenty
nasyceni <- nasyceni |> 
  mutate(year = year(dt), # rok jsme vlastně nemuseli tvořit, jelikož jsme ho v tabulce již měli
         month = month(dt),
         day = mday(dt),
         hour = hour(dt),
         minute = minute(dt),
         second = second(dt))

# z důvodu dokázání, že v tabulce máme tyto nové sloupce schválně pro tisk vybereme funkcí select() jen důležité sloupce
nasyceni |> 
  select(obj_id,
         year:second)

# rok a vteřina jsou desetinná čísla, vše ostatní jsou celá čísla
# u roků si to lze vysvětlit např. po přidání kvartálu
# takto lze vlastně řešit i roční období, když si posuneme začátek kvartálu
nasyceni |> 
  mutate(year2 = quarter(dt, with_year = T)) |> 
  pull(year2)

# existuje i šikovná funkce odpovíající na otázku, zda byl rok přestupný
?leap_year

# když budeme chtít naopak v tabulce datumy a casy z komponent skládat, lze opět použít funkce make_date() a make_datetime()
nasyceni <- nasyceni |> 
  mutate(datum = make_date(year,
                           month,
                           day),
         cas = make_datetime(year,
                             month,
                             day,
                             hour,
                             minute,
                             second))

# přesvědčíme se, že tyto sloupce v tabulce teď skutečně máme
nasyceni |> 
  select(obj_id,
         datum,
         cas)

# časová zóna se v tabulce tradičně schovává, ale lze si ukázat, že tam je
nasyceni |> 
  select(obj_id, # tahle aplikace funkce select() tady vlastně ani není nutná
         datum,
         cas) |> 
  slice(1) |> # funkce slice() extrahuje řádky podle jejich indexu (je citlivá na grupování!)
  pull(cas)

# a když se odkážeme na sloupec, který jsme měli v tabulce od začátku, vypadá to stejně
nasyceni |> 
  slice(1) |> 
  pull(dt)


# Odbočka k funkci slice() ------------------------------------------------

# funkce slice() je jakási obdoba funkce filter()
# řádky tabulky ale vybírá s využitím indexů řádků
nasyceni |> 
  slice(1:2)

# funkce slice() je ale citlivá na grupování tabulky
# což znamená, že pokud je tabulka grupovaná vybírají se řádky dle indexů ze všech skupin
nasyceni |> 
  group_by(month) |> 
  slice(1)

# funkcí ungroup() vše napravíme, pokud nechceme řádky vybírat ze všech skupin
nasyceni |> 
  group_by(month) |> 
  ungroup() |> 
  slice(1)


# Odbočka k přestupným rokům ----------------------------------------------

# funkce leap_year() se hodí třeba k zisku počtu dnů v roce podle přestupnosti
# a tím k zisku vah podle počtu dnů v roce
nasyceni <- nasyceni |> 
  mutate(n = if_else(leap_year(make_date(year)), 366, 365))

# s rokem 2008 jsme se trefili zrovna do přestupného roku
nasyceni |> 
  select(obj_id,
         dt,
         year,
         n)

# pokud máme jen měsíční hodnoty, je dobré si počítat váhy podle počtu dnů v jednotlivých měsících v nějakém období 
tab <- tibble(datum = seq(ymd(19700101),
                          ymd(20001231))) |> 
  count(month = month(datum))

# tyto váhy pak mohou posloužit ve funkcích jako weighted.mean(), a to jak v základním pojetí, tak i ve variantě funkce z balíčku terra
tab


# Zaokrouhlování datumu ---------------------------------------------------

# v balíčku lubridate existují funkce round_date(), floor_date() a celing_date()
?floor_date

# do funkcí musíme zadávat časovou jednotku, na kterou chceme zaokrouhlovat
# bez toho se datum (čas) zaokrouhluje na vteřiny
today() |> 
  floor_date(unit = "month")

# funkce ceiling_date() dává trochu nečekaně začátek následujícího měsíce
# tento problém se dá řešit funkcemi, které probereme později
today() |> 
  ceiling_date(unit = "month")

# do naší tabulky si můžeme přidat sloupce se začátkem a koncem aktuálního měsíce
nasyceni <- nasyceni |> 
  mutate(zacatek = floor_date(datum,
                              unit = "month"),
         konec = ceiling_date(datum,
                              unit = "month"))

# prohlédneme výsledek
nasyceni |> 
  select(obj_id,
         datum,
         zacatek,
         konec)


# Trvání, období, intervaly -----------------------------------------------

# zjistěme si stáří Univerzity Karlovy v letech
# nejprve ve dnech
uk_age <- today() - ymd(13480407) # druhé datum je datum založení UK

uk_age

# funkcí as.duration() převedeme na trvání ve vteřinách (sekundách)
# přitom se v závorce dozvídáme, kolik tyto veřiny činí zhruba let
uk_age |> 
  as.duration()

# kromě možnosti převodu na trvání existují i následující funkce
dyears(700)

# takže můžeme zjistit, kolik vteřin ještě zbývá do 700. výročí UK
dyears(700) - as.duration(uk_age)

ddays(15)

ddays(14)

dhours(5)

dhours(24)

# tohle se může hodit, když potřebujeme zjistit datum 30 dnů po dnešku
# což často souvisí s termíny danými legislativou 
today() + ddays(30)

today() + ddays(525)

# tady dostáváme trochu neočekávaně i čas a časovou zónu
today() - dyears(1)

# z toho důvodu se zde ještě odlišují funkce pro období
# tyto funkce typicky vrací řetězec s označením časových komponent
days(1)

years(2)

# opět lze provádět jednoduché výpočty typu sčítání a násobení
years(2) + months(4) + days(29)

today() - years(1)

# díky tomuto si nyní můžeme opravit i konec našeho měsíce v tabulce
nasyceni <- nasyceni |> 
  mutate(konec = ceiling_date(datum,
                              unit = "month") - days(1))

nasyceni |> 
  select(obj_id,
         datum,
         zacatek,
         konec)

# i s obdobími můžeme někdy mít problémy
# toto vzniká z důvodu, že průměrný rok je nastaven na období 365.25 dnů (kvůli přestupným rokům)
years(1) / days(1)

# pokud potřebujeme délku nějakého období zjistit přesně, používáme tzv. intervaly
# zde máme speciální operátor %--%
(ymd(20230101) %--% ymd(20240101)) / days(1) # v intervalu musíme počítat s tím, že den začíná půlnocí, a tedy i limity intervalu musí být nastaveny správně


# Časové zóny -------------------------------------------------------------

# vektor názvů časových zón získáme funkcí OlsonNames()
OlsonNames() |> 
  str_subset("Tok[iy]o") # funkce str_subset() pomáhá hledat řetězec pomocí regulárního výrazu

# funkce with_tz() mění datum a čas podle časové zóny
now() |> 
  with_tz(tzone = "Asia/Tokyo")

# na rozdíl od funkce with_tz() funkce force_tz() mění jen označení časové zóny
now() |> 
  force_tz("Europe/London")


# Další speciální konstanty v R -------------------------------------------

# Eulerovo číslo (základ přirozeného logaritmu)
exp(1)

# to se liší od Eulerovy konstanty, která vystupuje ve vzorečcích extrémálních rozdělení (např. v klimatologii a hydrologii)
-digamma(1)

# již známe funkci is.na() pro hledání chybějících hodnot
?is.na

# musí však existovat i funkce is.nan() pro hledání hodnot NaN (z angl. Not a Number)
# takové hodnoty vznikají dělením nuly nulou
0 / 0

# mějme např. následující vektor celých čísel
vek1 <- -5:5

# po uplatnění tzv. recyklace máme
vek1 / 0

# funkce which() nám řekne, pro který index (pořadí prvku) máme ve vektoru pravdu
which(is.nan(vek1 / 0))

# namísto funkce is.nan() lze aplikovat i funkci is.na()
which(is.na(vek1 / 0))

# kromě toho jsme si mohli povšimnout i konstant -Inf (minus nekonečno) a Inf (plus nekonečno)
# jde o rálná čísla, takže je můžeme klasicky porovnávat
vek1 > -Inf

# pokud chceme počítat s číslem pí, je tato konstanta v R uložena jako pi
pi


# Propojování tabulek -----------------------------------------------------

# mějme metadata2, která chceme připojit k tabulce s daty
meta2

# při připojování musíme znát názvy sloupců, podle kterých chceme napojení tabulek provést (jde o tzv. klíče)
colnames(nasyceni)

colnames(meta2)

# zde tedy budeme mít jako klíče sloupce s názvem tscon_id

# tohle pak zadáváme jako argument funkce join_by(), což je poměrně nová funkce umožňující i jiné vztahy mezi klíči, než je rovnost
nasyceni <- nasyceni |> 
  left_join(meta2, # left_join() je jedna z funkcí patřících k tzv. mutating joins (přidává sloupce z připojované tabulky zprava)
            join_by(tscon_id == tscon_id))

# ověříme, zda bylo propojení provedeno
nasyceni |> 
  select(obj_id, konec:unit_ds)
