{-# LANGUAGE BangPatterns,DeriveFunctor,TypeFamilies,TypeSynonymInstances, FlexibleInstances, FlexibleContexts #-}

module Main where

import Debug.Trace

main = do
    print "Hello world"
    print $ subtringMatch "ABC ABCDAB ABCDABCDABDE" "ABCDABD"
    
-- TODO : Draw KMP in terms of loops and fibers
subtringMatch os ow = findMatch os gss ow 0 0 where
    findMatch s h w c res |
        trace ("findMatch with helper: " ++ show h ++ " String: " ++ show s ++ " matcher: " ++ show w ++ " Count: " ++ show c ++ " Res: " ++ show res) False = undefined
    findMatch s [] w c res = findMatch s gss w c res -- Loop for helper table
    findMatch s h [] c res = findMatch s h ow c res -- Loop for matcher table
    findMatch [] h w c res = -1 -- End of phrase, End of the OG loop
    findMatch s h w c res
        | c == length ow = res - c -- Success condition, End of the OG loop, End of the program
        | otherwise = case (head s) == (head w) of
            True -> findMatch  (tail s) (tail h) (tail w) (c+1) (res+1) -- local match
            False -> findMatch (tail s) (drop (head h + 1) h) (drop (head h + 1) ow) 0 (res+1) -- local mismatch
    gss = [-1, 0, 0, 0, -1, 0, 2] -- helper table


--makeGss h w = case (head w) == ()

--substringM os ow = zygo findM (os, gss, ow, 0, 0) where
--  findM = undefined
--  gss = [-1, 0, 0, 0, -1, 0, 2] -- helper table
    

------------------------- Abstraction ----------------------

type family Base t :: * -> *

class Functor (Base t) => Recursive t where
    project :: t -> Base t t
    
class Functor (Base t) => CoRecursive t where
    embed :: Base t t -> t
    
instance Functor f => Recursive (Fix f) where
    project (In a) = a
instance Functor f => CoRecursive (Fix f) where
    embed = In
    
instance Recursive [a] where
    project [a] = Nil a
    project (x:xs) = Cons x xs
    
instance CoRecursive [a] where
    embed (Nil a) = [a]
    embed (Cons x xs) = (x:xs)
    
------------------------ Data types----------------------------------

newtype Fix f = In { out :: f (Fix f)}

data ListF a r = Nil a | Cons a r deriving (Show, Functor)
type List a = Fix (ListF a)

type instance Base (Fix f) = f
type instance Base [a] = ListF a

type Algebra f a   = f a -> a
type CoAlgebra f a = a -> f a
type RAlgebra f a = f (Fix f, a) -> a
type RCoAlgebra f a = a -> f (Either (Fix f) a)

type Alg t a = Base t a -> a

data FreeM f a = Pure a | FreeM a (f (FreeM f a)) deriving (Functor)
data CofreeM f a = a :< (f (CofreeM f a))

------------------------- Helper functions ----------------------

cata' :: Recursive t => Alg t a -> t -> a
cata' f = f . fmap (cata' f) . project

cata :: Functor f => Algebra f a -> (Fix f -> a)
cata f = f . fmap (cata f) . out

ana :: Functor f => CoAlgebra f a -> (a -> Fix f)
ana f = In. fmap (ana f) . f

hylo :: Functor f => CoAlgebra f a -> Algebra f b -> a -> b
hylo f g = g . fmap (hylo f g) . f  -- no mention of Fix!

para :: Functor f => RAlgebra f a -> Fix f -> a
para f = f . fmap ((,) <*> (para f)) . out

apo :: Functor f => RCoAlgebra f a -> a -> Fix f
apo f = In . (fmap (either id (apo f))) . f

zygo :: Functor f => Algebra f b ->  (f (b, a) -> a) -> Fix f -> a
zygo f g = snd . cata (\x -> (f $ fmap fst x, g x))

mutu :: Functor f => (f (b, a) -> b) -> (f (b, a) -> a) -> Fix f -> a
mutu f g = snd . cata (\x -> (f x, g x))