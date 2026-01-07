###
# R ve fyzické geografii
# lekce 10: Stavba statistických modelů v R na příkladu analýzy trendu
# autor: O. Ledvinka
# datum: 2026-01-06
###


# Prerekvizity ------------------------------------------------------------

# stále pracujeme v R projektu, který jsme zakládali na lekci 01
# v Classroomu máme nový RDS soubor obsahující časové řady vodní hodnoty sněhu v jednotlivých CHKO (každé pondělí se sněhem v období kalendářních let 1980-2024)
# data vznikla aplikací funkce exactextractr::exact_extract() s podkladovým rastrem reprezentujícím regresní odhady modelu náhodných lesů a vrstvy CHKO vzniklé funkcí RCzechia::chr_uzemi()
# funkce exactextractr::exact_extract() sice umí počítat přesně (a to i s vahami, viz argument weights = "area"), ale vrací nevhodný široký formát tabulky, takže bude zapotřebí zaměstnat funkci pivot_longer()
# ve zbytku skriptu se také pracuje s digitálním modelem reliéfu (dem) stahovaným z internetu pomocí RCzechia::vyskopis(), takže dobré připojení k internetu je nezbytné


# Načtení potřebných balíčků ----------------------------------------------

# schválně načteme jen několik balíčků, některé funkce budeme naopak volat konstruktem s dvěma dvojtečkami
xfun::pkg_attach2("tidyverse",
                  "RCzechia", # kvůli polygonům CHKO a dem
                  "winfapReader", # obsahuje funkci water_year() k zisku indikace hydrologického roku
                  "modifiedmk") # obsahuje funkce pro aplikace modifikovaného Mannova-Kendallova testu

# v jiném sezení (aby náhodou nevzniklo tolik konfliktů s názvy funkcí) také zkuste načíst celý metapackage tidymodels, který je určen pro modelování a strojové učení ve smyslu tidyverse
# tento metapackage s sebou přináší dalších 16 balíčků, z nichž některé se schodují s tidyverse
# studujte také význam jednotlivých balíčků, které jsou probírány v knize Tidy modeling with R (https://www.tmwr.org/) nebo přímo na stránkách https://www.tidymodels.org/


# Načtení potřebných dat a geodat -----------------------------------------

# načteme soubor swe_chko.rds, který byl dodán v Classroomu jako příloha lekce 10
# za předpokladu, že data máme ve složce R projektu s názvem 'data', můžeme načítat takto
swe <- read_rds("data/swe_chko.rds")

# pokud jsme líní psát cestu k souboru, můžeme využít i vkládání cesty nakopírované do schránky (např. přes Total Commander nebo jiného souborového průzkumníka)
# v tomto případě pomáhá funkce readClipboard() vložená dovnitř načítací funkce (ta se i stará o obrácení lomítek apod.)
swe2 <- read_rds(readClipboard())

# existuje i možnost s file.choose(), tedy funkcí, kteá otevře okénko pro hledání souboru
swe3 <- read_rds(file.choose())

# samozřejmostí je poklepání na RDS soubor v kartě Files v pravé dolní části RStudio
# zde se však nic neobjeví ve skriptu a může tedy docházet k nejasnostem, odkud se daný objekt vzal

# nepotřebné objekty z Globálního prostředí odstraňujeme funkcí rm()
rm(swe2, swe3)

# alternativně lze v RStudio v kartě Environment (vpravo nahoře) přepnout z List na Grid, označit objekty pro odstranění a klepnout na ikonu smetáčku

# pro práci na konci skriptu si bereme ještě polygony CHKO funkcí z RCzechia
chko <- chr_uzemi() |> 
  filter(TYP == "CHKO") |> 
  as_tibble() |> 
  st_sf() |> 
  select(NAZEV)

# a ještě dem, opět funkcí z RCzechia
dem <- vyskopis("actual")

# odteď bude cílem určit analýzou trendu všechna CHKO, která vykazují signifikantní trend v časových řadách zimního období let 1980-2024 (na hladině významnosti 0.05)


# Pivoting podkladových dat s vodní hodnotou sněhu ------------------------

# prohlédneme tabulku s časovými řadami
swe

# kreslicí funkce, stejně tak jako analytické funkce mají radši dlouhý formát tabulky
# takže je na řadě pivoting
# upravujeme do dlouhého formátu
swel <- swe |> # volíme nový objekt (do názvu přidáváme písmeno l, abychom naznačili, že se jedná o dlouhý formát)
  pivot_longer(cols = starts_with("mean"), # volíme všechny sloupce pro natažení na bázi jejich názvu (tzv. tydeselect)
               names_to = "dtm", # volíme název sloupce vznikajícího z původních názvů natahovaných sloupců
               values_to = "val_num", # volíme název sloupce s hodnotami
               names_prefix = "^mean\\.ymd_") |> # tímto odstraňujeme tzv. prefix, který ve sloupci 'dtm' mít nechceme (přitom je povolen regulární výraz)
  rename(nm = NAZEV) |> # volíme lepší název sloupce informujícího o příslušnosti k CHKO
  mutate(dtm = ymd(dtm)) # zbylý řetězec (po odstranění prefixu) konvertujene na skutečné datum

# prohlédneme začátek nového objektu
swel

# a také konec
swel |> 
  tail()


# Agregace do zimních období (prosinec - duben) ---------------------------

# úkolem bylo omezit se jen na období prosinec - duben
# budeme se také muset zbavit necelých zimních obobí (z okrajových let)
# na pomoc si vezmeme hydrologické roky začínající v Česku od listopadu předchozího kalendářního roku
# tímto zajistíme, že se nám zimní období neroztrhnou do dvou částí a budeme všechna mít označena hydrologickým rokem
swel_winters <- swel |> 
  mutate(hyear = water_year(dtm, # jde o funkci z winfapReader
                            start_month = 11) + 1, # autorka nesprávně označuje hydrologické roky kalendářním rokem, kdy období začíná, tak přičítáme jedničku (viz diskuzi na https://github.com/ilapros/winfapReader/issues/4)
         month = month(dtm)) |> # dodáme sloupec s měsícem
  filter(!hyear %in% c(1980, 2025)) |> # odstraníme okrajové roky, kde jsou zimní období necelá (rok 2025 vzniká posunem na hydrologické roky)
  filter(month %in% c(12, 1:4)) |> # omezíme se jen na měsíce prosinec až duben
  group_by(nm, hyear) |> # grupujeme dle CHKO a hydrologického roku ještě před sumarizací
  summarize(val_num = mean(val_num) |> # počítáme průměrnou vodní hodnotu za každé zimní období
              round(1), # zaokrouhlujeme na jedno desetinné místo, protože uvádět více desetinných míst nemá smysl (ani přístroje takto neměří)
            n = n()) |> # přidáme počty týdnů se sněhem za jednotlivé zimy, může se to hodit pro další analýzu
  mutate(row = row_number()) # kvůli regresním modelům přidáme ještě index řádky

# index řádky se mj. opakuje pro každou skupinu
# což zajišťuje právě grupování pomocí funkce group_by() - po sumarizaci zůstává grupování dle nm
swel_winters |> 
  filter(nm == "Křivoklátsko") |> 
  tail()

# kreslíme situaci
# i díky tomu jsme si převedli tabulku na dlouhý formát
ggplot(data = swel_winters,
       aes(x = hyear,
           y = val_num)) + 
  geom_point() + 
  geom_smooth(method = "lm",
              se = F) + 
  labs(title = "Trendy vodní hodnoty sněhu v CHKO",
       x = "hydrologický rok",
       y = "SWE [mm]") + 
  facet_wrap(~nm)

# v tomto obrázku je vše standardizováno, takže lze hezky průměrné velikosti vodních hodnot porovnávat

# ještě jednou, ale s uvolněným měřítkem na ose y
ggplot(data = swel_winters,
       aes(x = hyear,
           y = val_num)) + 
  geom_point() + 
  geom_smooth(method = "lm",
              se = F) + 
  labs(title = "Trendy vodní hodnoty sněhu v CHKO",
       x = "hydrologický rok",
       y = "SWE [mm]") + 
  facet_wrap(~nm, # prostudujte dokumentaci k funkci facet_wrap() a zjistěte, jak se přenastavuje počet řádků a sloupců s facetami
             scales = "free_y")

# tento obrázek má zkreslené směrnice trendů určených přímkami
# neznalí by mohli být jednoduše přesvědčeni, že jde o významné trendy (graduální změny)
# správně bychom ale měli směrnice podrobit testování hypotéz

# díle si ukážeme jak lze detekovat deterministické trendy pomocí aplikace t-testu na směrnici přímky dané lineárním modelem
# a také si ukážeme, jak se aplikuje neparametrický Mannův-Kendallův test (resp. jeho modifikace)

# dodejme ještě, že kromě funkce facet_wrap() existuje také funkce facet_grid(), která je určena k dělení facet podle dvou kategorických proměnných
?facet_grid


# Lineární modely ---------------------------------------------------------

# sestavíme lineární modely hormadně
# existují i alternativy - např. kombinace hnízdění a mapping (protože funkce map standardně vrací seznam)

# napřed si rekapitulujeme, jak vypadá tabulka v objektu swel_winters
swel_winters

# takto se rychle dá stavět lineární model pro jedno vybrané CHKO pomocí pipů
krivoklatsko <- swel_winters |> 
  filter(nm == "Křivoklátsko") |> 
  lm(val_num ~ row, # zde se jedná o tzv. formuli, která připomíná směrnicový tvar přímky (vlevo je závisle proměnná, následuje tilda a pak sada prediktorů); lepší je brát jako nezávisle proměnnou index řádku (kvůli interceptu)
     data = _) # funkce lm() má argument data, který zleva naplňujeme pipem až na druhém místě, takže musíme použít placeholder _

# kdybychom chtěli argument data vyplňovat přímo, museli bychom kód rozdělit do více částí
krivoklatsko2 <- swel_winters |> 
  filter(nm == "Křivoklátsko")

model <- lm(val_num ~ row,
            data = krivoklatsko2)

# sledujte také, jak je nyní popsána část Call při tisku u obou objektů
model

krivoklatsko

# samotný tisk modelu do konzole moc neřekne
# ale po aplikaci funkce summary() dostáváme mnohem upovídanější report
summary(model)

# nyní následuje ukázka, jak lze hromadně sestavit lineární modely pro všechna CHKO najednou
# funkcí list() zajistíme, že se výsledek vejde jako tzv. list column do nového sloupce tabulky (tabulka je mnohem přehlednější)
# funkcí pick() zajistíme, že se pro stavbu modelu budou brát jen data uvnitř skupiny (vybíráme sloupce)
swe_lmodely <- swel_winters |> 
  summarize(lmodel1 = list(lm(val_num ~ hyear, 
                              data = pick(hyear:val_num))), # modely s rokem coby prediktorem
            lmodel2 = list(lm(val_num ~ row, 
                              data = pick(c(row, val_num))))) # modely s indexem řádky coby prediktorem

# jak výsledek vypadá?
swe_lmodely

# zkuste také sestavit model pro počty týdnů v zimních obsobích se sněhem, tedy porměnnou (sloupec) n

# takto můžeme prohlížet modely jednotlivě
swe_lmodely |> 
  pluck("lmodel1", 1)

swe_lmodely |> 
  pluck("lmodel2", 2)


# Uklízení modelů ---------------------------------------------------------

# lineární model má výhodu v tom, že pro něj existuje tzv. tidy metoda
# jde o funkci tidy() z balíčku broom
# tento balíček není načten, takže v následujícím používáme broom::tidy()
# protože lineární modely máme schovány ve sloupcích, jejichž obsahem je seznam, musíme uvnitř mutate() zaměstnant funkci map()
swe_lmodely <- swe_lmodely |> 
  mutate(lmodel1_tidy = map(lmodel1, broom::tidy),
         lmodel2_tidy = map(lmodel2, broom::tidy))

# prohlédneme a vidíme, že obsahem nových sloupců jsou tabulky ukryté v seznamu
swe_lmodely

# opět se na obsah takových tabulek lze dívat pomocí funkce pluck()
swe_lmodely |> 
  pluck("lmodel1_tidy", 1)

# nyní snadno dostaneme tabulky s koeficienty ven
# vhodná je zde funkce unnest()
swe_lmodel_signif_slope <- swe_lmodely |> 
  select(nm, lmodel2_tidy) |> # vybíráme jen sloupce, které potřebujeme, ať si zbytečně nezpřehledníme situaci
  unnest(lmodel2_tidy)

# prohlédneme
swe_lmodel_signif_slope

# to ale není všechno
# zajímají nás totiž jen řádky s regresním koeficientem (směrnicí)
# a tedy filtrujeme na na term == "row" nebo na term == "hyear"
# pokud se chceme zaměřit jen na signifikatní trendy (na hladině 0.05), hledáme také zároveň řádky, kde je p-hodnota menší než 0.05
swe_lmodel_signif_slope <- swe_lmodel_signif_slope |> 
  filter(term == "row",
         p.value < 0.05)

# zjistili jsme, že z celkem 26 CHKO vykazují významný poklesový trend ve vodní hodnotě sněhu jen tři CHKO
# může ale také jít o porušení podmínek pro platnost nulové hypotézy
swe_lmodel_signif_slope

# výsledky za řádky term == "hyear" musí být stejné, protože směrnice je citlivá na diference, které jsou u hydrologických roků stejné


# Aplikace neparametrického Mannova-Kendallova testu ----------------------

# využijeme již načtený balíček modifiedmk, jehož funkce bohužel zatím nemají ekvivalentní metody pro uklízení, které má lineární model
# zde je ve finále (i hláškami) doporučováno využití funkce reframe() namísto summarize()
?summarize

# reframe totiž akceptuje více vrácených hodnot (např. vektor) na rozdíl od funkce summarize()
?reframe

# demonstrujme např. funkci mmky1lag(), která vrací výsledky pro modifikovaný Mannův-Kendallův test pro trend se zohledněním autoregresního procesu 1. řádu (původní verze testu je na tohle citlivá)
# co vše vrací funkce mmky1lag() zjistíme ze sekce Value její dokumentace
?mmky1lag

# zajímáme se o Corrected Zc, new.P.value a třeba Sen's Slope (z výstupu vybereme indexy)
swe_mk <- swel_winters |> 
  reframe(stat = mmky1lag(val_num)[c(1, 2, 7)]) # funkci mmky1lag() stačí zadávat jako jediný argument jen časovou řadu hodnot, které samozřejmě musí být správně seřazeny dle chodu času

# jednotlivé statisiky si můžeme rohodit do zvláštních sloupců
swe_mk <- swe_mk |> 
  group_by(nm) |> # tohle zajistí, že do následující funkce mutate() stačí zadat jen tři hodnoty, které indikují o jakou statistiku jde; vše se pak do dalších skupin vhodně zduplikuje
  mutate(nm2 = c("zc", "p.value", "sen")) |> 
  pivot_wider(names_from = nm2,
              values_from = stat)

# prohlédneme
swe_mk

# která CHKO vykazují dle tohoto testu významný trend?
# překvapivě se nyní ukazuje trendů více (čekali bychom snížení jejich počtu)
swe_mk |> 
  filter(p.value < 0.05)

# dodejme, že ve sloupci sen nyní máme neparametricky určený regresní koeficient (směrnici) prokládané přímky
# zc je standardizovaná testová statistika, která respektuje standardní Gaussovo rozdělení


# Tidy modelování ---------------------------------------------------------

# jedním z hlavních důvodů, proč jsme se v semestru trápili se světem balíčků tidyverse je fakt, že na něj navazuje tzv. tidy modelování
# tyto přístupy pak usnadňují používat různé modely ve smyslu strojového učení
# protože v R a jeho balíčcích je zakomponováno velké množství modelů a jejich argumenty mohou mít stejný význam, ale jsou nazvány jinak (nebo jsou na jiném místě ve funkci), rozhodli se autoři tidymodels přístupy modelování a statistického učení standardizovat

# jako příklad uveďme, jak by se pomocí tidy modelování sestavil lineární model pro Křivoklátsko (třeba i s více prediktory)
# zrekapitulujeme, jak vypadá tabulka v objektu krivoklatsko2
krivoklatsko2

# načteme metabalíček tidymodels
# teď už si troufneme s konflikty zariskovat
# kdyby náhodou nějaká dříve načtená funkce nefungovala, jak má, máme v záloze dvě dojtečky
xfun::pkg_attach2("tidymodels")

# založíme model
lm_mod <- linear_reg() |> # definice pochází z balíčku parsnip
  set_engine("lm") |> # vybíráme tzv. engine; pro lineární model můžeme vybrat i jiný, ale tenhle je základní
  set_mode("regression") # vybíráme mód (kromě regrese je v jiných typech modelů možná klasifikace atp.)

# založíme workflow, kde jednotlivé komponenty skládáme do nějakého postupu
# kromě modelu a formulky můžeme dodávat i tzv. recepty (balíček recipes), kde proměnné před fitováním modelu různě transformujeme (jedná se o tzv. feature engineering)
# ale dají se provádět různé další činnosti, jako jsou změny rolí proměnných apod.
wflow <- workflow() |> 
  add_model(lm_mod) |> 
  add_formula(val_num ~ row + n) # namísto toho lze přidávat proměnné

# teď můžeme workflow fitnout
# tohle je postup s formulkou
fit(wflow, data = krivoklatsko2) # kdybychom pracovali namísto toho s proměnnými, aplikovali bychom funkci fit_xy()

# ale u lineárního modelu máme i jednodušší možnost, bez zakládání workflow
# jde o to, že u tohoto enginu není jiný mód
lm_mod2 <- linear_reg() |> 
  set_engine("lm")

# i při fitování tohoto modelu lze volit zkratku
lm_mod2 |> 
  fit(val_num ~ row + n,
      data = krivoklatsko2)

lm_mod2 |> 
  fit(val_num ~ row + n,
      data = krivoklatsko2)|> 
  extract_fit_engine() |> # abychom si mohli zobrazit summary, jak jsme zvyklí, musíme napřed extrahovat
  summary()

# ovšem kouzlo tidy modelování je v tzv. reamplingu, výběrech trénovacích (analytických, vyhodnocovacích) a testovacích podmnožin datasetů
# silná je i náplň balíčku yardstick s velkým množstvím výkonnostních statistik
# balíček workflowsets obsahuje funkce na porovnávání různých modelů (nebo stejných s jiným nastavením)


# Lineární model s nadmořskou výškou a plochou CHKO -----------------------

# zkusme ještě nějaký složitější lineární model
# zjistěme, jak moc vysvětluje změnu v Mannově-Kendallově statistice zc následující kombinace prediktorů:
# průměrná nadm. výška CHKO + směrodatná odchylka nadm. výšky CHKO (tj. výšková členitost) + plocha CHKO
# zkusme také prediktory upravit na hlavní komponenty, abychom se zbavili tzv. kolinearity

# tyto charakteristiky si musíme nejprve odvodit
# demonstrujme sílu balíčku exactextractr
# tento balíček musíme mít nainstalovaný
char_elv <- exactextractr::exact_extract(dem, # nejprve rastr
                                         chko, # pak vektorová vrstva
                                         fun = c("mean", "stdev"), # funkcí může být více (jejich názvy ve vektoru)
                                         weights = "area", # crs není plochojevný, tak se snažíme vážit skutečnou plochou
                                         append_cols = "NAZEV") # připojujeme sloupec z vektorové vrstvy, abychom věděli, co řádky představují

# ještě plocha chko
# balíček units musí být nainstalovaný
chko <- chko |> 
  mutate(a = st_area(geometry) |> # nejprve plocha vychází v m^2
           units::drop_units()) # pro model však proměnné s jednotkami nejsou vhodné, tak je zahazujeme

# vytvořme celou podkladovou tabulku pro model
tab_chko_mod <- swe_mk |> 
  select(nm, zc) |> 
  left_join(char_elv,
            join_by(nm == NAZEV)) |> 
  left_join(chko |> 
              st_drop_geometry(),
            join_by(nm == NAZEV))

# vidíme, že potenciální prediktory máme v různých jednotkách, což není vhodné pro metodu hlavních komponent (PCA)
tab_chko_mod

# sestavíme základ lineárního modelu
chko_mod <- linear_reg() |> 
  set_engine("lm")

# nastavíme recept (manipulace s podkladovými daty)
# nejprve standardizace (normalizace), pak PCA
chko_rec <- recipe(formula = zc ~ mean + stdev + a,
                   data = tab_chko_mod) |> 
  step_normalize(all_predictors()) |> # vybíráme proměnné, které chceme standardizovat 
  step_pca(all_predictors()) # vybíráme proměnné, nad kterými chceme postavit hlavní komponenty (již ze standardizovaných hodnot)

# vše nakombinujeme do workflow
chko_wflow <- workflow() |> 
  add_model(chko_mod) |> 
  add_recipe(chko_rec)

# nakonec můžeme zkusit odhadnout parametry a získat tak nasazený model
chko_fit <- fit(chko_wflow,
                data = tab_chko_mod)

# měla celá tato činnost smysl?
# je třeba celý model signifikantní?
# je nějaký regresní koeficient signifikantní?
chko_fit |> 
  extract_fit_engine() |> 
  summary()

# vypadá to, že kombinace charakteristik nadmořské výšky a plochy CHKO přinesla spíše poznatek, že variabilitu trendů (tendencí) ovlivňuje jiný faktor
