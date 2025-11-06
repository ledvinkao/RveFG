###
# R ve fyzické geografii
# lekce 03: Základy kreslení grafů ve smyslu ggplot2
# autor: O. Ledvinka
# datum: 2025-11-04
###


# Prerekvizity ------------------------------------------------------------

# platí stejné prerekvizity jako u lekce 01
# navíc se předpokládá, že pokračujeme v práci s naším R projektem založeným na začátku kurzu


# Počáteční načtení balíčků -----------------------------------------------

# kromě metabalíčku tidyverse nebudeme žádný další balíček načítat celý
# přesto ale tidyverse načteme způsoběm vhodným pro načítání více balíčků najednou
# při načítání metabalíčku tidyverse se ve skutečnosti načte 9 balíčků, které tvoří jádro tidyverse
# jedním z těchto balíčků je i ggplot2, takže jsme na kreslení grafů dobře připraveni
xfun::pkg_attach2("tidyverse")

# budeme potřebovat ještě pár funkcí z balíčku units a janitor
# klidně se podíváme na jejich dokumentaci
?janitor::clean_names

?units::set_units

?units::drop_units


# Dataset pro cvičení -----------------------------------------------------

# dataset trees přichází se základem R, takže není nutné načítat a shánět žádná další data
# takto zjistíme popis datasetu, včetně seznamu tří sloupců a jednotek, ve kterých jsou proměnné naměřeny
# co znamenají jednotlivé sloupce? jaké proměnné reprezentují?
?trees

# každý datový rámec (data frame) lze zkoumat i z hlediska dimenzí
# pro počet sloupců máme
trees |> 
  ncol()

# pro počet řádků máme
trees |> 
  nrow()

# pro obě dimenze máme
trees |> 
  dim()

# cílem teď bude uklidit (resp. vyčistit) si názvy sloupců a převést si jednotky z imperiálních na SI 

# nejprve převod na tibble a uklízení názvů sloupců
# mezitím zakládáme nový objekt df
df <- trees |> 
  as_tibble() |> 
  janitor::clean_names()

# prohlížíme
df

# nyní je na řadě převod jednotek
# zde využijeme šikovnou funkci mutate() a vybranou funkci balíčku units
# pro jistotu raději zakládáme nový objekt (abychom si předchozí práci nepřepsali)
df2 <- df |> 
  mutate(girth = units::set_units(girth, "in") |> # nejdříve nastavíme původní jednotky
           units::set_units("cm"), # pak převádíme
         height = units::set_units(height, "ft") |> # opakujeme pro další proměnné
           units::set_units("m"),
         volume = units::set_units(volume, "ft3") |> 
           units::set_units("m3"))

# protože funkce určené ke kreslení grafů ve smyslu ggplot2 mají většinou problém se sloupci s přiřazenými jednotkami, můžeme se jednotek nyní zbavit
# pomocníci across() a everything() umožňují funkci mutate() provést jednu operaci najednou pro všechny sloupce
df2 <- df2 |> 
  mutate(across(everything(), units::drop_units))

# prohlédneme
df2


# Začínáme kreslit --------------------------------------------------------

# naprostým základm je funkce ggplot()
?ggplot

# takto se vykreslí jen šedivý rámeček
ggplot()

# takto se již nastaví i rozsahy os podle výběru proměnných z tabulky a podle jejich pořadí ve funkci aes()
# dva hlavní argumenty funkce ggplot() jsou data (definuje tabulku se sloupci reprezentujícími proměnné) a mapping (definuje tzv. aestetics vždy funkcí aes())
ggplot(data = df2,
       mapping = aes(x = girth,
                     y = height))

# aby se vůbec něco vykreslilo uvnitř šedivého pole, musíme vybrat reprezentaci nějakou funkcí definující geometrii
# takové funkce vždy začínají na 'geom_'
# řekněme, že budeme chtít kreslit tzv. scatterplot (XY bodový graf)
# k tomu slouží funkce geom_point()
?geom_point

ggplot(data = df2,
       mapping = aes(x = girth,
                     y = height)) + # další vrstvy přidáváme operátorem + (pozor! odlišujeme od pipe operátoru |> )
  geom_point() # bez nastavení ničeho dalšího se kreslí černé body

# existuje i výhodná funkce zobrazující vyrovnávající křivky
ggplot(data = df2,
       mapping = aes(x = girth,
                     y = height)) + 
  geom_point() + 
  geom_smooth() # bez nastavení ničeho dalšího dostaneme tzv. LOESS křivku

# takto měníme křivku na regresní přímku (s parametry odhadnutými lineárním modelem)
ggplot(data = df2,
       mapping = aes(x = girth,
                     y = height)) + 
  geom_point() + 
  geom_smooth(method = "lm")

# takto se zbavujeme pásu nejistoty parametrů křivky daného standardní chybou (standard error, ve zkratce 'se')
ggplot(data = df2,
       mapping = aes(x = girth,
                     y = height)) + 
  geom_point() + 
  geom_smooth(method = "lm",
              se = F)

# proměnné můžeme i prohodit (přiřadíme je osám x a y opačně)
ggplot(data = df2,
       mapping = aes(x = height,
                     y = girth)) + 
  geom_point() + 
  geom_smooth(method = "lm",
              se = F)

# ještě by to chtělo nějaké popisky
# k tomu zde dobře slouží funkce labs(), kterou oeprátorem + přidáme za geometrii
?labs

ggplot(data = df2,
       mapping = aes(x = girth,
                     y = height)) + 
  geom_point() + 
  geom_smooth(method = "lm",
              se = F) + 
  labs(title = "Závislost výšky na obvodu kmene u střemchy pozdní", # hlavní titulek (název grafu)
       subtitle = "autor: O. Ledvinka", # podtitulek (podnázev grafu)
       caption = "zdroj: R balíček datasets", # info o zdrojích (i autorství zde může být)
       x = "obvod [cm]", # nastavení popisu osy x
       y = "výška [m]") # nastavení popisu osy y


# Export vytvořených grafů do souboru -------------------------------------

# v případě balíčku ggplot2 zde máme na ukládání do souborů funkci ggsave()
?ggsave

# pokud nespecifikujeme argumemt plot (tedy odkud se má brát zdroj), je automaticky ukládán poslední zobrazený graf v kartě Plots
# je žádoucí do názvu souboru uvádět i příponu, čímž se specifikuje driver pro uložení
ggsave(filename = "obrazky/stremcha_pozdni_zavislot_vysky_na_obvodu.pdf", # narazili jsme také na to, že v názvu nesmí být dvojtečka (pokud se nám tam náhodou objeví, soubor pak uložen není)
       height = 148, # zkusili jsme rozměry A5, ale na šířku
       width = 210,
       units = "mm") # nezapomínat na jednotky, ve kterých uvádíme čísla výšky a šířky!

# pokud se nám nelíbí ukládání posledních obrázků, lze si zdroj pohlídat tak, že si obrázek uložíme do objektu
# tento objekt pak slouží pro specifikaci argumentu plot
p1 <- ggplot(data = df2,
             mapping = aes(x = girth,
                           y = height)) + 
  geom_point() + 
  geom_smooth(method = "lm",
              se = F,
              col = "red") + # zde jsme poprvé ukázali, že si můžeme manuálně nastavit barvu geometrie, jako je zde regresní přímka
  labs(title = "Závislost výšky na obvodu kmene u střemchy pozdní",
       subtitle = "autor: O. Ledvinka",
       caption = "zdroj: R balíček datasets",
       x = "obvod [cm]",
       y = "výška [m]")

# nyní uložíme s argumentem plot
# raději soubor nepřepisujeme a volíme trochu jiný název
ggsave(filename = "obrazky/stremcha_pozdni_zavislot_vysky_na_obvodu_s_cervenou_primkou.pdf",
       height = 148,
       width = 210,
       units = "mm",
       plot = p1)

# proveďme ještě jedno uložení, tentokrát i se změnou tloušťky čáry
p2 <- ggplot(data = df2,
             mapping = aes(x = girth,
                           y = height)) + 
  geom_point() + 
  geom_smooth(method = "lm",
              se = F,
              col = "red",
              linewidth = 1.5) + # pozor! píšeme desetinná čísla v anglickém prostředí, takže žádné desetinné čárky!
  labs(title = "Závislost výšky na obvodu kmene u střemchy pozdní",
       subtitle = "autor: O. Ledvinka",
       caption = "zdroj: R balíček datasets",
       x = "obvod [cm]",
       y = "výška [m]")

ggsave(filename = "obrazky/stremcha_pozdni_zavislot_vysky_na_obvodu_s_tlustou_cervenou_primkou.pdf",
       height = 148,
       width = 210,
       units = "mm",
       plot = p2)


# Další argumenty měnící vzhled geometrie ---------------------------------

# kromě barvy a tloušťky čáry, můžeme nastavovat typ symbolů, jehich velikot, ale i výplň (kde je to možné)
ggplot(data = df2,
       mapping = aes(x = girth,
                     y = height)) + 
  geom_point(pch = 24, # body měníme na trojúhelníky s možností vyplňování jejich vnitřku
             fill = "green", # manuálně měníme výplň trojůhelníků
             size = 1.5, # manuálně nastavujeme velikost symbolů
             col = "darkblue") + # tohle mění barvu ohraničení trojúhelníků
  geom_smooth(method = "lm",
              se = F,
              col = "red",
              linewidth = 1.5,
              linetype = 3) + # u čar lze měnit i jejich typ (namísto čísel lze používat i akceptovaná slova)
  labs(title = "Závislost výšky na obvodu kmene u střemchy pozdní",
       subtitle = "autor: O. Ledvinka",
       caption = "zdroj: R balíček datasets",
       x = "obvod [cm]",
       y = "výška [m]")

# ggplot akceptuje i klasické názvy argumentů, jako je např. lwd (pro linewidth) a lty (pro linetype)
df2 |> # data (tabulka) mohou jít do funkce ggplot() i pomocí pípe operátoru
  ggplot(aes(x = girth, # odteď se také odnaučíme psát zbytečná slova při kreslení; např. fakt, že specifikujeme data a mapping, je naprosto zřejmý
             y = height)) + 
  geom_point(pch = 24,
             fill = "green",
             size = 1.5,
             col = "darkblue") + 
  geom_smooth(method = "lm",
              se = F,
              col = "red",
              linewidth = 1.5,
              linetype = 3) + 
  labs(title = "Závislost výšky na obvodu kmene u střemchy pozdní",
       subtitle = "autor: O. Ledvinka",
       caption = "zdroj: R balíček datasets",
       x = "obvod [cm]",
       y = "výška [m]")

# pokud je argument měnící tvar, barvu, výplň apod. uzavřen ve funkci aes(), lze tímto měnit vlastnost geometrie automaticky podle nějaké další proměnné
df2 |> 
  ggplot(aes(x = height,
             y = girth)) + 
  geom_point(pch = 24,
             fill = "green",
             aes(size = volume), # lokální nastavení aes() přepisuje globální nastavení aes() z funkce ggplot()
             col = "darkblue") + 
  geom_smooth(method = "lm",
              se = F,
              col = "red",
              linewidth = 1.5,
              linetype = 3) + 
  labs(title = "Závislost výšky na obvodu kmene u střemchy pozdní",
       subtitle = "autor: O. Ledvinka",
       caption = "zdroj: R balíček datasets",
       x = "obvod [cm]",
       y = "výška [m]",
       size = "objem [m3]")

# pokud se nám nelíbí automatické nastavování těchto vlastností, existuje pokročilejší nastavování měřítek pomocí funkcí 'scale_'
?scale_fill_manual # touto funkcí můžeme manuálně nastavovat výplně
?scale_size_manual # touto funkcí můžeme manuálně nastavovat velikosti
# atp. (existují i přídavné balíčky přidávající další podobné funkce s měřítky)


# Histogramy a hustoty ----------------------------------------------------

# zásadní je funkce geom_histogram()
ggplot(df2,
       aes(x = volume)) + # povšimněte si, že zde potřebujeme nastavit jen jednu osu
  geom_histogram(binwidth = 0.3, # velmi dležitý je argument bindwidth nebo jeho obdoba (určuje šířku intervalu, do kterého se vejde nějaká četnost našich spojitých dat)
                 col = "black", # i zde lze ladit ohraničení a výplně sloupců
                 fill = "purple")

# funkce geom_density() jako by přehodí přes sloupce histogramu dlouhou špagetu
ggplot(df2,
       aes(x = volume)) + 
  geom_density(col = "darkolivegreen", # i tyto vlastnosti lze u grafu měnit
               fill = "green",
               linewidth = 2,
               alpha = 0.2) + # alpha je průhlednost od největší (0) do žádné (1)
  theme_bw() # zde se seznamujeme s funkcí, která přenastaví podklad podle nějaké přednastavené šablony (tady theme_bw() pro 'black and white')

# podklad také nemusí být žádný
ggplot(df2,
       aes(y = volume)) + # osy lze prohodit
  geom_density(col = "darkolivegreen",
               fill = "green",
               linewidth = 2,
               alpha = 0.2) + 
  theme_void() # tohle se hodí, když si nejprve chceme vytvořit sadu tzv. grafických objektů (tzv. grobů), které pak třeba budeme chtít lokalizovat v tematické mapě


# Krabicové grafy (boxploty) a předpříprava tabulky -----------------------

# krabicové grafy jsou jedním z nejužívanějších nástrojů pro zkoumání rozdělení spojitých veličin
# naše tabulka ale neodpovídá tomu, co při hromadném kreslení takových grafů potřebujeme
# tady pomůže pivoting tabulky z širokého formátu na dlouhý (viz Quarto text k lekci 02)

# následující dva způsoby výběru sloupců pro natažení do dlouhého formátu mají totožný efekt
# nové sloupce 'name' a 'value' se pojmenovávají automaticky, ale lze to změnit (viz argumenty funkce pivot_longer())
df3 <- df2 |> 
  pivot_longer(cols = girth:volume)

df3

df3 <- df2 |> 
  pivot_longer(cols = everything())

df3

# pokud se rozhodneme objekt z globálního prostředí odstranit, lze to udělat funkcí rm() (zřejmě její název pochází z angl. 'remove')
rm(df3)

# raději jsme namísto toho založili objekt dfl (abychom věděli, že se jedná o dlouhý formát)
dfl <- df2 |> 
  pivot_longer(cols = everything())

# každá proměnná má jiné měřítko (jiné jednotky, jiné rozsahy apod.)
# je tedy vhodné proměnné standardizovat a dostat je na stejné měřítko
# pro tento účel lze využít funkci mutate(), která reaguje i na grupování pomocí funkce group_by()
dfl <- dfl |> 
  group_by(name)

# co se stalo, když jsme tabulku grupovali podle proměnné name?
# jak se změnil tisk tabulky do konzole?
dfl

# využijeme standardizaci odečtením průměru mean() a dělením rozdílu smerodatnou odchylkou sd()
#protože máme tabulku grupovanou, berou se v úvahu průměry a odchylky proměnné value za tyto skupiny
dfl <- dfl |> 
  mutate(val_stand = (value - mean(value)) / sd(value)) |> 
  mutate(presvedceni1 = mean(val_stand), # zde jde jen o přesvědčení, že mám skutečně průměr nulový
         presvedceni2 = sd(val_stand)) # a směrodatnou odchylku jedničkovou

# nevrací se nic, protože všechny hodnoty ve sloupci presvedceni1 jsou blízké nule
# zde již trochu začínáme s logickými vektory a s funkcí filter() pro výběry řádků tabulky
dfl |> 
  filter(!near(presvedceni1, 0)) # vykřičník je negace; raději používáme k porovnání funkci near(), protože někdy se na počítači díky limitované přesnosti místo nul ukazují čísla velmi blízká nule, která ve skutečnosti mají také znamenat nulu

# pro krabicové grafy existuje funkce geom_boxplot()
ggplot(dfl,
       aes(x = name,
           y = val_stand)) + 
  geom_boxplot(col = "darkolivegreen") + # opět můžeme nastavovat barvu ohraničení a výplně
  labs(x = "", # tohle děláme, když nebudeme chtít zobrazovat popisek nějaké osy
       y = "rozdělení val_stand")


# Facety ------------------------------------------------------------------

# když už máme v jednom grafu zobrazených hodně proměnných, začíná problém s nepřehledností grafů
# řešení formou tzv. facet využívá rozdělení grafu do více grafů podle nějaké kategorické proměnné - funkce facet_wrap(), nebo podle více takových proměnných - funkce facet_grid()
# tuto rozdělující proměnnou uvádíme např. ve funkci facet_wrap() za tildou ~
ggplot(dfl,
       aes(x = name,
           y = val_stand)) + 
  geom_boxplot(col = "darkolivegreen") + 
  labs(x = "",
       y = "rozdělení val_stand") + 
  facet_wrap(~name)

# graf vypadá celkem dobře, ale ještě by to něco chtělo
# když máme nahoře v panelu specifikovanou rozdělující proměnnou, není třeba ji mít specifikovanou i dole v ose 
# navíc by bylo vhodné v panelech jaksi centrovat
# z následujícího kódu se dozvídáme, jak tohoto všeho docíli
ggplot(dfl,
       aes(x = name,
           y = val_stand)) + 
  geom_boxplot(col = "darkolivegreen") + 
  labs(x = "",
       y = "rozdělení val_stand") + 
  facet_wrap(~name,
             scale = "free_x") + # uvolněním měřítka na ose x jednotlivé panely centrujeme
  theme(axis.text.x = element_blank(), # zbavujeme se textu u osy x
        axis.ticks.x = element_blank()) # zbavujeme se výběžků z osy


# Jiné --------------------------------------------------------------------

# pak tu máme spoustu dalších funkcí pro jiné typy grafů
# ke konstrukci sloupcových grafů slouží funkce geom_bar()
?geom_bar

# dalšími důležitými argumenty v 'geom_' funkcích jsou argumenty 'position' a 'stat'
# blíže viz kap. 1 knihy R4DS (https://r4ds.hadley.nz/data-visualize.html)

# zajímavé jsou i funkce pro práci se souřadnicovým systémem
# zde se dozvídáme, že namísto coord_radial() již máme používat výhradně coord_polar()
?coord_radial
