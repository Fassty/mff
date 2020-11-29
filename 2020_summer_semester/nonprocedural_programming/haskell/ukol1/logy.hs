import Data.List
type Castka = Int

data Operace
  = Prihlaseni
  | Odhlaseni
  | Vyber Castka
  | Pripis Castka
  deriving (Show, Read, Eq)

type Cas = Int

type Uzivatel = String

data Zaznam =
  Zaznam Cas
         Uzivatel
         Operace
  deriving (Show, Read, Eq)

type Zaznamy = [Zaznam]

main = do
  log <- (map read . lines <$> readFile "banka.log") :: IO [Zaznam] --nacteni a rozparsovani logu
  let result cmt f --pomocna funkce na vypisovani vysledku
       = do
        putStrLn (cmt ++ ":")
        print (f log)
        putChar '\n'
  {- pocitani a vypisovani vysledku zacina zde -}
  result
    "DEMO1 -- jmeno prvniho uzivatele v souboru se smichanymi zaznamy"
    demoPrvniZaznam
  result
    "DEMO2 -- pocet zaznamu se jmenem Marie"
    demoPocetMarie
  result "Seznam uzivatelu serazenych podle abecedy" serazeniUzivatele
  result "Casy top 10 nejvetsich vyberu" top10vyber
  result "Jmena uzivatelu 10 nejmensich pripisu" top10pripis
  result "Nejaktivnejsi uzivatel" topUzivatel
  result "Uzivatel ktery vydelal nejvic penez" topPrirustek
  result "BONUS: Prumerna vybrana castka uzivatelu zacinajicich od J" prumerVyberuJ
  result
    "BONUS: Uzivatel s nejdelsi posloupnosti akci nerusenou v logu jinymi uzivateli"
    nejdelsiSingleRun

uzivatel :: Zaznam -> String
uzivatel (Zaznam _ x _) = x

vyber :: Zaznam -> Maybe (Castka,Uzivatel,Cas)
vyber (Zaznam t u (Vyber c)) = Just (c,u,t)
vyber _ = Nothing

pripis :: Zaznam -> Maybe (Castka,Uzivatel,Cas)
pripis (Zaznam t u (Pripis c)) = Just (c,u,t)
pripis _ = Nothing

-- příklad 1: Jméno uživatele prvního záznamu v logu
demoPrvniZaznam :: Zaznamy -> Uzivatel
demoPrvniZaznam ((Zaznam _ jm _):_) = jm

-- příklad 2: Počet záznamů se jménem Marie
demoPocetMarie :: Zaznamy -> Int
demoPocetMarie = length . filter uzivatelMarie
  where
    uzivatelMarie (Zaznam _ "Marie" _) = True
    uzivatelMarie _ = False
-- ekvivalentně:
-- demoPocetMarie zaznamy = length $ filter uzivatelMarie zaznamy
-- nebo:
-- demoPocetMarie zaznamy = length (filter uzivatelMarie zaznamy)

{- Ukol zacina tady. Misto `undefined` dodejte definice funkci, ktere z logu
 - vytahnou pozadovany vysledek. -}

-- Seznam uživatelů (bez duplicit), seřazený podle abecedy
serazeniUzivatele :: Zaznamy -> [Uzivatel]
serazeniUzivatele seznam = (nub . sort) uzivatele
  where
    uzivatele = map uzivatel seznam

-- Časy deseti největších výběrů
top10vyber :: Zaznamy -> [Cas]
top10vyber seznam = take 10 [ t | Just (c,u,t) <- serazeny ]
  where
   serazeny = sortBy (flip compare) (map vyber seznam)

-- Jména uživatelů, kterým přišlo deset nejmenších přípisů (bez opakování jmen)
top10pripis :: Zaznamy -> [Uzivatel]
top10pripis seznam = nub $ take 10 [ u | Just (c,u,t) <- serazeny ]
  where
    serazeny = sort (map pripis seznam)

compFunc (Zaznam _ a _) (Zaznam _ b _) = compare a b
-- Jméno uživatele, který je nejaktivnější (tj. má v logu nejvíc záznamů)
topUzivatel :: Zaznamy -> Uzivatel
topUzivatel seznam = snd $ maximumBy (\(a, _) (b, _) -> compare a b) [(length x, head x) | x <- uzivatele]
  where
    serazene = sortBy compFunc seznam
    sjednocene = groupBy (\(Zaznam _ x _) (Zaznam _ y _) -> x == y) serazene
    uzivatele = [map uzivatel x | x <- sjednocene]


prijem :: Zaznam -> (Castka,Uzivatel)
prijem (Zaznam _ u (Pripis c)) = (c,u)
prijem (Zaznam _ u _) = (0,u)

vydaj :: Zaznam -> (Castka,Uzivatel)
vydaj (Zaznam _ u (Vyber c)) = (c,u)
vydaj (Zaznam _ u _) = (0,u)

secti :: [(Castka,Uzivatel)] -> Castka
secti arr = sum $ map fst arr

-- Jméno uživatele, kterému na účtu přibylo nejvíc peněz (tj. má maximální součet příjmů mínus součet výdajů)
topPrirustek :: Zaznamy -> Uzivatel
topPrirustek seznam = snd $ maximumBy (\(a, _) (b, _) -> compare a b) celkem
  where
    serazene = sortBy compFunc seznam
    sjednocene = groupBy (\(Zaznam _ x _) (Zaznam _ y _) -> x == y) serazene
    balance = [ (map prijem x, map vydaj x) | x <- sjednocene ]
    celkem = [ ((secti x - secti y), (snd . head) x) | (x,y) <- balance]


zacinaNaJ :: (Castka,Uzivatel) -> Bool
zacinaNaJ os = (head . snd) os == 'J'

averageInt xs = fromIntegral (secti xs) / fromIntegral (length xs)
-- BONUS: Průměrná částka (oříznutá na celé číslo), kterou vybrali uživatelé začínající od J
-- prumerVyberuJ :: Zaznamy -> Castka
prumerVyberuJ seznam = floor $ averageInt norm
  where
    vydaje = map vydaj seznam
    naJ = filter zacinaNaJ vydaje
    norm = filter (\(x, y) -> x /= 0) naJ

time (Zaznam a _ _) (Zaznam b _ _) = compare a b
-- BONUS: Jméno uživatele, který provedl nejvíc akcí za sebou bez toho, aby jakýkoliv jiný uživatel cokoliv udělal (tj. po seřazení logu podle času bude mít “nejvíc řádků po sobě”)
--nejdelsiSingleRun :: Zaznamy -> Uzivatel
nejdelsiSingleRun seznam = snd $ maximumBy (\(a, _) (b, _) -> compare a b) delky
  where
    serazene = sortBy time seznam
    sjednocene = groupBy (\(Zaznam _ x _) (Zaznam _ y _) -> x == y) serazene
    delky = [ (length x, head $ map uzivatel x) | x <- sjednocene ]
