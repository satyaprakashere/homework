module Main where

import Data.List

mins = head.sort

data Three a = LeftT Int | MidT String | RightT Float

instance Functor Three where
    fmap _ (LeftT i) = LeftT i
    fmap _ (MidT s) = MidT s
    fmap f (RightT x) = RightT (f x)

instance Applicative Three where
    pure = RightT
    LeftT i <*> _ = LeftT i
    MidT s <*> _ = MidT s
    RightT f <*> r = fmap f r

instance Monad Three where
    return = pure
    LeftT i >>= _ = LeftT i
    MidT s >>= _ = MidT s
    RightT x >>= f = f x

main :: IO ()
main = do
    print $ mins [43,67,3,4,43,5]
    print $ rem (sum [1..100000000]) 34578435
