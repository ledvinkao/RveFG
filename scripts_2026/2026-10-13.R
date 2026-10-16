###
# R ve fyzické geografii
# lekce 03: Pivoting tabulek a základy kreslení grafů ve smyslu ggplot2
# autor: O. Ledvinka
# datum: 2026-10-13
###


# Návrat k RDS souborům ---------------------------------------------------

# nejprve načítáme oba balíčky, které potřebujeme pro další práci
xfun::pkg_attach(
  "tidyverse",
  "arrow"
)

# jako příklad vezmeme opět první metadata, která jsou v Parquet souboru 'wq_water_metadata1'
meta1 <- open_dataset(
  "metadata/wq_water_metadata1"
) |> 
  collect()

# jakou další funkcí z balíčku arrow bychom mohli tento soubor načíst
# prohledejte dokumentaci balíčku arrow

# zde se podíváme, co vzniklo po aplikaci odkazu na soubor a sebrání dat funkcí collect()
meta1

# zapíšeme do RDS souboru (nemícháme malá a velká písmena v příponě)
meta1 |> 
  write_rds("outputs/meta1.rds") # složka 'outputs musí v R pojektu existovat'

# soubor zpětně načteme funkcí read_rds()
# přitom načítání trvá v závislosti na použité kompresi souboru při ukládání
# tady jsme nezvolili žádnou kompresi, ale jinak viz argument 'compress' ve funkci write_rds(), kterým můžeme velikost souboru zmenšit
meta1_nacteny <- read_rds("outputs/meta1.rds")

# jsou ve výsledném souboru (tabulce) nějaké nechtěné znaky?
meta1_nacteny


# Dočasné soubory a složky (adresáře) -------------------------------------

# podívali jsme se do nápovědy k funkcím tempfile() a tempdir()
# u tempfile() máme dokonce možnost volit příponu dočasného souboru (argumentem 'fileext')
?tempfile

# dočasné soubory se často vyskytují ve spojitosti s rastrovými daty, kdy se při výpočtech vytvářejí ve složce dané funkcí terra::terraOptions()
# specifikace přípony souboru se hodí např. při stahování geopackage


# Pivoting tabulek --------------------------------------------------------

# opět jsme si prohlédli nápovědu k funkci pivot_longer(), která je zaměřena na tvorbu dlouhých tabulek
?pivot_longer

# a také k funkci pivot_wider(), která je určena k torbě širokých tabulek

# argumentů v těchto funkcích je opravdu hodně, tak jsme se zaměřili na ty nejdůležitější

# jako příklad jsme vzali tabulku (data frame) trees, která pochází ze základního balíčku datasets
# nápověda obsahuje názvy proměnných a také info o jednotkách
?trees

# funkce as_tibble() data frame konvertuje na tibble
trees |> 
  as_tibble()

# využijme tuto funkci a pokračujme dál s přeformátováním na dlouhou tabulku
trees_long1 <- 
  trees |> 
  as_tibble() |> 
  pivot_longer(
    cols = everything(), # v argumentu 'cols' vybíráme sloupce, které se mají 'natáhnout'
    names_to = "variable", # dále určujeme názvy nových sloupců se střídajícími se (původními) názvy
    values_to = "val_num" # a 'nataženými' hodnotami
  )

# co vzniklo?
trees_long1

# objekt 'trees_long2' jsme vytvořili jen kvůli demonstraci jiného způsobu vybírání sloupců
trees_long2 <- 
  trees |> 
  as_tibble() |> 
  pivot_longer(
    cols = Girth:Volume, # tady jsme vybírali pomocí názvů sloupců a rozmezí (daným dvojtečkou)
    names_to = "variable",
    values_to = "val_num"
  )

# výsledky jsou stejné
trees_long1

trees_long2

# což by měla potvrdit i funkce identical()
identical(trees_long1, trees_long2)

# tady už jsme nový objekt netvořili
# jen jsme demonstrovali, že rozmezí sloupců lze určit i čísly jejich pořadí v tabulce
trees |> 
  as_tibble() |> 
  pivot_longer(
    cols = 1:3,
    names_to = "variable",
    values_to = "val_num"
  ) |> 
  group_by(variable) |> # po dotazu jsme ale demonstrovali význam dlouhých tabulek grupováním podle proměnné
  summarize(val_num = mean(val_num)) # počítáním průměru za dané skupiny

# když má být výdledkem sumarizační funkce vícero hodnot, používáme namísto summarize() / summarise() funkci reframe()
# reframe() bychom použili např. při zisku minim a maxim (tedy rozpětí hodnot)
trees |> 
  as_tibble() |> 
  pivot_longer(
    cols = 1:3,
    names_to = "variable",
    values_to = "val_num"
  ) |> 
  group_by(variable) |> 
  reframe(val_num = range(val_num))

# funkcí pivot_wider() se vracíme k širokému formátu
trees_wide1 <- 
  trees_long1 |> 
  pivot_wider(
    names_from = variable,
    values_from = val_num
  )

# dostáváme varování o neexistenci identifikačního sloupce
# což způsobuje, že nakonec dostaneme vektory sbalené (zahnízděné)
trees_wide1

# zahnízděné objekty můžeme 'odhnízdit' funkcí unnest()
trees_wide1 <- 
  trees_wide1 |> 
  unnest(everything()) # opět zde využíváme pomocné funkce pro výběr sloupců

# prohlédneme v konzoli, co vzniklo
trees_wide1

# co se stane, když definujeme sumarizační funkci?
trees_wide2 <- 
  trees_long2 |> 
  pivot_wider(
    names_from = variable,
    values_from = val_num,
    values_fn = mean # mean() je funkce, která je definovaná v prostředí, proto není nutné používat závorky a ani zástupné proměnné
  )

# toto je vlastně jeden ze způsobů, jak získat průměry za skupiny bez nutnosti tabulku natahovat do dlouhého formátu
# nefunguje však vždy (musí být zaručena tendence hnízdit)
trees_wide2

# existují ale i tzv. anonymní funkce, které tvoříme přímo v kódu bez jejich ukládání do prostředí
trees_long2 |> 
  pivot_wider(
    names_from = variable,
    values_from = val_num,
    values_fn = function(x) { # postaru jsme tyto funkce uvozovali slovíčkem 'fnction', dnes namísto něj postačuje zpětné lomítko (na české klávesnici zadáme zkratkou AltGr+Q)
      sd(x) / mean(x)
    }
  )

# tady de facto počítáme variační koeficient pro všechny proměnné, tj. směrodatnou odchylku podělenou průměrem
trees_long2 |> 
  pivot_wider(
    names_from = variable,
    values_from = val_num,
    values_fn = \(prokocku) { # zástupnou proměnnou (zastupuje všechny tři proměnné) si můžeme pojmenovat jakkoliv:-)
      sd(prokocku) / mean(prokocku)
    }
  )


# Základy kreslení ve smyslu ggplot2 --------------------------------------

# balíček ggplot2 je součástí základního tidyverse, takže jej nemusíme načítat znovu (je již načtený)
# kreslení vždy zahajujeme funkcí ggplot() a dále pokračujeme geometrickými funkcemi (jejich názvy začínají na 'geom_')
# dále pak sledujeme strategii nabalování funkcí (operátorem +) naznačenou v taháku ke kreselní (viz https://rstudio.github.io/cheatsheets/html/data-visualization.html)
ggplot() # tato funkce jen založí jakési plátno, ale i zde již můžeme definovat 'mapping' funkcí aes(), kterou předchází odkaz na tabulku v argumentu 'data'

# jakmile určíme data a mapping, optimalizují se rozsahy (obecně měřítka) na osách

# k funkcím určujícím, jak se data budou vykreslovat náleží např.
?geom_boxplot

?geom_point

?geom_line

?geom_col

?geom_density

?geom_histogram

# a mnoho dalších, které ani nemusí být v základním balíčku ggplot2
# v balíčku tidyterra máme např. funkci geom_spatraster() pro vykreslování rastrových vrstev (třídy SpatRaster)
?tidyterra::geom_spatraster

# budeme vycházet ze známé tabulky trees
ggplot(
  data = trees # definovali jsme data pro všechny následující funkce a je na nás, zda mapping vložíme sem nebo ho budeme specifikovat někde dále (pak máme mapping více pod kontrolou)
) + 
  geom_point( # zvolili jsme vykreslení pomocí bodů (tzv. scatterplot)
    mapping = aes( # často se v kódu cizích vyskytuje jen aes(), jelikož je jasné, že jde o mapping
      x = Girth, # určujeme, co bide na ose x
      y = Height # a co bude na ose y (schválně jsem nezvolil objem, protože jsem se nechtěl zdržovat s jednotkami s exponentem)
    ),
    size = 1, # specifikace velikosti bodů je zde mimo funkci aes(), což znamená, že pro všechny body bude stejná
    col = "darkolivegreen" # s barvou mimo aes() je to podobné; tady podotýkám, že není nutné pamatovat is jejich názvy (lze si i z iternetu vypůjčit hexadecimální kód atp.)
  )

# co se však stane, vložíme-li např. argument 'size' do funkce aes() a přiřadíme mu třetí proměnnou?
ggplot(
  data = trees
) + 
  geom_point(
    mapping = aes(
      x = Girth,
      y = Height,
      size = Volume
    ),
    col = "darkolivegreen"
  )

# třetí proměnnou často bývá kategorická proměnná (v řeči R faktor)
# pokud budeme potřebovat ze spojité (numerické) veličiny udělat kategorickou, můžeme si ji rozsekat na intervali pomoci funkce cut()
?cut

# zde je příklad s mappingem uvedeným rovnou v počáteční funkci ggplot()
# tento postup se hodí, nechceme-li se zdržovat s definicí mappingu v následujících funkcích a chceme jej mít všude stejný
ggplot(
  data = trees,
  mapping = aes(
    x = Girth,
    y = Height
  )
) + 
  geom_point(
    size = 1,
    col = "darkolivegreen"
  ) + 
  geom_smooth() # zde jsme ještě přidali funkci pro proložení dat křivkou (standardně se křivka tvoří metodou loess)

# pokračujeme dále a soustředíme se na argumenty funkce geom_smooth()
# rovněž tak si graf popíšeme
ggplot(
  data = trees,
  mapping = aes(
    x = Girth,
    y = Height
  )
) + 
  geom_point(
    size = 1,
    col = "darkolivegreen"
  ) + 
  geom_smooth(
    method = "lm", # lze specifikovat i jinou metodu pro vyrovnávání (prokládání)
    col = "red", # samozřejmě si můžeme zvolit jinou barvu čáry
    linetype = "dotted", # pro typ čáry existují i číselné kódy
    se = FALSE, # tímto se zbavíme pásů okolo přímky, které jsou dány standardní chybou koeficientů
    linewidth = 1.5 # nastavujeme jinou tloušťku čáry
  ) + 
  labs(
    x = "obvod kmene [in]", # popisujeme osu x (jednotky jsme vzali z nápovědy k datasetu trees)
    y = "výška stromu [ft]", # popisujeme osu y
    title = "Závislost výšky na obvodu kmene", # volíme název grafu
    subtitle = "autor: O. Ledvinka", # volíme podnázev grafu
    caption = "data: R balíček datasets" # caption se standardně píše vpravo dole (hodí se třeba pro určení zdroje dat)
  ) + 
  scale_x_continuous(limits = c(5, 25)) # funkce, jejichž název začíná na 'scale_' jsou určené pro přenastavení měřítek; zde např. rozmezí na numerické ose x

# pak by mohla následovat některá z funkcí, jejichž název začíná na 'coord_'
# tyto funkce přenastavují souřadnicový systém
# existuje zde např. coord_radial(), která z kartézského systému tvoří polární (aniž bychom se zdržovali s výpočty radiánů apod.)
?coord_radial

# geografové jistě ocení funkci coord_sf()
?coord_sf

# ta nastavuje jiný souřadnicový referenční systém (crs) při kreslení statických map

# zkuste se na závěr poradit s AI, co by doporučila, kdybychom chtěli k regresní přímce dodat směrnicový tvar regresní rovnice
