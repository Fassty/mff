import Control.Monad (mapM_, when)

-- tady začíná úkol, doplňte vlastní kód do míst s podtržítkem a undefined --
-- následující TODOs jsou potřeba pro spuštění prvního testu ve funkci main
newtype Stack stack a = S { runCommented :: stack -> (a,stack) }
type Commented a = Stack [String] a

instance Functor (Stack st) where
    fmap f (S r) = S
        { runCommented = \st ->
            let (result, state) = r st
            in (f result, state)
        }

instance Applicative (Stack st) where
    pure a = S { runCommented = \st -> (a, st) }
    (<*>) (S fr) (S r) = S
        { runCommented = \st ->
            let (result, state) = r st
                (f, nextState) = fr state
            in (f result, nextState)
        }

instance Monad (Stack st) where
    (>>=) (S r) f = S
        { runCommented = \st ->
            let (result, state) = r st
            in runCommented (f result) state
        }

comment x = S { runCommented = \st -> ((), st ++ [x]) }

-- jednoduchy komentovany foldr (negenericky, fungujici jen na seznamy)
-- následující TODO je potřeba pro spuštění druhého testu ve funkci main
cFoldr :: Show a => (a -> a -> a) -> a -> [a] -> Commented a
cFoldr = undefined -- TODO

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
