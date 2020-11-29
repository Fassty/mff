-- Author: Martin Pilat
-- Date: 9. 5. 2017
-- Updated: 18. 5. 2020

------------------------------------------------------------------------------
--          5. cviceni -- Haskell - monady
------------------------------------------------------------------------------

-- # Haskell - monady

-- V Haskellu jde pouzivat i typy, ktere se v jinych jazycich vyjadruji tezko 
-- napr. se v nich pouzivaji specialni hodnoty (jako treba `null`). Uzitecny typ 
-- je `Maybe a`, ktery muze obsahovat bud hodnotu typu `a` (`Just a`), nebo nic 
-- (`Nothing`). Udelejme si jeho klon (pouzijeme cestinu, abychom nekolidovali s 
-- vestavenym).

data Mozna a = Proste a | Nic deriving (Show)

-- Tento typ nam umozni nadefinovat funkci i tam, kde normalne definovana neni,
-- proste v tech pripadech vratime `Nothing` (nebo `Nic` v nasi definici).

-- Muzeme treba napsat tzv. bezpecny logaritmus nebo bezpecnou odmocninu.

safeLog :: Double -> Mozna Double
safeLog x   | x <= 0    = Nic
            | otherwise = Proste (log x)

safeSqrt :: Double -> Mozna Double
safeSqrt x  | x < 0     = Nic
            | otherwise = Proste (sqrt x)

-- Co kdybychom chteli spojit odmocninu a logaritmus? Spocitat bezpecne odmocninu
-- logaritmu nejakeho cisla?

safeSqrtLog :: Double -> Mozna Double
safeSqrtLog x = f (safeLog x)
            where
                    f Nic           = Nic
                    f (Proste x)    = safeSqrt x

-- Typ `Mozna` se muze hodit i v jinych pripadech, napr. kdyz chceme napsat funkci,
-- ktera hleda nejaky prvek v seznamu, a pokud ho najde, tak vrati jeho index. 
-- Pokud ho nenajde, muze klidne vratit `Nic`. Bez typu `Mozna` by musela vracet 
-- nejakou zvlastni hodnotu (treba -1), nebo vyhodit vyjimku.

najdi :: Eq a => [a] -> a -> Mozna Int
najdi xs x = najdi' xs x 0  -- pocitame od 0
    
najdi':: Eq a => [a] -> a -> Int -> Mozna Int
najdi' [] _ _                   = Nic
najdi' (x:xs) y  n  | y == x    = Proste n
                    | otherwise = najdi' xs y (n+1)

-- Podobnym zpusobem muzeme napsat i bezpecne verze funkci, ktere normalne vyhazuji
-- vyjimku, pokud se jim neco nelibi (napr. `head` a `tail` na prazdnem seznamu).

safeHead :: [a] -> Mozna a
safeHead [] = Nic
safeHead xs = Proste (head xs)

safeTail :: [a] -> Mozna [a]
safeTail []     = Nic
safeTail (_:xs) = Proste xs

-- Napiste ted funkci, ktera vyhleda v seznamu `xs` prvek, ktery je na prvnim miste
-- v seznamu `ys`. Pouzijte nase bezpecne funkce.

najdiPrvni:: Eq a => [a] -> [a] -> Mozna Int
najdiPrvni xs ys = f xs (safeHead ys)
                where   f xs (Proste y) = najdi xs y
                        f _ Nic         = Nic

-- Spojovani funkci, ktere vraci `Maybe` (nebo `Mozna`) je trochu skarede, ale 
-- mohla by se dat napsat funkce, ktera ho udela obecne?

-- Napiste funkci `lbind`, ktera dostane funkci `a -> Mozna b` a hodnotu typu 
-- `Mozna a` a vrati `Mozna b`, tj. spoji funkce dohromady podobne, jako `(.)` 
-- spojuje normalni funkce.

lbind::(a->Mozna b)->Mozna a -> Mozna b
lbind f Nic         = Nic
lbind f (Proste y)  = f y

-- Nas bezpecny logaritmus odmocniny se pak da napsat jako

lbSafeSqrtLog x = lbind safeSqrt (safeLog x)

-- A co nase vyhledani prvniho prvku? To je malicko slozitejsi, protoze najdi je 
-- binarni funkce, ale neni to nic nezvladnutelneho.

lbNajdiPrvni xs ys = lbind (najdi xs) (safeHead ys)

-- Pokud bychom chteli, aby slozeni bylo podobnejsi obvyklemu skladani, muzeme 
-- vyuzit infixovou notaci

lbSafeSqrtLog' x = safeSqrt `lbind` safeLog x

-- Podobne samozrejme muzeme napsat totez pro nase hledani prvniho prvku.

-- Pokud budeme pouzivat vestavene `Maybe`, muzeme pouzit i vestaveny `lbind` 
-- operator `(=<<)`.

mSafeLog :: Double -> Maybe Double
mSafeLog x  | x <= 0    = Nothing
            | otherwise = Just (log x)
            
mSafeSqrt :: Double -> Maybe Double
mSafeSqrt x | x < 0     = Nothing
            | otherwise = Just (sqrt x)
            
mSafeSqrtLog x = mSafeSqrt =<< mSafeLog x

-- S pomoci tohoto bind musime cist funkce zprava doleva, lepe se cte naopak, ale 
-- ani to neni problem naprogramovat.

-- Pracujme zase s nasim typem `Mozna`, pak si totez ukazeme na standardnim 
-- `Maybe`.

-- Napisme si tedy vlastni `rbind`, ktery bude parametry brat v opacnem poradi nez 
-- `lbind`.

rbind :: Mozna a -> (a -> Mozna b) -> Mozna b
rbind x f = lbind f x

rbSafeSqrtLog :: Double -> Mozna Double
rbSafeSqrtLog x = safeLog x `rbind` safeSqrt

-- Operator `(>>=)` je obdobou naseho `rbind` operatoru pro standardni typ `Maybe`.

rmSafeSqrtLog :: Double -> Maybe Double
rmSafeSqrtLog x = mSafeLog x >>= mSafeSqrt

-- Tento zapis muzete take cist tak, ze se napred aplikuje bezpecny logaritmus na 
-- `x` a potom teprve bezpecna odmocnina na vysledek. Trochu to zacina pripominat 
-- proceduralni programovani.

-- Haskell ve skutecnosti ma specialni syntaxi, ktera proceduralni programovani 
-- pripomina jeste o neco vic.

dSafeSqrtLog :: Double -> Maybe Double
dSafeSqrtLog x = do 
            y <- mSafeLog x
            mSafeSqrt y

-- Tento zapis ma pripominat to, ze do `y` se ulozi mezivysledek a ten se potom o 
-- radek dal aplikuje, ale ve skutecnosti jde porad jen o ten samy vypocet jako 
-- jsme videli pred chvili. Cela `do` konstrukce je jen syntakticky cukr.

-- Obcas se hodi do retezu funkci, ktere vraci `Mozna a`, pridat i nejakou funkci, 
-- ktera vraci jen `a`. Potom se nam hodi funkce, ktera prevede `a` na `Mozna a`. 
-- Teto funkci, se rika `return`, my ji budeme rikat `vrat` a jeji implementace je 
-- jednoducha.

vrat :: a -> Mozna a
vrat x = Proste x

-- Kdyz mame takovou funkci, muzeme snadno napsat treba soucet bezpecne odmocniny 
-- a bezpecneho logaritmu.

dSafeLogPlusSqrt x = do
        y <- mSafeLog x
        z <- mSafeSqrt x
        return (y + z)

-- Rikali jsme, ze `do` notace je jen syntakticky cukr. Jak se ale da horni vyraz 
-- prepsat bez ni? (pro pokrocile Haskellisty, nemusite umet)

mSafeLogPlusSqrt = (\x -> mSafeLog x >>= (\y -> mSafeSqrt x >>= (\z -> return (y+z))))

-- Vsimnete si postupneho skladani funkci, k pojmenovani `y` (odpovidajici `y <-`) 
-- dojde az uvnitr druhe anonymni funkce. K pojmenovani `z` jeste o kousek dal. 

-- Nas typ `Mozna` se od `Maybe` porad malicko lisi. Napr. tim, ze pro nej nemuzeme
-- pouzivat `do` notaci, takze napsat pomoci nej predeslou funkci by bylo trochu 
-- neprehledne

safeLogPlusSqrt = (\x -> safeLog x `rbind` (\y -> safeSqrt x `rbind` (\z -> vrat (y+z))))

-- Pokud chceme pouzivat do notaci i pro nas typ `Mozna`, je potreba rict, ze
-- `Mozna` patri do tridy `Monad`, ta je od verze GHC 7.10 (brezen 2015) 
-- automaticky ve tride `Applicative` (ktera sama je podtrida tridy `Functor`). 
-- Je tedy treba jeste napsat instance pro `Applicative Mozna` a `Functor Mozna`.

instance Functor Mozna where
    fmap f Nic        = Nic
    fmap f (Proste a) = Proste (f a)
 
-- Funkce `fmap` je zajimava sama o sobe, umoznuje nam vzit funkci, ktera pracuje
-- s beznymi typy a aplikovat ji treba na typ `Mozna`. Napriklad, kdyz chceme k 
-- `Just 1 (::Mozna Int)` pricist cislo `3 (::Int)`, napiseme `fmap (+3) (Just 1)` 
-- a dostaneme vysledek `Just 4`.

instance Applicative Mozna where
    pure             = vrat
    Nic        <*> _ = Nic
    (Proste f) <*> m = fmap f m
 
-- Funkce `pure` by mela zadanou hodnotu zabalit do `Applicative` co 
-- nejjednodussim zpusobem. V nasem pripade odpovida presne nasi funkci `return`.
-- Operator `(<*>)` ma typ `Mozna (a -> b) -> Mozna a -> Mozna b`, "vybali" tedy 
-- funkci z aplikativniho funktoru, a potom udela `fmap` na funktor, ktery dostane 
-- jako vstup. To se muze hodit, napriklad v pripade, ze chceme secist dve cisla 
-- zabalena v nejakem aplikativnim funktoru (treba monade `Mozna`). Muzeme pak 
-- psat `pure (+) <*> Proste 3 <*> Proste 5` (a dostaneme `Proste 8`). Funkce pure 
-- nam dovolila zabalit funkci do aplikativniho funktoru a potom ji pouzit na 
-- parametry, ktere v tomto funktoru jsou. Muzeme se na `(<*>)` divat take jako na 
-- vylepseny `fmap`. Zapisovat `pure (+)` na zacatek muze byt zdlouhave, ale 
-- existuje i operator `<$>`, ktery funkci napred do funktoru zabali a potom se 
-- chova jako `<*>`. Predchozi priklad bychom mohli tedy prepsat jako 
-- `(+) <$> Proste 3 <*> Proste 5`.

instance Monad Mozna where
    (>>=)  = rbind
    return = pure -- od GHC 7.10 neni treba, je to defaultni implementace

-- A ted muzeme pouzivat do notaci i pro nasi tridu `Mozna`.

safeLogPlusSqrt' x = do
        y <- safeLog x
        z <- safeSqrt x
        return (y + z)

-- `Maybe` neni jedina monada, ktera v Haskellu je, je to spis jeden z 
-- jednodussich prikladu pouziti monad. Podivejme se na dalsi.

-- Zkusme si zahrat piskvorky na hraci plose 3x3. Hraci plochu muzeme 
-- reprezentovat jako seznam deviti pozic, pricemz na kazde pozici je 
-- `'.'`, `'x'` nebo `'o'`. 

-- Napisme si funkci, ktera dostane symbol, za ktery hrajeme (`'x'`, nebo `'o'`) a 
-- aktualni hraci plochu a vrati nam vsechny mozne hraci plochy po jednom tahu.

dalsiTahy :: Char -> [Char] -> [[Char]]
dalsiTahy t xs = tahy ("", xs) t

-- Napiseme si jeste pomocnou funkci `tahy`. Vsimnete si pouziti rozdeleni plochy 
-- na dve casti - jednu, kterou uz jsme zpracovali, a druhou, se kterou prave 
-- pracujeme. Diky tomu celou plochu projdeme jen jednou.

tahy :: ([Char], [Char]) -> Char -> [[Char]]
tahy (_,[])   _    = []
tahy (x,y:ys) t     | y == '.'  = (x ++ (t:ys)) : tahy (x++[y], ys) t
                    | otherwise = tahy (x++[y], ys) t

-- Jeste se nam hodi prevod plochy na tisknutelnejsi String.

plochaStr xs = "---\n" ++ take 3 xs ++ "\n" ++ take 3 (drop 3 xs) ++ "\n" ++ take 3 (drop 6 xs) ++ "\n"

-- Jak ted zjistime, jak bude plocha vypadat po odehrani jednoho tahu hrace `'o'`, 
-- jestlize na zacatku byl jeden krizek uprostred? To se da snadno zjistit pomoci 
-- nasi funkce `dalsiTahy`. 

poJednomTahu :: [[Char]]
poJednomTahu = dalsiTahy 'o' "....x...."

-- A jak to bude vypadat po dvou tazich? Napred `'o'` a pak `'x'`.

poDvouTazich :: [[Char]]
poDvouTazich = concat (map (dalsiTahy 'x') (dalsiTahy 'o' "....x...."))

-- Jak byste to napsali dal po trech, po ctyrech a po peti tazich? Funkce se nam 
-- prodluzuje a zneprehlednuje. Nicmene muzeme vyuzit toho, ze i seznam je monada 
-- a chova se presne tak, jak by se nam hodilo -- bind dela prave ten `map` a 
-- `concat`, ktery potrebujeme. Takze funkce `poDvouTazich` se pomoci monadoveho 
-- zapisu da napsat jako:

mPoDvouTazich = ["....x...."] >>= dalsiTahy 'o' >>= dalsiTahy 'x'

-- Nebo pomoci do notace

dPoDvouTazich = do 
    x <- ["....x...."]
    y <- dalsiTahy 'o' x
    dalsiTahy 'x' y 
   
-- Seznamy se chovaji prave takhle, protoze tim umoznuji zachytit 
-- nedeterminismus vypoctu. Funkce proste vraci vsechny moznosti, ktere mohou 
-- nastat; postupne dalsi a dalsi vetveni nabaluje do dalsich a dalsich seznamu.

-- Ted uz dokonce umime napsat i seznam vsech usporadanych dvojice bez toho, 
-- abychom potrebovali list comprehension.

usporadaneDvojice xs ys = do
        x <- xs
        y <- ys
        return (x,y)

uD xs ys = xs >>= (\x -> (ys >>= \y -> return (x,y)))