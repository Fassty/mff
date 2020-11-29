data Op
    = Plus
    | Minus
    | Times
    deriving (Eq, Ord)

data Exp
    = Const Int
    | Oper Op Exp Exp
    deriving (Eq, Ord)

instance Show Op where
    show Plus = "+"
    show Minus = "-"
    show Times = "*"

showInner :: Exp -> String
showInner (Const x) = show x
showInner (Oper op e1 e2) = "(" ++ showInner e1 ++ " " ++ show op ++ " " ++ showInner e2 ++ ")"

instance Show Exp where
    show (Const x) = show x
    show (Oper op e1 e2) = showInner e1 ++ " " ++ show op ++ " "  ++ showInner e2


genTree :: [Int] -> [Exp]
genTree nums
    | length nums <= 1 = [(Const (head nums))]
    | otherwise = do
        i <- [1..(length nums - 1)]
        let (l, r) = splitAt i nums
        e1 <- genTree l
        e2 <- genTree r
        op <- [Plus, Minus, Times]
        return (Oper op e1 e2)

eval :: Exp -> Int
eval (Const x) = x
eval (Oper Plus e1 e2) = eval e1 + eval e2
eval (Oper Minus e1 e2) = eval e1 - eval e2
eval (Oper Times e1 e2) = eval e1 * eval e2

arit :: [Int] -> Int -> [Exp]
arit nums n = [expr | expr <- (genTree nums), eval expr == n]
