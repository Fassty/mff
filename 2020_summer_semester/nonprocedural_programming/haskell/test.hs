import Data.List
import Data.Maybe
bin f (a:b:xs) = do { c <- a; d <- b; Just $ (f c d) } :xs
partials [x] = [[Just x]]
partials (x:xs) = concatMap (addOp (Just x:)) (partials xs)
addOp x p = x p : if (length p == 1) then [] else binR (addOp x) p
finish p = if (length p == 1) then [head p] else binR finish p
binR f p = concatMap (f . flip id p) [bin (+), bin (-), bin (*)]
ans = catMaybes $ sort $ concatMap finish (partials [1,2,3])
