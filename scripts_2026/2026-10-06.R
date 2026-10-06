###
# R ve fyzické geografii
# lekce 02: Základy práce s externími daty
# autor: O. Ledvinka
# datum: 2025-10-06
###


# Prerekvizity ------------------------------------------------------------

# ukázali jsme si, jak v RStudio zakládat tzv. R projekty
# založení R projektu je velmi důležité hned z několika důvodů
# patří sem používání relativních cest k souborům, ale třeba i lepší uspořádání podkladů pro práci
# a to včetně historie (zapamatování 10 naposledy otevřených R projektů)

# vedle toho jsme si v rychlosti ukázali další nastavení RStudio (Appearance apod.)
# také jsme si vysvětlili, že existují soubory .R, .Rhistory, .RData nebo třeba také .RDS (či .rds)
# řekli jsme si, že na .RData zapomeneme a, pokud možno, z nastavení RStudio odstraníme jejich ukládání (ptaní se na ně) a načítání


# Nahrávání Apache Parquet souborů ----------------------------------------

# jeden z nejmodernějších typů souborů s daty, který lze uchovávat bez nutnosti obsluhovat databázi, je Apache Parquet
# práce s ním (nebo sadou souborů) ale práci s databází připomíná
# výhodou těchto souborů je, že nezatěžují RAM pracovní stanice
# namísto toho se prostřednictvím objektu, který se na soubor (soubory) odkazuje, soustředíme pouze na podmnožinu dat

# že pracujeme s odkazem na soubor dlící v souborovém systému zjistíme tak, že se v pravém horním rohu konzole objeví zelená ležatá osmička v kroužku

# základní balíček, který nám dopomůže pracovat s Parquet soubory, je 'arrow'
# jinak existuje více balíčků, jejichž funkce s Parquet soubory pracují

# načteme tedy základní balíčky pro naší práci
xfun::pkg_attach2( # když balíčky nejsou nainstalovány, používáme funkci pkg_attach2()
  "tidyverse", # zde musíme používat uvozovky!
  "arrow"
)

# balíček 'arrow' obsahuje samozřejmě více funkcí
# my se zaměříme na funkci open_dataset(), která zakládá odkaz na soubor
# při odkazování se na soubor dbáme na správnou cestu
# zde musí podsložka 'metadata' již existovat (jinak ji založíme) a musí obsahovat Parquet soubor z Classroomu
# díky tomu, že jsme v R projektu, se lze odkazovat relativně
meta1 <- open_dataset("metadata/wq_water_metadata1") |> # zajímavostí je, že se stačí odkázat na složku s Parquet souborem
  collect() # tato funkce sbírá všechna data do RAM (u metadat si to můžeme dovolit, u časových řad to již není doporučeno)


# Vylepšený datový rámec - tibble -----------------------------------------

# dataset se stromy, který jsme tu měli minulou lekci, je obyčejný datový rámec
# což zjistíme např. funkcí class()
trees |> 
  class()

# funkcí as_tibble() dodáme datovému rámci další třídy
# a vzniká tak regulérní tibble objekt
trees <- 
  trees |> 
  as_tibble()

# jaké jsou dvě přidané třídy?
trees |> 
  class()

# jak vypadá tisk takového tibble objektu do konzole?
trees

# tisk se liší od obyčejného datového rámce
# vidíme lépe třeba typy sloupců a tiskne se jen podmnožina (záčátek) tabulky

# také naše metadata se načetla jako tibble
meta1


# Prohlížení začátků a konců tabulek --------------------------------------

# v základu exitují funkce head() a tail()
# které mají v nastaveních ovšem nějaký limit zobrazených řádků
# např. 25 řádků standardně nefunguje
meta1 |> 
  tail(25)

# ale např. 15 řádků funguje
meta1 |> 
  head(15)

# když budeme naslouchat našeptávání pod tiskem objektu tibble v konzoli, zjistíme, že existuje funkce print()
# tato funkce se ale chová trochu jinak než funkce head()
# pod tiskem totiž ukazuje, kolik řádků ještě v tabulce zbývá
# a tohle u funkce head() nemáme
meta1 |> 
  print(n = 20)


# Vyvolání nápovědy funguje i v komentářích -------------------------------

# po stisknutí klávesy F1 na názvu funkce funguje v RStudio i v komentářích
# funkce však musí existovat
# tail()


# Třídy lze zjišťovat funkcí class() i u vektorů --------------------------

# sloupce tabulky jsou vlastně vekory
# vektor ze sloupce tabulky získáme např. operátorem $
meta1$stream_name # název sloupce musí samozřejmě existovat (hranaté závorky v konzoli vlevo značí, o kolikátý prvek vektoru jde)

# následně lze aplikovat funkci class() pro zjištění třídy
meta1$stream_name |> 
  class()


# Zápis a načtení XLSX souborů --------------------------------------------

# jedny z nejlepších balíčů v současnosti jsou z tohoto pohledu balíčky 'writexl', 'readxl' a 'openxlsx'
# balíček 'writexl' a jeho funkce jsou určeny pro zápis dat do XLSX souborů
writexl::write_xlsx(meta1, # musíme minimálně zadat z čeho chceme zapisovat
                    "outputs/metadata1.xlsx") # a kam chceme zapisovat (podložka 'outputs' musí existovat)

# balíček 'readxl' a jeho funkce slouží k načítání XLSX a XLS souborů
# takto načteme právě uložený soubor 'metadata1.xlsx'
meta1b <- readxl::read_xlsx("outputs/metadata1.xlsx")

# prohlédneme a zjistíme, zda se všechny sloupce načetly se správným typem
meta1b

# zde jsme měli štěstí, ale problémy mohou nastat (nejčastěji asi s datumy a časy)


# Zápis a načtení textových souborů ---------------------------------------

# nejčastější jsou zřejmě CSV (comma-separated values) a TXT soubory
# CSV soubory se středníky se užívají pouze tam, kde by mohlo dojít k záměně s desetinnou čárkou
# základní funkcí pro zápis je zde write_delim(), pro načtení naopak 'read_delim()'
?write_delim # otazník před názvem funkce na začátku řádku je alternativou k zobrazení dokumentace pomocí F1

?read_delim

# další funkce, jako jsou read_csv(), read_csv2() nebo read_tsv(), jsou odvozeny
# i tak ale mají velké množství argumentů pro ladění locale apod.
# argumenty se lze učit za pomoci nástroje Import Dataset (najdeme v pravém horním rohu v kartě Environment)

# využijme např. funkci write_delim() pro zápis metadatové tabulky do CSV souboru
write_delim(meta1,
            "outputs/metadata1.csv", # příponu souboru musíme specifikovat
            delim = ";") # tímto napodobíme východoevropský typ souboru (tedy CSV2)


# Rozdíl mezi základními (base) a tidyverse funkcemi ----------------------

# kromě fukcí typu read_csv() se setkáme také s funkcemi typu read.csv() (s tečkou místo podtržítka)
# důvod proč v tidyverse existují protější base funkcí je ten, že autoři potřebovali tzv. vektorizované funkce
# vektorizovaných funkcí se pak využívá v tzv. funkcionálním programování
