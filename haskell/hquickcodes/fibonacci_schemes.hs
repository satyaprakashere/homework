{-# LANGUAGE BangPatterns, DeriveFunctor, TypeFamilies, TypeSynonymInstances, FlexibleContexts, FlexibleInstances, AllowAmbiguousTypes #-}

module Main where

import Data.Kind

import Debug.Trace

fst3 (a, _, _) = a

main :: IO ()
main = do
    print $ rem (fibonacciH1 5) 999999999

fibonacciH :: Int -> Integer
fibonacciH n = fst3 . hylo coAlgH algH $ (0,1,n)

fibonacciH1 :: Int -> Integer
fibonacciH1 n = fst3 . hylo'' coAlgH1 algH1 $ (0,1,n)

hylo'' :: Functor f => CoAlgebra f a -> Algebra f b -> a -> b
hylo'' f g = g . fmap (cata g .ana f) . f

newtype Fix f = Fix { unfix :: f (Fix f)}
type Mu = Fix

data ListF a r = Nil a | Cons a r deriving (Show, Functor)
type List a = Fix (ListF a)

type Algebra f a   = f a -> a
type CoAlgebra f a = a -> f a

algH :: (Eq a, Num a, Show a) => Algebra (ListF a) (a, a, Int)
algH (Nil a) = (a, a, 0)
algH (Cons _ (b, c, n)) = (b, c, n)
algH (Cons _ (x, y, n)) | trace ("(x, y) = (" ++ show x ++ ", " ++ show y ++ ")") False = undefined

coAlgH :: (Num a, Ord a, Show a) => CoAlgebra (ListF a) (a, a, Int)
coAlgH (x, _, 0) = Nil x
coAlgH (x, !y, n) = Cons x (y, x+y, (n-1))
coAlgH (x, y, n) | trace ("(x, y) = (" ++ show x ++ ", " ++ show y ++ ")") False = undefined


hylo :: Functor f => CoAlgebra f a -> Algebra f b -> a -> b
hylo f g = g . fmap (hylo f g) . f  -- no mention of Fix!

---------------------- Rough Work -------------------------
type family Base t :: Type  -> Type

type Alg f a = Base f a -> a
type CoAlg f a = a -> Base f a

algH1 :: (Eq a, Num a, Show a) => Alg [a] (a, a, Int)
algH1 (Cons _ (x, y, n)) | trace ("algebra (x, y) = (" ++ show x ++ ", " ++ show y ++ ")") False = undefined
algH1 (Nil a) = (a, a, 0)
algH1 (Cons _ (b, c, n)) = (b, c, n)

coAlgH1 :: (Num a, Ord a, Show a) => CoAlg [a] (a, a, Int)
coAlgH1 (x, y, n) | trace ("coalgebra (x, y) = (" ++ show x ++ ", " ++ show y ++ ")") False = undefined
coAlgH1 (x, _, 0) = Nil x
coAlgH1 (x, !y, n) = Cons x (y, x+y, n-1)

--hylo :: Functor f => CoAlg f a -> Alg f b -> a -> b -- doesn't work
--hylo' f g = g . fmap (hylo f g) . f  -- no mention of Fix!

type instance Base [a] = ListF a

class Functor (Base t) => Recursive t where
    project :: t -> Base t t

class Functor (Base t) => CoRecursive t where
    embed :: Base t t -> t

--instance Functor f => Recursive (Fix f) where
--  project (In a) = a
--instance Functor f => CoRecursive (Fix f) where
--  embed = In

instance Recursive [a] where
    project [] = undefined
    project [a] = Nil a
    project (x:xs) = Cons x xs

instance CoRecursive [a] where
    embed (Nil a) = [a]
    embed (Cons x xs) = x:xs


--data PairF a r = PairF r deriving (Show, Functor)
--type Pair a = Fix (PairF a)

-- redundant
--ana :: Functor f => CoAlgebra f a -> (a -> Mu f)
--ana f = Fix. fmap (ana f) . f
--
--anaL :: (b -> ListF a b) -> b -> List a/Fix (ListF a
--anaL f y = Fix (fmap (anaL f) (f y))

-- Fibonacci with Ana concrete

fibonacciC :: [Integer]
fibonacciC = anaLC coAlgC (0,1)

anaLC :: (b -> (a, b)) -> b -> [a]
anaLC f b = a : anaLC f b' where
    (a, b') = f b

coAlgC (a, b) = (a, (b, a+b))

unbox :: List a -> [a]
unbox (Fix (Nil a)) = [a]
unbox (Fix (Cons a r)) = a : unbox r

fibonacci :: [Integer]
fibonacci = unbox (ana coAlg (0,1))

coAlg :: Num a => CoAlgebra (ListF a) (a, a)
coAlg (x, y) = Cons x (y, x+y)

alg :: (Eq a, Num a) => Algebra (ListF a) (a, a)
alg (Nil _) = undefined -- unnecessary
alg (Cons _ (b, c)) = (b, c)


data FreeM f a = Pure a | FreeM a (f (FreeM f a)) deriving (Functor)
data CofreeM f a = a :< (f (CofreeM f a))

cata :: Functor f => Algebra f a -> (Mu f -> a)
cata f = f . fmap (cata f) . unfix

ana :: Functor f => CoAlgebra f a -> (a -> Mu f)
ana f = Fix. fmap (ana f) . f

-----------------------------------------------------------------------

foldls :: (a -> b -> a) -> a -> [b] -> a
foldls _ a [] = a
foldls f !a (b:bs) = foldls f (f a b) bs

refold :: Functor s => (s b -> b) -> (a -> s a) -> a -> b
refold f g = go where go a = f (fmap go (g a))
