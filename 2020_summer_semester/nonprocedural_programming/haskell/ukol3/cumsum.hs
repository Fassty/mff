cumsum :: Num a => [[a]] -> [[a]]
cumsum lst = scanl1 (\x y -> zipWith (+) x y) (map (\x -> scanl1 (+) x) lst)
