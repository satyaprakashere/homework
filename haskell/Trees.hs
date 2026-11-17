{-# LANGUAGE BangPatterns, DeriveFunctor, TypeFamilies, TypeSynonymInstances, FlexibleInstances, FlexibleContexts, AllowAmbiguousTypes #-}

module Main where

main :: IO ()
main = do
    -- Simulate universe this way
    -- Root node : Wavefunction
    -- Internal nodes : symmetries of the wavefunction | Measurement apparatus
    -- Leaf node : measurement
    print =<< contract alg ((NodeL (+) (NodeL (*) (LeafL (fmap read getLine)) (LeafL (fmap read getLine))) (LeafL (fmap read getLine)))::TreeL (Int -> Int -> Int) (IO Int)) where
--  alg :: (TreeLF (Int -> Int -> Int) (IO Int) (IO Int)) -> IO Int
        alg (LeafLF a) = do
            x <- a
            return (x+1)
        alg (NodeLF f a b) = do
            x <- a
            y <- b
            return (f x y)

testIntervalTree = do
    print $ updateRange (1, 3) tree where
        updateRange (a, b) tree = undefined
        tree = NodeIF (0, 4) 40
                (NodeIF (0, 2) 20
                    (NodeIF (0, 1) 15
                        (NodeIF (0, 0) 10)
                        (NodeIF (1, 1) 18))
                    (LeafIF 25))
                (LeafIF 40)

--updateRange range tree = undefined

--treeWithHoles :: [IO Int] -> TreeL (Int -> Int -> Int) (IO Int) -> TreeL (Int -> Int -> Int) (IO Int)
--treeWithHoles filling tree = expand coAlg (filling, tree) where
--      coAlg :: ([IO Int], TreeLF (Int -> Int -> Int) (IO Int) (IO Int)) -> TreeLF (Int -> Int -> Int) (IO Int) (IO Int)
--      coAlg ([], x)           = x
--      coAlg (x:xs, undefined) = (xs, x)
--      coAlg (x, y)               = y
data IntervalTreeF i a r = LeafIF a | NodeIF i a r r deriving (Show, Functor)
data IntervalTree i a = LeafI a | NodeI i a (IntervalTree i a) (IntervalTree i a)

data TreeLF f a r = LeafLF a | NodeLF f r r deriving (Show, Functor)
data TreeL f a = LeafL a | NodeL f (TreeL f a) (TreeL f a) deriving (Show, Functor)
type instance Base (TreeL f a) = TreeLF f a
instance Recursive (TreeL f a) where
    project (LeafL a) = LeafLF a
    project (NodeL f a b) = NodeLF f a b
    
instance Corecursive (TreeL a b) where
    embed (NodeLF f a b) = NodeL f a b
    embed (LeafLF a) = LeafL a
    
instance Show (Int -> Int -> Int) where
    show f = "op"
    
instance Show (IO Int) where
    show f = "IO Int"
------------------------- Abstraction ----------------------

type family Base t :: * -> *
--type Fix f = Base f

class Functor (Base t) => Recursive t where
    project :: t -> Base t t
    
class Functor (Base t) => Corecursive t where
    embed :: Base t t -> t
    
instance Recursive [a] where
    project [] = undefined
    project [a] = Nil a
    project (x:xs) = Cons x xs
    
instance Corecursive [a] where
    embed (Nil a) = [a]
    embed (Cons x xs) = (x:xs)
    
--newtype Fix f = In { out :: f (Fix f)}
--type instance Base (Fix f) = f

type Alg f a   = f a -> a
type CoAlg f a = a -> f a

type Algebra f a = Base f a -> a
type CoAlgebra f a = a -> Base f a
--type RAlg f a = f (Fix f, a) -> a
--type RCoAlg f a = a -> f (Either (Fix f) a)

type RAlgebra f a = Base f (f, a) -> a
type RCoAlgebra f a = a -> Base f (Either f a)

type Algebra2 f b a = Base f b -> a
type CoAlgebra2 f b a =  a -> Base f b

data FreeM f a = Pure a | FreeM a (f (FreeM f a)) deriving (Functor)
data CofreeM f a = a :< (f (CofreeM f a))
    
------------------------ Data types----------------------------------

data ListF a r = Nil a | Cons a r deriving (Show, Functor)
--type List a = Fix (ListF a)

type instance Base [a] = ListF a

data TreeF a l r = Leaf a | Node a l r deriving Functor
--type Tree a = Fix (TreeF a)
--type instance Base Tree a 

------------------------- Helper functions ----------------------

contract :: Recursive f => Algebra f a -> (f -> a)
contract = cata

expand :: Corecursive f => CoAlgebra f a -> (a -> f)
expand = ana

--loop' :: (Recursive f, Corecursive f) => (a -> Base f a) -> (Base f b -> b) -> (a -> b)
path' f g = (contract g) . (expand f)

path :: Functor f => CoAlg f a -> Alg f b -> (a -> b)
path = hylo

dissolve ::  Recursive f => RAlgebra f a -> f -> a
dissolve = para

evolve :: Corecursive f => RCoAlgebra f a -> a -> f
evolve = apo

dissolveWith :: Recursive f => Algebra2 f (b, a) a -> Algebra f b -> f -> a
dissolveWith = zygo

evolveWith :: Corecursive f => CoAlgebra2 f (Either b a) a -> CoAlgebra f b -> a -> f
evolveWith = gapo

-------------------------------------------------------------------

cata :: Recursive f => Algebra f a -> (f -> a)
cata f = f . fmap (cata f) . project

--cata :: Functor f => Algebra f a -> (Fix f -> a)
--cata f = f . fmap (cata f) . out

ana :: Corecursive f => CoAlgebra f a -> (a -> f)
ana f = embed . fmap (ana f) . f

--ana :: Functor f => CoAlg f a -> (a -> Fix f)
--ana f = In. fmap (ana f) . f

hylo :: Functor f => CoAlg f a -> Alg f b -> (a -> b)
hylo f g = g . fmap (hylo f g) . f  -- no mention of Fix!

--hylo :: Functor f => CoAlg f a -> Alg f b -> a -> b
--hylo f g = g . fmap (hylo f g) . f  -- no mention of Fix!

para ::  Recursive f => RAlgebra f a -> f -> a
para f = f . fmap ((,) <*> (para f)) . project

--para :: Functor f => RAlgebra f a -> Fix f -> a
--para f = f . fmap (\x -> (id x, (para f x))) . out

apo :: Corecursive f => RCoAlgebra f a -> a -> f
apo f = embed . (fmap (either id (apo f))) . f

--apo :: Functor f => RCoAlgebra f a -> a -> Fix f
--apo f = In . (fmap (either id (apo f))) . f

zygo :: Recursive f => Algebra2 f (b, a) a -> Algebra f b -> f -> a
zygo g f = g . fmap ((,) <$> (cata f) <*> (zygo g f)) . project

--zygo :: Recursive f => Algebra f b -> Algebra2 f (b, a) a -> f -> a
--zygo f g = g . fmap (\x -> (cata f x, (zygo f g x))) . project

--zygo :: Functor f => Algebra f b ->  (f (b, a) -> a) -> Fix f -> a
--zygo f g = snd . cata (\x -> (f $ fmap fst x, g x))

gapo :: Corecursive f => CoAlgebra2 f (Either b a) a -> CoAlgebra f b -> a -> f
gapo g f = embed . fmap (either (ana f) (gapo g f)) . g

mutu :: Recursive f => Algebra2 f (b, a) a -> Algebra2 f (b, a) b -> f -> a
mutu g f = snd . cata ((,) <$> f <*> g)

--mutu :: Functor f => (f (b, a) -> b) -> (f (b, a) -> a) -> Fix f -> a
--mutu f g = snd . cata (\x -> (f x, g x))

--loop ::