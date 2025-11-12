###
# R ve fyzické geografii
# lekce 04: Logické vektory, čísla
# autor: O. Ledvinka
# datum: 2025-11-11
###


# Prerekvizity ------------------------------------------------------------

# platí stejné prerekvizity jako u lekce 01
# navíc se předpokládá, že pokračujeme v práci s naším R projektem založeným na začátku kurzu


# Jak vypadá logický vektor? ----------------------------------------------

# logický vektor může obsahovat maximálně tři různé hodnoty - TRUE, FALSE a NA
# tyto hodnoty můžeme skládat do vektoru pomocí funkce c()
logika <- c(TRUE,
            FALSE,
            NA,
            NA,
            TRUE)

logika

# TRUE a FALSE lze také krátit na T a F
logika2 <- c(T, F, NA, NA, T)

identical(logika, logika2)


# Načtení balíčku a příprava cvičných dat ---------------------------------

# sice bychom mohli použít načítání přes library(), ale chytřejší je následující postup
# je k tomu potřeba mít nainstalovaný aspoň balíček xfun
xfun::pkg_attach2("tidyverse")

# opět budeme pracovat se stromy, které si také opět napřed upravíme
?trees

# nejprve převedeme jednotky a hned se jich zbavíme
df <- trees |> 
  as_tibble() |> 
  janitor::clean_names() |> 
  mutate(girth = units::set_units(girth, "in") |> 
           units::set_units("cm"),
         height = units::set_units(height, "ft") |> 
           units::set_units("m"),
         volume = units::set_units(volume, "ft3") |> 
           units::set_units("m3")) |> 
  mutate(across(everything(), units::drop_units))

# tiskem do konzole ověříme, zda je vše správně
df


# Extrakce vektorů (sloupců) z tabulek ------------------------------------

# každý sloupec tabulky je vlastně vektor, takže existují i funkce, jak ze sloupců takový vektor získat
# klasicky lze vektory získat operátorem $ nebo hranatými závorkami
objem <- df$volume # zde musíme znát název sloupce

# hranaté závorky akceptují názvy i čísla
df["volume"] # protože df je třídy tibble, výsledkem je opět tibble (s jedním sloupcem)

df[, 3] # podobný příad, ale raději specifikujeme, že extrahujeme sloupec (dáváme najevo čárkou, která odděluje dimenze)

# takto pak lze získat třetí prvek z vektoru objem
objem[3]

# když napřed tibble konvertujeme zpět na data frame, získáváme specigikací indexu sloupce vektor
# pozor na toto odlišné chování!
as.data.frame(df)[, 3]

# abychom nemuseli napřed konvertovat na data frame, existuje funkce pull()
df |> 
  pull(volume)

# ta akceptuje i čísla (indexy sloupců)
df |> 
  pull(3)


# Logické vektory jako výsledek porovnávání -------------------------------

# klasicky zde využíváme operátory < (menší), <= (menší nebo rovno), > (větší), >= (větší nebo rovno), == (rovná se) a != (nerovná se)
# skutečně je rozdíl mezi = a ==
objem > 2

objem <= 0.5

# vykřičník je negace, takže hodnoty TRUE a FALSE obrací
!(objem > 2)


# Logické vektory jako výsledek Booleovy algebry --------------------------

# zde se uplatňují operátory jako & (and, a) nebo | (or, nebo)
# viz také schéma v kap. 12 knihy R4DS
objem > 2 & objem < 0.5 # & je hodně striktní (vyžaduje průnik)

objem > 2 | objem < 0.5 # naopak | se zaměřuje na sjednocení

# samozřejmě lze i negovat
!objem > 2 & objem < 0.5

# nebo porovnávat s vypočítanými statistikami z téhož objektu
objem >= median(objem)

objem <= mean(objem)

# logické vektory mají stejnou délku jako vektor, který s něčím srovnáváme
# uplatňuje se zde tzv. recyklace vektorů
length(objem)

length(objem >= median(objem))

as.numeric(objem >= median(objem))


# Sumarizační funkce, chybějící hodnoty -----------------------------------

# hodnoty TRUE lze uvažovat jako jedničky, hodnoty FALSE jako nuly
# také se tak logický vektor chová, pokud jej konvertujeme na vektor celých čísel (nebo obecně na třídu numeric)
as.integer(objem >= median(objem))

# na chybějící hodnoty se ptáme funkcí is.na()
is.na(logika)

# negace fungují také
!is.na(logika)

# protože logický vektor může být uvažován jako množina jedniček a nul (nebo hodnot NA), lze se ptát i takto
# tímto získáme absolutní četnost chybějících hodnot ve vektoru
sum(is.na(logika))

# tímto získáme podíl počtu chybějících hodnot na celkovém počtu prvků vektoru
mean(is.na(logika)) # znamená to, že ve vektoru máme 40 % chybějících hodnot


# Funkce near() -----------------------------------------------------------

# počítače mají určitou přesnost v uvádění desetinných míst
# proto se někdy může stát, že se na nějakém hodně vzdáleném desetinném místě některá čísla nebudou shodovat, i když by měla

# vytvořme matici rozměru 3 x 3 
mat <- matrix(1:9,
              ncol = 3)

# determinant matice počítáme funkcí det()
det(mat)

# determinant transponované matice
det(t(mat))

# což lze s využitím pipe operátoru přepat na toto
mat |> 
  t() |> 
  det()

# tady pak dostáváme negativní odpověď
det(mat) == det(t(mat))

# když ale použijeme funkci near(), kde můžeme nastavovat i přesnost, dostaneme odpověď, že čísla jsou si velmi blízká
near(det(mat), det(t(mat)))


# Funkce any() a all() ----------------------------------------------------

# funkcí any() se ptáme, vyskytuje-li se ve vektoru aspoň jedna hodnota pro kterou uvnitř ní vyhodnoceno TRUE
any(is.na(logika))

# funkcí all() se ptáme na všechny prvky
all(is.na(logika))

# funkce rep() opakuje nějaký prvek a staví vektor tak dlouhý, kolik udává argument times
logika3 <- rep(NA, times = 10)

# nyní již budeme mít pravdu i s funkcí all()
all(is.na(logika3))


# Význam logických vektorů v dotazech na řádky a sloupce ------------------

# raději si ponechme vektor v objektu objem stranou a vytvořme jeho kopii v objektu objem2
objem2 <- objem

# funkcí mutate tento vektor můžeme přidat do naší tabulky df jako další sloupec
# dokonce lze určovat polohu nového sloupce argumenty .before a .after (pozor, s tečkami před názvy argumentů)
df <- df |> 
  mutate(objem2 = objem2)

# pokud se spleteme a chceme tento sloupec odstranit, můžeme odstranění provést pomocí funkce select()
df <- df |> 
  select(-objem2) # negaci lze namísto znaménka - provést i znaménkem !

# odstraňovat sloupce lze i pomocí funkce mutate
df <- df |> 
  mutate(objem2 = objem2,
         objem2 = NULL)

# nahraďme si některé prvky vektoru objem2 chybějícími hodnotami
objem2[c(18, 20)] <- NA

# když budeme pokračovat s nahrazováním, staré nahrazení zůstane a přidá se další
objem2[c(3, 5)] <- NA

sum(is.na(objem2))

# přidejme si tento vektor definitivně jako nový sloupec do tabulky df
# a to i s chybějícími hodnotami
df <- df |> 
  mutate(objem2 = objem2)

# funkce filter() očekává logickou odpověď, a tedy akceptuje logické vektory
df |> 
  filter(is.na(objem2)) # vybírají se jen řádky, kde je dotazem nalezena pravda

# unvitř funkce filter() lze kombinovat
df |> 
  filter(is.na(objem2) & height > 20)

# namísto & lze psát i obyčejnou čárku
df |> 
  filter(is.na(objem2),
         height > 20)

# přidejme si sloupec s indexy řádků
df <- df |> 
  mutate(poradi = row_number())

# prozkoumejme začátek a konec tabulky
df |> 
  head()

df |> 
  tail()

# nebo klidně i celou tabulku, pokud se do konzole vejde
df |> 
  print(n = nrow(df))

# existuje i funkce View()
View(df)

# operátor %in% přichází vhod, když nechceme psát dlouhé dotazy typu 'nebo'
df |> 
  filter(poradi == 9 | poradi == 11 | poradi == 20 | poradi == 25)

df |> 
  filter(poradi %in% c(9, 11, 20, 25))

# při výběru sloupců se jistě budou hodit tyto dotazující funkce
?is.numeric

?is.integer

?is.double

?is.character

?is.factor

?is.Date

# změňme typ sloupce 'poradi' na character
# rozlišujme přitom dotazující funkce začínající na 'is.' a konvertující funkce začínající na 'as.'
df <- df |> 
  mutate(poradi = as.character(poradi))

# takto aplikujeme přirozený logaritmus na všechny nalezené numerické sloupce
# raději si necháme tabulku df stranou a zakládáme novou tabulku df2
df2 <- df |> 
  mutate(across(where(is.numeric),
                log))

# zpátky k původním hodnotám v numerických sloupcích se dostaneme aplikací inverzní funkce
df3 <- df2 |> 
  mutate(across(where(is.numeric),
                exp))

# tabulky df a df3 jsou pak stejné
df3

df


# Funkce if_any() a if_all() ----------------------------------------------

# nejsou to stejné funkce jako any() a all()
?any

?all

# jsou to příbuzné funkce across(), protože umožňují ptát se napříč sloupci
?if_any

?if_all

# s výhodou je můžeme kombinovat s funkcí filter()
df |> 
  filter(if_any(everything(), is.na))

# negací ponecháváme všechny řádky, které ani v jednom sloupci neobsahují znaky NA
df |> 
  filter(!if_any(everything(), is.na))


# Funkce if_else() a case_when() ------------------------------------------

# tohle je base-R funkce ifelse()
?ifelse

# tohle je její vylepšená varianta ze světa tidyverse
?if_else

# pomocí if_else() lze třeba nahradit všechny chybějící hodnoty nějakou naší odhadnutou hodnotou
df4 <- df |> 
  mutate(objem2 = if_else(is.na(objem2), 1, objem2)) # kde je splněna podmínka, bude nově 1, kde ne, zopakujeme hodnoty z původního sloupce objem2

# teď už ve sloupci objem2 není žádná chybějící hodnota
df4 |> 
  filter(is.na(objem2))

# case_when() je zobecněním if_else() a akceptuje více podmínek (viz kap. 12 v R4DS)
?case_when

# pomocníky ptající se na typ sloupce lze samozřejmě využít i ve funkci select()
df2 |> 
  select(where(is.character))


# Pozor na třídy čísel ----------------------------------------------------

# takto se dostaneme snadno k aritmetické posloupnosti s diferencí 1
1:9

# výsledkem je třída integer
0:9 |> 
  class()

# tohle je delší způsob, jak se k posloupnosti dostat, ale výsledkem je třída numeric
seq(from = 1,
    to = 9,
    by = 1)

seq(from = 1,
    to = 9,
    by = 1) |> 
  class()

identical(1:9,
          seq(from = 1,
              to = 9,
              by = 1))

# když k nějakému zdánlivě celému číslu přidáme pásmeni L, dáváme na vědomí, že chceme tvořit celá čísla
identical(1:9,
          seq(from = 1L,
              to = 9L,
              by = 1L))

# i takto lze docílit předchozího
identical(1:9,
          seq(from = 1,
              to = 9,
              by = 1) |> 
            as.integer())


# Funkce summarize() ------------------------------------------------------

# lze psát i summarise()
?summarize

# ukažme si význam této funkce nejprve na dlouhém formátu tabulky
df |> 
  select(1:3) |> 
  pivot_longer(cols = everything(),
               names_to = "parametr", # při pivotingu si můžeme určit naše vlastní názvy sloupců
               values_to = "val_num") |> 
  group_by(parametr) |> # vše se teď bude počítat po skupinách
  summarize(prumer = mean(val_num), # lze tvořit více statistik
            cetnost = n(),
            odchylka = sd(val_num),
            cv = sd(val_num) / mean(val_num)) # takto se lze dostat ke koeficientu variace

# existuje jiný způsob, jenom budeme mít výsledek trochu jinak uspořádaný
# tohle už je pro pokročilejší, ale je to kratší zápis
df |> 
  select(1:3) |> 
  summarize(across(everything(),
                   .fns = list(mean = mean, # funkce uzavíráme do seznamu
                               sd = sd),
                   .names = "{.col}_{.fn}")) # toto je tzv. glueing textových řetězců (inspirace nápovedou k funkci across()), povíme si o tom příště
