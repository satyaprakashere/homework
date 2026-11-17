{-# LANGUAGE BangPatterns,DeriveFunctor,TypeFamilies,TypeSynonymInstances, FlexibleInstances, FlexibleContexts, DeriveTraversable, TypeFamilies, TypeApplications #-}

module Main where

import Data.Kind

import Data.Typeable
import Data.Bifunctor

main = do
    print tree
    print $ (contract maxE tree :: Int)
    print $ (contract double tree :: BTree Int Int)
    print $ (expand hippify tree :: BTree Int Int) where
        tree = Node 42 (Node 2 (Leaf 243) (Leaf 23)) (Node 23 (Leaf 32) (Leaf 78)) -- :: (BTree Int Int)

hippify (Leaf a) = LeafF a
hippify t@(Node a x y) = shift (direction a x y) t

shift :: Shift -> BTree Int Int -> BTreeF Int Int (BTree Int Int)
shift _ (Leaf a) = LeafF a -- Base case
shift None (Node a x y) = NodeF a x y
shift Righty (Node a x (Leaf r)) = NodeF r x (Leaf a)
shift Righty (Node a x (Node r r1 r2)) = NodeF r x (Node a r1 r2)
shift Lefty (Node a (Leaf l) y) = NodeF l (Leaf a) y
shift Lefty (Node a (Node l l1 l2) y) = NodeF l (Node a l1 l2) y

direction a x y
    | a <= (value x) && a <= (value y) = None
    | a > (value x) =  Lefty
    | otherwise = Righty

value (Leaf a) = a
value (Node a _ _) = a

data Shift = Lefty | Righty | None


double (LeafF a) = Leaf (2*a)
double (NodeF a l r) = Node (2*a) l r

multiply (LeafF a) = a
multiply (NodeF a l r) = product [a, l, r]

minE (LeafF a) = a
minE (NodeF a l r) = minimum [a, l, r]

maxE (LeafF a) = a
maxE (NodeF a l r) = maximum [a, l, r]

sumE (LeafF a) = a
sumE (NodeF a l r) = sum [a, l, r]

------------------------- Abstraction ----------------------

type family Base t :: Type -> Type
newtype Fix f = In { out :: f (Fix f)}

class Functor (Base t) => Recursive t where
    project :: t -> Base t t

class Functor (Base t) => Corecursive t where
    embed :: Base t t -> t

instance Functor f => Recursive (Fix f) where
    project (In a) = a
instance Functor f => Corecursive (Fix f) where
    embed = In

instance Recursive [a] where
    project [] = undefined
    project [a] = Nil a
    project (x:xs) = Cons x xs

instance Corecursive [a] where
    embed (Nil a) = [a]
    embed (Cons x xs) = (x:xs)

type Algebra f a   = f a -> a
type CoAlgebra f a = a -> f a
type RAlgebra f a = f (Fix f, a) -> a
type RCoAlgebra f a = a -> f (Either (Fix f) a)

type RAlg f a = Base f (f, a) -> a

type Alg t a = Base t a -> a
type CoAlg f a = a -> Base f a

data FreeM f a = Pure a | FreeM a (f (FreeM f a)) deriving (Functor)
data CofreeM f a = a :< (f (CofreeM f a))

------------------------ Data types----------------------------------


data ListF a r = Nil a | Cons a r deriving (Show, Functor)
type List a = Fix (ListF a)

type instance Base (Fix f) = f
type instance Base [a] = ListF a

data BTree b l =
    Node b (BTree b l) (BTree b l)
        | Leaf l
        deriving (Show, Typeable, Functor, Traversable, Foldable)

instance Bifunctor BTree where
    bimap _ g (Leaf x) = Leaf (g x)
    bimap f g (Node b l r) = Node (f b) (bimap f g l) (bimap f g r)

data BTreeF b l r =
    NodeF b r r
        | LeafF l
        deriving (Show, Functor, Typeable)

type instance Base (BTree a b) = BTreeF a b

instance Recursive (BTree a b) where
    project (Leaf x) = LeafF x
    project (Node s l r) = NodeF s l r

instance Corecursive (BTree a b) where
    embed (NodeF sp x xs) = Node sp x xs
    embed (LeafF x) = Leaf x

------------------------- Helper functions ----------------------

contract :: Recursive t => Alg t a -> t -> a
contract = cata'

cata' :: Recursive t => Alg t a -> t -> a
cata' f = f . fmap (cata' f) . project

cata :: Functor f => Algebra f a -> (Fix f -> a)
cata f = f . fmap (cata f) . out

ana :: Functor f => CoAlgebra f a -> (a -> Fix f)
ana f = In. fmap (ana f) . f

expand :: Corecursive f => CoAlg f a -> (a -> f)
expand f = embed . fmap (expand f) . f

hylo :: Functor f => CoAlgebra f a -> Algebra f b -> a -> b
hylo f g = g . fmap (hylo f g) . f  -- no mention of Fix!

para ::  Recursive f => RAlg f a -> f -> a
para f = f . fmap ((,) <*> (para f)) . project
--para :: Functor f => RAlgebra f a -> Fix f -> a
--para f = f . fmap ((,) <*> (para f)) . out

apo :: Functor f => RCoAlgebra f a -> a -> Fix f
apo f = In . (fmap (either id (apo f))) . f

zygo :: Functor f => Algebra f b ->  (f (b, a) -> a) -> Fix f -> a
zygo f g = snd . cata (\x -> (f $ fmap fst x, g x))

mutu :: Functor f => (f (b, a) -> b) -> (f (b, a) -> a) -> Fix f -> a
mutu f g = snd . cata (\x -> (f x, g x))


------------------------- Rough Work -------------------------------


--sort (Node a x@(Leaf l) y@(Leaf r))
--  | a <= l && a <= r = NodeF a x y
--  | a > l =  NodeF l (Leaf a) y
--  | otherwise = NodeF r x (Leaf a)
--sort (Node a x@(Node l l1 l2) y@(Leaf r))
--  | a <= l && a <= r = NodeF a x y
--  | a > l = NodeF l (Node a l1 l2) y
--  | otherwise = NodeF r x (Leaf a)
--sort (Node a x@(Leaf l) y@(Node r r1 r2))
--  | a <= l && a <= r = NodeF a x y
--  | a > l = NodeF l (Leaf a) y
--  | otherwise = NodeF r (Node a r1 r2) x
--sort (Node a x@(Node l l1 l2) y@(Node r r1 r2))
--  | a <= l && a <= r = NodeF a x y
--  | a > l = NodeF l (Node a l1 l2) y
--  | otherwise = NodeF r (Node a r1 r2) x
