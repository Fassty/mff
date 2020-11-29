import Control.Monad (mapM_, when)

-- tady začíná úkol, doplňte vlastní kód do míst s podtržítkem a undefined --
-- následující TODOs jsou potřeba pro spuštění prvního testu ve funkci main
data Commented a = Commented [String] a deriving(Show)  -- TODO

comment :: String -> Commented ()
comment c = (Commented [c] ()) -- TODO

runCommented :: Commented a -> (a, [String])
runCommented (Commented cs a) = (a, cs) -- TODO

instance Functor Commented where
    -- fmap :: (a->b) -> Commented a -> Commented b
    fmap f (Commented cs a) = Commented cs (f a)  -- TODO

instance Applicative Commented where
    -- pure :: a -> Commented a
    pure a = Commented [] a -- TODO
    -- (<*>) :: Commented (a -> b) -> Commented a -> Commented b
    (Commented cs2 f) <*> (Commented cs1 a) = Commented (cs1 ++ cs2) (f a)  -- TODO

instance Monad Commented where
    return = pure
    -- (>>=) :: Commented a -> (a -> Commented b) -> Commented b
    (Commented cs1 a) >>= f = Commented (cs1 ++ cs2) b
        where (Commented cs2 b) = f a -- TODO

-- jednoduchy komentovany foldr (negenericky, fungujici jen na seznamy)
-- následující TODO je potřeba pro spuštění druhého testu ve funkci main
cFoldr :: Show a => (a -> a -> a) -> a -> [a] -> Commented a
cFoldr f a [b] = do
    comment ("konec seznamu")
    comment ("mezihodnota " ++ show a)
    return $ f a b
cFoldr f a (b:bs) = do
    bs' <- cFoldr f a bs
    comment ("mezihodnota " ++ show bs')
    return $ f b bs'


-- tady končí úkol a začíná testování: --



-- vrátí okomentovaný seznam řešení kvadratické rovnice
solutions :: (Show a, Ord a, Floating a) => a -> a -> a -> Commented [a]
solutions a b c = do
    when (a == 0) $ comment "Ajaj, rovnice je ve skutecnosti linearni."
    let d = b ^ 2 - 4 * a * c
    comment $ "Diskriminant je " ++ show d
    if (d < 0)
        then do
            comment "Nemame reseni!"
            return []
        else do
            comment "Parada, mame alespon jedno reseni!"
            return $ (\op -> (-b `op` sqrt d) / (2 * a)) `map` [(+), (-)]

twoSolutions :: (Show a, Ord a, Floating a) => a -> a -> a -> a -> Commented [a]
twoSolutions a b1 b2 c = do
    sol1 <- solutions a b1 c
    comment $ "Prvni rovnice ma " ++ show (length sol1) ++ " reseni"
    sol2 <- solutions a b2 c
    comment $ "Druha rovnice ma " ++ show (length sol2) ++ " reseni"
    return $ sol1 ++ sol2

main :: IO ()
main = do
    -- prvni test: twoSolutions.
    putStrLn "=== Zacatek prvni test ==="
    let (a, b1, b2, c) = (1, 5, 7, 6)
    putStrLn $ "Prvni kvadraticka rovnice: " ++ (show a) ++ "x^2 + " ++ (show b1) ++ "x + " ++ (show c)
    putStrLn $ "Druha kvadraticka rovnice: " ++ (show a) ++ "x^2 + " ++ (show b2) ++ "x + " ++ (show c)
    let (vysledky, comments) = runCommented $ twoSolutions a b1 b2 c
    mapM_ putStrLn comments
    putStrLn . ("Vysledek twoSolutions: " ++) . show $ vysledky
    putStrLn ""
    -- druhy test: twoSolutions.
    putStrLn "=== Zacatek druhy test ==="
    let (vysledky, comments) = runCommented $ cFoldr (*) 1 [1 .. 10]
    mapM_ putStrLn comments
    putStrLn . ("Vysledek foldr: " ++) . show $ vysledky
