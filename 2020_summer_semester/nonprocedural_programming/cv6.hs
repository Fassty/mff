-- Author: Martin Pilat
-- Date: 16. 5. 2017
-- Updated: 18. 5. 2020

------------------------------------------------------------------------------
--          6. cviceni -- Haskell - State, IO, record syntaxe, zipper
------------------------------------------------------------------------------

-- V dnesnich cvicenich se nam hodi nekolik importu:

import Data.Char
import Control.Exception
import Network.HTTP -- pokud modul nemate, muzeho ho nainstalovat pomoci `cabal update; cabal install HTTP`

-- Rikali jsme si, ze funkce v Haskellu jsou ciste, tj. jejich hodnoty zavisi
-- jen na jejich vstupnich parametrech. To je sice pekne a dobre se s tim
-- pracuje, ale obcas to je neprakticke. Predstavme si treba, ze chceme v
-- pracovat se zasobnikem cisel. Muzeme si ho nadefinovat jako

type Zasobnik = [[Char]]

-- Pro praci se zasobnikem potom pouzivame typicky funkce jako `push` a `pop`.
-- `push` pridava hodnotu na zasobnik a `pop` vraci hodnotu z vrcholu zasobniku
-- (a odebere ji). Pro nas zasobnik je jednoduche je napsat.

push::[Char] -> Zasobnik -> Zasobnik
push h zas  = h:zas

pop::Zasobnik -> ([Char], Zasobnik)
pop (z:zas) = (z, zas)

-- Jak bychom ted napsali funkci, ktera odebere dve hodnoty z vrcholu zasobniku,
-- secte je, a vrati novy zasobnik?

zasobnikTest::Zasobnik->([Char], Zasobnik)
zasobnikTest z = (a++b, nz)
        where
            (a, z1)   = pop z
            (b, z2)   = pop z1
            nz        = push (a++b) z2

-- Neni to tezke, ale je to celkem ukecane a neprehledne, musime se sami starat
-- o predavani zasobniku mezi funkcemi. Pritom by bylo tak pekne, kdybychom
-- mohli pouzivat treba `do` notaci a zasobniku si vubec nevsimat. Takova vec
-- je v Haskellu mozna a implementuje ji `State` monada. Ta ma dva typove
-- parametry, typ stavu (`s`) a typ navratove hodnoty funkce (`a`). Zajimave
-- je, ze uvnitr monady tentokrat nemame samotne hodnoty techto dvou typu, ale
-- funkci, ktera vezme stav a spocita navratovou hodnotu a novy stav. Musi to
-- tak byt, jinak bychom se museli o stav starat porad sami a predavat si ho.
-- Cela myslenka teto monady je v tom, ze budeme postupne skladat funkce. Na
-- zacatku zadame jako parametr pocatecni stav a dal se o nej funkce budou
-- starat samy a budou si ho i samy predavat (pomoci `>>=`).

data Stav a = Stav {runState :: a -> (a, [String])}

-- V definici `Stav` si muzete vsimnout pouziti tzv. record syntaxe, ta vlastne
-- pojmenovava funkci ulozenou uvnitr `Stav` a zaroven vytvari funkci
-- `runState::Stav s a -> s -> (a, s)`, ktera nam vrati funkci obsazenou ve
-- `Stav`. Funkce `pop` a `push` potom muzeme prepsat tak, aby pracovaly se
-- stavem, ktery obsahuje nas zasobnik. Potrebujeme tedy, aby vracely neco typu
-- `Stav Zasobnik b`, kde `b` je libovolny navratovy typ funkce. U `popS` tento
-- typ je `Int` (prvni hodnota ze zasobniku), u `pushS` pouzijeme jako typ `()`,
-- kteremu se take rika unit. Je to typ, ktery muze obsahovat jen jednu hodnotu
-- a to `()`. Odpovida trochu typu void v jinych programovacich jazycich
-- (`NoneType` v Pythonu). (Pozor v Haskellu je i typ `Void`, ktery dela neco
-- uplne jineho -- je pro funkce, ktere nikdy nic nevrati.)

-- `popS` tedy zabali do `Stav` funkci, ktera vezme stav, z nej odebere prvni
-- prvek ten nastavi jako vyslednou hodnotu a vrati zasobnik bez prvniho prvku.

pushS::[Char] -> Stav ()
pushS x = Stav $ \_ -> ((),x)

-- Na `pushS` vidime, ze funkce pro praci se stavem mohou mit i parametry. V
--  tomto pripade `pushS` dostane `Int`, ten prida na zacatek zasobniku a vrati
-- `()`. Neni totiz asi zadna rozumna hodnota, kterou by `pushS` jinak mohla
-- vratit, tato navratova hodnota nas navic nebude zajimat. Pojdme ze `Stav`
-- udelat monadu: samotna monada musi mit jen jeden typovy parametr,
-- implementovat jako monadu tedy budeme `(Stav s)` a ne jen samotny `Stav`.

-- Prvni vec, kterou potrebujeme je napsat instanci pro `Functor (Stav s)`,
-- tzn. potrebujeme napsat funkci `fmap::(a -> b) -> Stav s a -> Stav s b`,
-- mela by to tedy byt funkce, ktera vezme funkci `a->b`, ktera stav uplne
-- ignoruje, a aplikuje ji ve `Stav s`. Jedina rozumna implementace takove
-- funkce bude vzit navratovou hodnotu ze `Stav s a`, na ni aplikovat funkci a
-- vytvorit tak `Stav s b`. Samotny vnitrni stav by se nemel zmenit.

instance Functor Stav where
    -- fmap::(a -> b) -> Stav s a -> Stav s b
    fmap f x = Stav $ \s -> let (v, ns) = runState x s
                            in  (f v, ns)

-- Na implementaci je mozna vhodne podivat se podrobneji. `runState x` vytahne
-- funkci ze stavu `x` (druheho parametru `fmap`) a aplikuje ji na stav
-- `s` (parametr nove funkce, kterou definujeme), tim ziska vysledek a stav, na
-- vysledek potom aplikuje `f` (prvni parametr `fmap`) a stav jen zkopiruje.

-- Jako dalsi krok potrebujeme napsat instanci `Applicative` pro `Stav s`, tedy
-- funkci `pure::a -> Stav s a`, ktera co nejjednoduseji zabali hodnotu do
-- `Stav s`, a operator `(<*>)::Stav s (a->b) -> Stav s a -> Stav s b`.

-- Funkce `pure` je jednoducha, kdyz dostane hodnotu, tak vytvori funkci, ktera
-- jen zkopiruje stav a jako navratovou hodnotu nastavi hodnotu ze vstupu.

-- Operator `(<*>)` je o neco komplikovanejsi. Napred spusti `runState` na stav,
-- ktery obsahuje funkci `(a->b)`, potom spusti `runState` i na druhy parametr,
-- tim dostane vysledek typu `a` a dalsi novy stav. Na vysledek aplikuje funkci,
-- ktera byla vysledkem prvniho stavu a vrati nejnovejsi stav.

instance Applicative Stav where
    -- pure:: a -> Stav s a
    pure x     = Stav $ \s -> (x, s)
    -- (<*>)::Stav s (a->b) -> Stav s a -> Stav s b
    sab <*> sa = Stav $ \s -> let (ab, ns) = runState sab s
                                  (a, ns2) = runState sa ns
                              in  (ab a, ns2)

-- Konecne muzeme napsat instanci `Monad (Stav s)`, staci uz nam jen dodefinovat
-- operator `(>>=)::Stav s a -> (a -> Stav s b) -> Stav s b`, ktery vlastne
-- retezi dve funkce se stavem za sebou. Napred tedy spusti `runState` na svou
-- levou stranu, a na vysledny stav aplikuje funkci, kterou ma na prave strane.
-- Tim dostane novy stav a zavola na nej `runState`.

instance Monad Stav where
    --(>>=)::Stav s a -> (a -> Stav s b) -> Stav s b
    h >>= f = Stav $ \_ -> let (a, newState) = runState h
                               g             = f a
                           in  runState g

-- Nyni muzeme nasi testovaci funkci prepsat jednoduse pomoci `do` notace, je
-- videt, ze kod je mnohem prehlednejsi a snadnejsi na pochopeni, navic se
-- nemusime o stav starat sami.

zasobnikTestS::Stav Int
zasobnikTestS = do
    pushS "ahoj"
    pushS "nazdar"
    return 20

-- Pomoci `State` monady muzeme treba implementovat i praci s nahodnymi cisly.
-- Napiseme si jednoduchy linearni kongruencni generator nahodnych cisel.

