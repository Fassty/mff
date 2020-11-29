data Commented s a = Commented {runState :: a -> (a, s)}

comment :: String -> Commented [Int] ()
comment x = Commented $ \ss -> ((), x:ss)

instance Functor (Commented s) where
    fmap f x = Commented $ \s -> let (v, ns) = runState x s
                                 in (f v, ns)

instance Applicative (Commented s) where
    pure x = Commented $ \s -> (x, s)
    sab <*> sa = Commented $ \s -> let (ab, ns) = runState sab s
                                       (a, ns2) = runState sa ns
                                   in (ab a, ns2)

instance Monad (Commented s) where
    h >>= f = Commented $ \s -> let (a, newCommented) = runState h s
                                    g                 = f a
                                in runState g newCommented

test = do
    comment 10
    comment 20
    return 10
