###
# R ve fyzické geografii
# lekce 04: ggplot2 motivy a panely; logické vektory
# autor: O. Ledvinka
# datum: 2026-10-27
###


# Prerekvizity ------------------------------------------------------------

# předpokládá se opět co nejdovější verze R a jeho balíčků
# stejně tak se předpokládá co nejnovější verze IDE RStudio
# je zapotřebí kvalitní připojení k internetu, protože se očekává stahování a instalace dalších přídavných balíčků
# a to i ze sítě GitHub

# ukázali jsme si, že kromě v nastaveních RStudio lze instalační repozitáře kontrolovat v souboru .Rprofile
# balíček usethis obsahuje funkce, které nám snadno umožní otevřít tento soubor
# lze zde např. nastavovat obecný CRAN repozitář "https://cloud.r-project.org/"
# ten zajistí, že se balíčky instalují z nejbližšího zrcadla CRAN, když jsme někde v zahraničí
# k ostatním repozitářům patří např. R-Universe (můžeme zde najít balíčky, které na CRAN už jako aktivní nenajdeme)
usethis::edit_r_profile()

# kromě toho balíček usethis pomáhá s editací souboru .Renviron
usethis::edit_r_environ()

# ke korektnímu otevření editace souborů .Rprofile a .Renviron však potřebujeme mít správně definovaný textový editor v operačním systému

# abychom mohli demonstrovat následující kód, potřebujeme nainstalovat balíček ThemePark, jehož zdroje se však nachází pouze na GitHub
# k instalaci balíčku z GitHub slouží funkce balíčků devtools nebo remotes
# na OS Windows je samozřejmostí mít nainstalovaný nástroj RTools, aby se zdrojový kód mohl zkompilovat
# instalujme tedy balíček ThemePark např. takto:
remotes::install_github("MatthewBJane/ThemePark")


# Načtení balíčků pro demonstraci motivů a panelů ggplot2 -----------------

# některé balíčky upotřebíme i v sekci o logických vektorech

# stejně ale raději zvolíme k načítání dalších balíčků pkg_attach2()
# může se totiž stát, že budeme muset instalovat chybějící balíčky i z CRAN
xfun::pkg_attach2(
  "tidyverse",
  "units",
  "ggforce",
  "ggthemes", # asi nejznámější balíček dodávající další funkce 'theme_' pro finální motivy grafů ggplot2
  "ThemePark" # balíček jsme právě nainstalovali
)


# Příprava základu pro demonstraci motivů a panelů ------------------------

# vezmeme opět dataset se stromy, který přichází s R rovnou, a není tedy potřeba nic dalšího instalovat
trees <- 
  trees |> 
  as_tibble() |> 
  janitor::clean_names() |> 
  mutate(
    girth = set_units(girth, "in") |> 
      set_units("cm"),
    height = set_units(height, "ft") |> 
      set_units("m"),
    volume = set_units(volume, "ft3") |> 
      set_units("m3")
  )

# definujme základ
# uložme si ho zámerně do objektu p1
p1 <- 
  ggplot(
    trees,
    aes(
      x = girth,
      y = height
    )
  ) + 
  geom_point(
    aes(size = volume),
    col = "darkolivegreen"
  ) + 
  geom_smooth(
    method = "lm",
    se = F,
    linetype = 4,
    linewidth = 1,
    col = "red"
  ) + 
  labs(
    title = "Závilost výšky střemchy pozdní na obvodu kmene",
    subtitle = "autor: O. Ledvinka",
    caption = "zdroj dat: R balíček datasets",
    x = "obvod kmene",
    y = "výška",
    size = "objem"
  )


# Demonstrace ggplot2 motivů (themes) -------------------------------------

# nejprve několik ukázek s nativními funkcemi balíčku ggplot2
# jde o tzv. kompletní motivy (themses)
p1 + 
  theme_bw()

p1 + 
  theme_void()

p1 + 
  theme_grey() # lze psát i theme_gray() kvůli rozdílnému spellingu v UK a US angličtině

p1 + 
  theme_light()

p1 + 
  theme_minimal()

# následují ukázky s motivy nabízenými balíčkem ggthemes
# tento balíček je na CRAN
p1 + 
  theme_base()

# často zde máme motivy nějakých novin nebo časopisů
p1 + 
  theme_economist()

# obecnou funkcí je však theme() z ggplot2
# takže i jejím prostřednictvím můžeme přenastavit nějaký detail
p1 + 
  theme_economist() + 
  theme(
    axis.text.x = element_blank() # touto pomocnou funkcí jsme odstranili čísla u osy x
  )

# konečně demonstrujme motiv z balíčku ThemePark
p1 + 
  theme_terminator()

# mějme ale na paměti, že zvolené písmo ne vždy musí podporovat českou diakritiku
# přičemž ladění detailů přes theme() zde postrádá smyls, protože právě chceme napodobit písmo z filmu a mohli bychom o něj přijít
# pak nezbývá, než spokojit se s angličinou


# Aktualizace motivů ------------------------------------------------------

# theme_set(), nebo se slovíčky v obráceném pořadí set_theme() přenastavuje motiv celého sezení
# tj. jde  všechno, co od její aplikace bude zobrazováno
# zde nepoužíváme ani +, ani |>
theme_set(theme_minimal())

# zobrazme
p1

theme_set(theme_bw())

# zobrazme
p1

# theme_update(), neboli update_theme() pak dolaďuje nějakou drobnost
theme_update(
  axis.text.x = element_blank()
)

# zobrazme
p1


# Panely grafů (facety) ---------------------------------------------------

# panely se nejčastěji tvoří tak, že jeden velký graf roztrhneme podle nějaké nebo několika kategorických proměnných
# v naší tabulce trees tedy potřebujeme nějakou takovou proměnnou vytvořit
# rovněž tak vadí jednotky, tak je zahodíme
# raději si tvoříme novou proměnnou
trees <- 
  trees |> 
  mutate(
    volume2 = drop_units(volume) |> 
      cut_number(n = 4) # přesně této funkci rozdělující proměnné do intervalů (a pocházející z ggplot2) jednotky vadí
  )

# podívejme se, jaké kategorie (resp. intervaly) zde teď máme
trees |> 
  pull(volume2) |> # funkcí pull() získáme vektor z daného sloupce tabulky
  levels()

# nyní již můžeme ukázat sílu facet
# odhlédněme nyní od objektu p1, kde je objem využit pro velikost bodu
ggplot(
  trees,
  aes(
    x = girth,
    y = height
  )
) + 
  geom_point(
    col = "darkolivegreen",
    size = 1
  ) + 
  geom_smooth(
    method = "lm",
    se = F,
    col = "red",
    linetype = 4,
    linewidth = 1
  ) + 
  facet_wrap(~volume2, # funkce akceptuje tildu a název proměnné, podle které chceme graf dělit; můžeme si dokonce diktovat, kolik má být řádků a kolik sloupců
             labeller = label_both, # zde jsme použili pojmenovanou funkci label_both(), aby se ukázal název třetí proměnné
             nrow = 4 # oproti HTML prezentaci jsme si ještě ukázali, že máme pod kontrolou i rozložení panelů (lze povolit i měřítka na osách atp.)
  ) +
  labs(
    title = "Závislost výšky střemchy pozdní na obvodu kmene",
    subtitle = "autor: O. Ledvinka",
    caption = "zdroj dat: R balíček datasets",
    x = "obvod kmene",
    y = "výška"
  )

# funkce facet_grid() pak umožňuje dělit velký graf podle dvou proměnných
# pro obrázky viz např. https://sape.inf.usi.ch/quick-reference/ggplot2/facet.html
?facet_grid


# Logické vektory ---------------------------------------------------------

# důvod, proč bychom měli rozumět logickým vektorům a Booleovské algebře, je především tidyverse funkce filter()
# tato funkce pochází z balíčku dplyr
?filter

# k logickým vektorům existuje celá kapitola 12 knihy R for Data Science
# viz https://r4ds.hadley.nz/logicals.html
# zde najdeme i vysvětlení operátorů Booleovské algebry i prostřednictvím diagramů

# upravme si naši tabulku se stromy s pomocí funkce mutate(), kterou již známe
# nepotřebujeme proměnnou 'volume2', tak ji zahodíme úplně
# další proměnné pomocí across() uvnitř mutate() vybereme najednou (např. rozmezím) a aplikujeme na ně funkci drop_units()
# protože jednotky jsou nyní nežádoucí
trees2 <- 
  trees |> 
  mutate(volume2 = NULL,
         across(girth:volume, drop_units))

# záměrně jsme si vytvořili nový objekt
# podívejme se, co v tabulce máme nyní
trees2

# dále si objem z tabulky uložíme jako vektor do dalšího objektu
objem <- trees2 |> 
  pull(volume) # v tidyverse je doporučována funkce pull(), protože hranaté závorky se chovají jinak u objektů tibble, než jak se chovají u data frame

objem

# alternativě lze vektor extrahovat dolárkem, když známe název sloupce
trees2$volume

# jinak pull() akceptuje i kladná nebo záporná celá čísla (viz dokumentaci)

# končně ukažme, že když se octneme v zajetí pipů, lze si pomoci i anonymní funkcí
trees2 |> 
  as.data.frame() |> # převod na data frame volíme, aby zafungovaly hranaté závorky
  (\(x) x[, "volume"])() # zde lze psát namísto názvu proměnné i její číslo pořadí v tabulce

# ptejme se nyní nějakými srovnávacími operátory jako je >, >=, <, <=, == (rovná se), či != (nerovná se)
objem < 2 # nepravdu máme jen u posledního prvku

# přitom vykřičník ! je negace

# kromě porovnávání může logickými vektory končit i operace s logickými operátory
# např. & znamená 'a' (průnik), | znamená 'nebo' (sjednocení), ale existuje i xor pro vyloučení průniku ve sjednocení

# aplikujme logické vektory uvnitř funkce filter()
trees2 |> 
  filter(objem < 2) # vybere všechny až na poslední řádek, tedy všechny řádky, kde jsme uvnitř funkce filter() dostali TRUE 

# namísto & lze ve funkci filter() použít pouhou čárku, pokud potřebujeme podmínky kombinovat na více sloupcích
trees2 |> 
  filter(objem < 2,
         height > 20)

# ukázka s negací (z TRUE se stává FALSE a z FALSE se stává TRUE)
trees2 |> 
  filter(!(objem < 2)) # vybraný je pouze poslední řádek
