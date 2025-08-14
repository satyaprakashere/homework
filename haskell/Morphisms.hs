{-# LANGUAGE BangPatterns, DeriveFunctor, TypeFamilies, TypeSynonymInstances, FlexibleContexts, FlexibleInstances, AllowAmbiguousTypes #-}
module Main where

import Data.Kind

import Data.List
import Data.Either

--class Fix f where
--	unfix :: f (Fix f)
--
--instance Fix (:) where
--	unfix = let x = f x in x
type family Base t :: Type -> Type

newtype Fix f = Fix { unfix :: f (Fix f)}
type Mu = Fix

--data FreeM f a = Pure a | FreeM a (f (FreeM f a))
--data CofreeM f a = a :< (f (CofreeM f a))

type Algebra f a   = f a -> a
type CoAlgebra f a = a -> f a

cata :: Functor f => Algebra f a -> (Mu f -> a)
cata f = f . fmap (cata f) . unfix

ana :: Functor f => CoAlgebra f a -> (a -> Mu f)
ana f = Fix. fmap (ana f) . f

hylo :: Functor f => (a -> f a) -> (f b -> b) -> a -> b
hylo f g = g . fmap (hylo f g) . f  -- no mention of Fix!

para :: Functor f => (f (Mu f, a) -> a) -> Mu f -> a
para f = f . fmap (\x -> (x, para f x)) . unfix

apo :: Functor f => (a -> f (Either (Fix f) a)) -> a -> Fix f
apo f = Fix . fmap (either id (apo f)) . f

zygoL :: Functor f => (a -> f (Either a (Fix f)))
zygoL = undefined

--unfoldr :: Functor f => (b -> Maybe (a, b)) -> (b -> f a)
--unfoldr f = undefined

foldls :: (a -> b -> a) -> a -> [b] -> a
foldls f a [] = a
foldls f !a (b:bs) = foldls f (f a b) bs

factOG 0 = 1
factOG 1 = 1
factOG n = n * factOG (n-1)

--factorial :: Num a => a -> a
factorial n = product [1..n]

anaL :: (b -> ListF a b) -> b -> List a
anaL f y = Fix (fmap (anaL f) (f y))

fibonacci :: [Integer]
fibonacci = unbox (ana coAlgb (0,1))

--coAlg :: (Num a, Num b) => (a, b) -> (a, (a, b))
coAlgb :: Num a => (a, a) -> ListF a (a, a)
coAlgb (x, y) = Cons x (y, x+y)

data ListF a r = Nil a | Cons a r deriving (Show, Functor)
type List a = Fix (ListF a)

unbox :: List a -> [a]
unbox (Fix (Nil a)) = []
unbox (Fix (Cons a r)) = a : unbox r

--anaT :: Functor f => CoAlgebra f a -> (a -> Fix f)
--anaT f =

main :: IO ()
main = do
    print $ rem ((head. drop 35383) fibonacci) 999999999
--	putStrLn "Hello World"
--	print $ foldls (+) 0 [1..123456736]
--	print $ fmap
--	print $ (take 100 fibonacci)
--	print $ fibs (1,1)
