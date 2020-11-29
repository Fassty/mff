import Data.List
type Castka = Integer

data Operace
    = Prihlaseni
    | Odhlaseni
    | Vyber Castka
    | Pripis Castka
    deriving (Show, Read, Eq)

type Cas = Integer

type Uzivatel = String

data Zaznam =
  Zaznam Cas
         Uzivatel
         Operace
  deriving (Show, Read, Eq)

in_range min max x =
    let lbound = min <= x
        ubound = max >= x
    in
    lbound && ubound

element :: (Eq a) => a -> [a] -> Bool
element _ [] = False
element e (x:xs) = (e == x) || (element e xs)

remd :: (Eq a) => [a] -> [a]
remd [] = []
remd (x:xs)
    |  element x xs = remd (xs)
    |  otherwise = x : remd (xs)

asc :: [Int] -> Bool
asc [] = True
asc [x] = True
asc (x:y:xs) =
    (x <= y) && asc(y:xs)

path :: [(Int, Int)] -> Int -> Int -> Bool
path [] x y = x == y
path xs x y
    | x == y = True
    | otherwise =
      let xs' = [ (n,m) | (n,m) <- xs, n /= x ] in
      or [ path xs' m y | (n,m) <- xs, n == x ]

serazeni :: [Int] -> [Int]
serazeni xs =
    let arr = nub xs
    in sort arr

revList = foldr (\(x:xs) acc -> acc++x) []
