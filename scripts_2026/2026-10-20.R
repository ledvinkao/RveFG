###
# R ve fyzické geografii
# lekce 03b: Základy kreslení grafů ve smyslu ggplot2 - pokračování
# autor: O. Ledvinka
# datum: 2026-10-20
###


# Prerekvizity ------------------------------------------------------------

# platí obdobné předpoklady jako v předchozích lekcích
# zejména pak je velmi žádoucí mít kvalitní připojení k internetu
# může se totiž stát, že některé balíčky používaní na následujících řádcích doposud nejsou nainstalované
# některé balčky volané operátorem :: se totiž neinstalují automaticky za využizí funkce xfun::pkg_attach2()

# zároveň jsme si řekli, že na světě máme nové RStudio (zkusme doma držet krok s dobou)


# Načtení základních balíčků ----------------------------------------------

# pokud si nejsme jisti, že některé R balíčky volané na začátku sklriptu nemáme nainstalované, zvolíme funkci pkg_attach2()
# jinak stačí volat funkci pkg_attach(), přičemž víme, že abychom mohli použít operátor :: specifikovaní balíček před ním musí být nainstalovaný
# zda nám ve skriptu zůstane pkg_attach() nebo pkg_attach2(), je pak už jedno
xfun::pkg_attach2(
  "tidyverse", # klasický tidyverse
  "units", # balíček pracující s jednotkami (nastavováním, převody a zahazováním)
  "ggforce", # pomůže s kreslením ggplot2 grafů z dat, která mají jednotky
  "ggpubr" # se svou funkcí scale_regline_equation() pomůže dodat do grafu směrnicový tvar regresní přímky
)


# Změna nastavení desetinné tečky na čárku pro celé sezení ----------------

# může se hodit funkce option(), která nastavuje mnohem více, než jen desetinný znak
# pomůže kreslit grafy přiblížené českému prostředí
options(OutDec = ",")


# Funkce mutate a její význam při dodání jednotek -------------------------

# podle nápovědy, mutate() vytváří, modifikuje, nebo odebírá sloupce z tabulky
# mutate pochází z balíčku dplyr, který je základem tidyverse
?mutate

# demonstrujme na známém datasetu se stromy (střemchou pozdní)
# nejprve úprava tabulky na tibble
trees <- 
  trees |> 
  as_tibble() |> 
  janitor::clean_names() # v tidyverse se také často dbá na pravidla s názvy sloupců

# aby fungovaly předchozí řádky, musí být balíček janitor nainstalovaný
# jeho funkce clean_names() zajistí, že sloupce tabulky pak budou mít standardizované názvy
# zde byla velká písmena na začátku názvů konvertována na malá
trees

# poznámka stranou k funkci janitor::clean_names()
# zkusme vytvořit umělou tabulku s jedním sloupcem s nestandardním názvem
# tečka ještě není takový problém oproti např. mezeře, ale můžeme mít problém ji v kódu vidět
# možná nebyly zpětné uvozovky nutné, ale s mezerou už bychom je potřebovali (takové názvy mohou přicházet např. z Excelu)
tibble(`Girth.Volume` = rnorm(100)) |> # funkce rnorm() generuje (pseudo)náhodná čísla z Gaussova (normálního) rozdělení (bez specifikace argumentů standardního)
  janitor::clean_names()

# nyní nastavme jednotky podle toho, co vidíme v nápovědě
# funkce set_units() pochází z balíčku units a nastavuje jednotky poprvé, nebo čísla převádí podle přenastavení na další jednotky
trees_units <- 
  trees |> 
  mutate( # funkcí mutate() můžeme modifikovat více sloupců najednou (ale lze i rozepsat za využití více pipů)
    girth = set_units(girth, "in"), # nastavujeme palce
    height = set_units(height, "ft"), # nastavujeme stopy
    volume = set_units(volume, "ft3") # nastavujeme stopy krychlové
  )

# prohlédneme výsledek
# pod názvy sloupců se objevily námi definované jednotky
trees_units

# demonstrujme převod na jednotky SI (i tohle jsme mohli psát rovnou do předchozí funkce mutate())
trees_units_si <- 
  trees_units |> 
  mutate(
    girth = set_units(girth, "cm"), # jednotky nemusíme psát do uvozovek, ale asi je to žádoucí, abychom se nedopustili konfliku s nějakým operátorem
    height = set_units(height, "m"),
    volume = set_units(volume, "m3") # jednotky s exponenty můžeme psát se znakem ^, ale není to potřeba
  )

# docílili jsme svého?
trees_units_si


# Kreslení ggplot2 grafů s daty s jednotkami ------------------------------


ggplot(
  trees_units_si, # už jsme si dovolili vynechat názvy argumentů 'data'
  aes( # a 'mapping' (je u nich jasné, že to jsou oni, musí tu být)
    x = girth,
    y = height,
  )
) + 
  geom_point(
    aes(size = volume), # zkoušíme opět změnit velikost bodů podle třetí proměnné (musí to být zde, jinak bychom to pokoušeli zobecnit i pro následující přímku)
    col = "#0033cc" # schválně jsme si na internetu vyhledali hexadecimální kód barvy, abychom ukázali, že RStudio umí napovídat, jak barva bude vapadat
  ) + 
  geom_smooth(
    method = "lm",
    se = F,
    col = "red",
    linetype = 4 # nepamatovali jsme si slovíčko pro čerchovanou čáru, tak jsme specifikovali číslem
  ) + 
  stat_regline_equation( # přesně tato funkce pochází z balíčku ggpubr
    aes(label = str_c(..eq.label.., ..rr.label.., sep = "   ")), # oproti lekci jsem si dovolil dodat ukázku, jak zobrazit i koeficient determinace
    label.x = 36, # těmito argumenty nastavujeme souřadnice (levé části) proužku s regresní rovnicí
    label.y = 25.7, # nezapomeneme ani na osu y (v řeči čísel našich proměnných)
    output.type = "text" # tohle mi napověděla AI (nesmí to být expression, aby se korektně ukázal tvar s desetinnou čárkou pro případ češtiny); pomůže i nastavení 'latex'
  ) +
  labs( # a ještě dodáme náležité popisky
    x = "obvod kmene", # povšimněme si, že není nutné doplňovat hranaté závorky a jednotky (k jejich vykreslení dojde automaticky)
    y = "výška", # když nebudeme specifikovat např. tento český název, převezme se původní název sloupce
    size = "objem",
    title = "Závislost výšky střemchy na obvodu kmene",
    subtitle = "autor: O. Ledvinka",
    caption = "zdroj dat: R balíček datasets")


# Jak ukládat ggplot2 grafy -----------------------------------------------

# ano, existuje průvodce pro ukládání obrázků po stisknutí tlačítka Export v záložce Plots
# my ale budeme využívat funkci ggsave(), která je mnohem vhodnější a můžeme s ní kontrolovat mnohé parametry
# k argumenům viz nápovědu
?ggsave

# výhodou je, že si můžeme pomoci vytvořením ggplot2 objektu
# zde ukládáme do jediného objektu, ale mějme na paměti, že programaticky lze pak ukládat stovky i tisíce grafů (ukážeme si později)
# když tvorbu obrázku nepřiřadíme objektu a necháme namísto toho kreslit, ukládá se funkcí ggsave() posledně zobrazený graf
p1 <- ggplot(
  trees_units_si,
  aes(
    x = girth,
    y = height,
  )
) + 
  geom_point(
    aes(size = volume),
    col = "#0033cc"
  ) + 
  geom_smooth(
    method = "lm",
    se = F,
    col = "red",
    linetype = 4
  ) + 
  stat_regline_equation(
    aes(label = str_c(..eq.label.., ..rr.label.., sep = "   ")), # funkce str_c() lepí více textových řetězců najednou
    label.x = 36,
    label.y = 25.7,
    output.type = "text"
  ) +
  labs(
    x = "obvod kmene",
    y = "výška",
    size = "objem",
    title = "Závislost výšky střemchy na obvodu kmene",
    subtitle = "autor: O. Ledvinka",
    caption = "zdroj dat: R balíček datasets")

# i tento objekt p1 má své třídy
class(p1)

# nyní konečně aplikujme funkci ggsave() pro uložení grafu
# pokud není nastaven argument 'create.dir' na TRUE, může nás R při ukládání informovat, že složka neexistuje
# což může být výhodné třeba z důvodu upozornění na překlep v cestě
# jinak jsme si také řekli, že pokud zvolíme při dalším ukládání stejnou cestu, starý soubor bude přepsán
ggsave(
  filename = "obrazky/stremcha_zavislost_vysky_na_obvodu_kmene.png", # cestu uvádíme všetně přípony souboru, jestli nechceme uvádět argument 'device'
  plot = p1,
  width = 297 / 2, # pamatovali jsme si rozměry A4 v mm, tak jsme dělili dvěma, abychom dostali A5
  height = 210 / 2,
  units = "mm" # je vhodné specifikovat jednotky uvedené v šířce a výšce
)

# soubory PDF mohou s českou diakritikou trochu zlobit
# tak upřednostňujeme PNG soubory, i když nejsou vektorové
ggsave(
  filename = "obrazky/stremcha_zavislost_vysky_na_obvodu_kmene.pdf",
  plot = p1,
  width = 297 / 2,
  height = 210 / 2,
  units = "mm"
)


# Další 'geom_' funkce ----------------------------------------------------

# ukázali jsme si vliv šířky koše na 'rozporcování' numerické proměnné u 
# histogram je také jeden z typů grafů, kde specifikujeme jenom jednu osu
trees_units_si |> 
  ggplot(aes(x = volume)) + 
  geom_histogram(binwidth = 0.3)

# co se stane, když zaměníme osu x za osu y?
trees_units_si |> 
  ggplot(aes(y = volume)) + 
  geom_histogram(binwidth = 0.3,
                 color = "blue", # řekli jsme si, že 'color' (což můžeme zkrátit na 'col') značí barvu obrysu
                 fill = "green") # zatímco 'fill' značí barvu výplně

# další fukce, která napovídá o rozdělení proměnné, je geom_density()
# ta už nemá argument 'binwidth'
trees_units_si |> 
  ggplot(aes(y = volume)) + 
  geom_density(col = "blue",
               fill = "green")
