###
# R ve fyzické geografii
# lekce 01: Základy práce v R a v IDE RStudio, nápovědy k funkcím a klávesové zkratky
# autor: O. Ledvinka
# datum: 2025-09-29
###


# Začátek -----------------------------------------------------------------

# řekli jsme si něco k instalaci R a RStudio (nebo také RTools) a k aktualizaci
# odteď si nebudeme plést pojmy R (hnací motor) a RStudio (integrované vývojářské prostředí, IDE)

# řekli jsme si, že není vhodné zadávat na řádku více hashtagů (ve smyslu komentování)
# jinak by vznikla nepojmenovaná sekce

# naučili jsme se tedy komentovat (zadáváním hashtagu na začátku řádky)
# přitom hashtag vložíme na české klávesnici kombinací kláves ALTGR + X
# větší bloky po označení komentujeme klávesovou zkratkou CTRL + SHIFT + C

# naučili jsme se také v R skriptu zakládaném zkratkou CTRL + SHIFT + N zakládat sekce pro přehlednost
# sekce se zakládají zkratkou CTRL + SHIFT + R a napsáním názvu sekce
# mezi sekcemi lze pak jednoduše přepínat


# Střed - R balíčky, citace, funkce, nápovědy -----------------------------

# budeme probírat balíčky metabalíčku tidyverse

# balíčky načítáme základní funkcí library()
library(tidyverse) # lze nebo nemusíme název mít v uvozovkách

# pokud chceme načíst více balíčků najednou, funkce library() se od nějakého množství již nevyplácí
# můžeme namísto toho využít funkci pkg_attach() z balíčku xfun, kde se předpokládá, že všechny potřebné balíčky jou nainstalované
# pokud chceme využít pouze jednu funkci z nějakého balíčku (nebo balíček specifikovat), používáme konstrukt s ::
xfun::pkg_attach( # existuje i varianta pkg_attach2(), která v případě absence balíčku navíc instaluje
  "tidyverse",
  "writexl" # pro ukládání do XLSX souborů
)

# po startu R jsme zjistili, že existuje funkce citation()
# ta se chová podle toho, zda necháme závorky prázdné (cituje R), nebo napíšeme název balíčku (citujeme balíček)
citation()

citation("tidyverse")

citation("dplyr")

# nápovědu k funkcím lze získat najetím kurzoru na název funkce a následným stisknutím klávesy F1
# sledujme jednotlivé sekce dokumentace k funkcím (které argumenty funkce má) a hlavně se zaměřujme na výstupy (Values)
# typ výstupu předznamenává možnost aplikace další funkce, která vyžaduje určitý typ objektu

# objekty zakládáme napsáním vymyšleného názvu, za kterým píšeme přiřazovací operátor <- (zkratka ALT + -)
# tento vymyšlený název se pak objeví v pravém horním okně prostředí RStudio (v tzv. Globálním prostředí)
# zde je výsledkem vektor textových řetezců
mujobjekt <- c("kocka",
               "pes")

# zde je výsledkem vektor čísel
# všímáme si také zalamování za čárkami (ale i jinými znaky), abychom neměli řádky kódu dlouhé
mujobjekt2 <- c(
  12,
  11
)

# poznamenejme, že i nepatrné písmeno c následované oblými závorkami znamená funkci
# funkcí c() skládáme prvky (většinou stejného typu) do vektoru

# co se stane, propojíme-li ve vektoru prvky různých typů?
mujobjekt3 <- 
  c(
    11, 
    "kocka"
  )

# objekt můžeme vytisknout do konzole pouhým napsáním našeho názvu (a spuštěním kódu např. zkratkou CTRL + ENTER)
mujobjekt3

# vidíme, že z čísla 11 se stal textový řetězec
# což poznáme podle toho, že kolem tohoto čísla se objevily uvozovky při výpisu v konzoli


# Konec - význam pipe operátoru -------------------------------------------

# v současnosti je již k dispozici tzv. nativní pipe operátor |> 
# znamená to, že pro jeho využívání nepotřebujeme žádné další přídavné balíčky
# chceme-li se však vrátit ke staršímu operátoru, píšeme buď %>% nebo si v Tools/Global Options.../Code odznačíme vkládání nativního pipu
# pro vkládání pipe operátoru (jakého, záleží na našem nastavení) pak slouží zkratka CTRL + SHIFT + M

# zápisy kódu s pipe operátorem usnadňují orientaci v kódu
# určitě minimalizuje problémy s velkým počtem závorek (nebo s neuzavřením některé závorky)
# práci s pipe operátory si lze představit jako práci se složenými funkcemi v matematice, kdy postupně vyhodnocujeme na sebe závislé operace

# můžeme tedy jednak psát toto bez pipe operátoru
str_subset( # funkce pochází z balíčku stringr (součásti tidyverse) a umožňuje hledat text podle tzv. regulárních výrazů (viz https://r4ds.hadley.nz/regexps.html)
  mujobjekt,
  "^k" # stříškou v textu (v uvozovkách) na začátku se omezujeme na řetězce, které začínají nějakým znakem
)

# nebo za využití pipe operátoru můžeme psát toto
mujobjekt |> 
  str_subset("^k")

# těchto pipe operátorů můžeme klidně využít hned několik za sebou
# to nás zbavuje povinnosti si stále zakládat nějaké objekty jako mezičlánky
mujobjekt |> 
  str_subset("^k") |> 
  str_length() # funkce str_length() také pochází z balíčku stringr a zjišťuje počet znaků v řetězci

# nedoporučuje se však využívat více jak 10 až 15 pipů, abychom pak mohli snadněji nacházet chyby v kódu (viz https://r4ds.hadley.nz/workflow-style.html)


# Bonus - lineární model --------------------------------------------------

# ukátali jsme, jak vkládat další časté znaky pomocí klávesových zkratek (viz také https://github.com/ledvinkao/RveFG/tree/66535f372acf5d05a37a4e682027b907870a89c9/klavesove_zkratky)
# avšak pozastavili jsme se u znaku ~ (tilda)
# tento znak se využívá v tzv. furmulích, které jsou základem stavby statistických modelů

# využijme např. vestavěného datasetu 'trees' a sestavme linární model, kterým se pokusíme vysvětlit proměnnou Girth v závislosti na proměnných Height a Volume

# přesvědčíme se, že dataset skutečně existuje jeho pouhým vytištěním do konzole
trees

# postavme model
model <- 
  lm(
    Girth ~ Height + Volume, # tilda vlastně nahrazuje znak = ve směrnicovém tvaru regresní rovnice
    data = trees # musíme specifikovat tabulku, která obsahuje proměnné, na které se ve formuli odkazujeme
  )

# a sledujme vlastnosti tohoto modelu
model

# mnohem upovídanější je kombinace s funkcí summary()
summary(model)
