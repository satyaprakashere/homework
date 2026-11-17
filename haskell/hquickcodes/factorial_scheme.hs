{-# LANGUAGE BangPatterns,DeriveFunctor,TypeFamilies,TypeSynonymInstances, FlexibleInstances #-}
module Main where

import Data.List
import Data.Either


main :: IO ()
main = do
    print $ numDigits (factorialM 344546)
    print $ numDigits (factorial 6)
    print $ numDigits (factorial 12345)
    print $ numDigits (factorial 1270)
    print $ toList (In (Nil 5))
    print $ toList (In (Cons 7 (In (Cons 6 (In(Nil 5))))))
    print $ prt (out (In (Cons 7 (In (Cons 6 (In(Nil 5)))))))
    
prt (Cons a r) = a

numDigits :: Integer -> Integer
numDigits n
    | n < 99999999999 = n
    | otherwise = toInteger.length $ show n

factorial :: Integer -> Integer
factorial n = cata alg (fromList [1..n]) where
    alg :: ListF Integer Integer -> Integer
    alg (Nil a) = a
    alg (Cons a x) = (x*a)

cata :: Functor f => Algebra f a -> (Fix f -> a)
cata f = f . fmap (cata f) . out

newtype Fix f = In {out :: f (Fix f)}
type Mu = Fix

data ListF a r = Nil a | Cons a r deriving (Show, Functor)
type List a = Fix (ListF a)

type Algebra f a   = f a -> a
type CoAlgebra f a = a -> f a


---------------------- Rough Work -------------------------

data FreeM f a = Pure a | FreeM a (f (FreeM f a)) deriving (Functor)
data CofreeM f a = a :< (f (CofreeM f a))

ana :: Functor f => CoAlgebra f a -> (a -> Mu f)
ana f = In. fmap (ana f) . f

fromList :: [a] -> List a
fromList [x] = In (Nil x)
fromList (x:xs) = In (Cons x (fromList xs))

toList :: List a -> [a]
toList (In (Nil a)) = [a]
toList (In (Cons a r)) = a : toList r


--factorialH :: Int -> Integer
factorialM n = fst . hylo coAlgH algH $ (1,n) -- Modulo 99999999999999

algH (Nil a) = (a, 0)
algH (Cons a (0, n)) = (0, 0)
algH (Cons a (c, n)) = (c, n)

coAlgH (y, 0) = Nil y
coAlgH (!y, n) = Cons y (rem (y*n) 99999999999, (n-1))

hylo :: Functor f => CoAlgebra f a -> Algebra f b -> a -> b
hylo f g = g . fmap (hylo f g) . f  -- no mention of Fix!


-----------------------------------------------------------------------

foldls :: (a -> b -> a) -> a -> [b] -> a
foldls f a [] = a
foldls f !a (b:bs) = foldls f (f a b) bs

refold :: Functor s => (s b -> b) -> (a -> s a) -> a -> b
refold f g = go where go a = f (fmap go (g a))
