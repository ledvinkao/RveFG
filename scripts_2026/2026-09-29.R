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


# Střed -------------------------------------------------------------------

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
# zde je výsledkem vektor textových řetezců
mujobjekt <- c("kocka",
               "pes")

# zde je výsledkem vektor čísel
# všímáme si také zalamování za čárkami (ale i jinými znaky), abychom neměli řádky kódu dlouhé
mujobjekt2 <- c(
  12,
  11
)

# co se stane, 