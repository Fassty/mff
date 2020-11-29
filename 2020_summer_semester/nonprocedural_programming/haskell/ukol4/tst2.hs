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

test = do
    comment "ahoj"
    comment "nazdar"
    return (2+3)

