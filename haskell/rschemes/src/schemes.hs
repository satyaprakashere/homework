{-# LANGUAGE DeriveFunctor, TypeFamilies, FlexibleInstances, FlexibleContexts, AllowAmbiguousTypes, ScopedTypeVariables #-}
module Schemes where

------------------------- Abstraction ----------------------

type family Base t :: * -> *

class Functor (Base t) => Recursive t where
    project :: t -> Base t t

class Functor (Base t) => Corecursive t where
    embed :: Base t t -> t
    
instance Recursive [a] where
    project [] = Nil
    project (x:xs) = Cons x xs

instance Corecursive [a] where
    embed Nil = []
    embed (Cons x xs) = x:xs

newtype Fix f = In { out :: f (Fix f)}
type instance Base (Fix f) = f

type Alg f a   = f a -> a
type CoAlg f a = a -> f a

type Algebra f a = Base f a -> a
type CoAlgebra f a = a -> Base f a

type Algebra2 f b a = Base f b -> a
type CoAlgebra2 f b a =  a -> Base f b

data FreeM f a = Pure a | FreeM a (f (FreeM f a)) deriving (Functor)
data CofreeM f a = a :< (f (CofreeM f a))

------------------------ Data types----------------------------------

data ListF a r = Nil | Cons a r deriving (Show, Functor)
type List a = Fix (ListF a)

type instance Base [a] = ListF a

--data TreeF a l r = Leaf a | Node a l r deriving Functor
--type Tree a = Fix (TreeF a)
--type instance Base Tree a

------------------------- Helper functions ----------------------

fold :: Recursive f => Algebra f a -> (f -> a)
fold = cata

unfold :: Corecursive f => CoAlgebra f a -> (a -> f)
unfold = ana

--loop' :: (Recursive f, Corecursive f) => (a -> Base f a) -> (Base f b -> b) -> (a -> b)
refold' f g = fold g . unfold f

refold :: Functor f => CoAlg f a -> Alg f b -> (a -> b)
refold = hylo

dissolve ::  Recursive f => Algebra2 f (f, a) a -> f -> a
dissolve = para

evolve :: Corecursive f => CoAlgebra2 f (Either f a) a -> a -> f
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

para ::  Recursive f => Algebra2 f (f, a) a -> f -> a
para f = f . fmap ((,) <*> para f) . project

--para :: Functor f => RAlgebra f a -> Fix f -> a
--para f = f . fmap (\x -> (id x, (para f x))) . out

apo :: Corecursive f => CoAlgebra2 f (Either f a) a -> a -> f
apo f = embed . fmap (either id (apo f)) . f

--apo :: Functor f => RCoAlgebra f a -> a -> Fix f
--apo f = In . (fmap (either id (apo f))) . f

zygo :: Recursive f => Algebra2 f (b, a) a -> Algebra f b -> f -> a
zygo g f = g . fmap ((,) <$> cata f <*> zygo g f) . project

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