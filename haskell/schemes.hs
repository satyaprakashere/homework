{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}

module Main where

import Data.Kind
import Debug.Trace
import Data.Bits ((.&.))

main = do
  print "Hello world"
  --  print $ refold addlasttwo multiply (1, 2, 6) -- product of fibonacci
  --  print $ (anaf decreasef 6 :: [Integer]) -- list thourough expansion
  --  print $ toList (anaf decrease 6) -- list thourough expansion
  --  print $ fold multiply [1, 2, 3, 4, 5, 6] -- Factorial thourough product
  --  print $ fold multiply [] -- Factorial thourough product
  --  print $ dissolve multiply2 1, 2, 3, 4, 5, 6] -- Factorial thourough product
  --  print $ dissolveWith multH multiply [1, 2, 3, 4, 5, 6] -- Factorial thourough product
  --  print $ (refold' decrease multiply 6 :: Integer) -- factorial through expansion and contraction
  --  print $ refold decrease multiply 5 -- factorial through expansion and contracion
  --  print $ (refold' decrease multiply 6 :: Integer) -- factorial through expansion and contraction
  --  print $ take 100 (unfold addlasttwo (0, 1) :: [Integer]) -- fibonacci
  --  print $ takeWhile (< 100) (unfold endsWith9 9 :: [Integer])
  print $ refold decrease multiply 98

multiply :: (Num b) => Algebra (List b) b
multiply Nil = 1
multiply (Cons x y) = x * y

multiply2 :: (Num b, Show b) => Algebra2 (List b) ([b], b) b
multiply2 w | trace ("algebra2 with input : " ++ show w) False = undefined
multiply2 Nil = 1
multiply2 (Cons x (_, z)) = x * z

multH :: (Num a, Integral a, Show a) => Algebra2 (List a) (a, a) a
multH w | trace ("helper method with input : " ++ show w) False = undefined
multH Nil = 1
multH (Cons _ (y, _)) = y - 1

addlasttwo :: (Num a) => CoAlgebra (List a) (a, a)
addlasttwo (x, y) = Cons x (y, x + y) -- 0, 1, 1, 2, 3,

decrease :: CoAlgebra (List Integer) Integer
decrease 0 = Nil
decrease n = Cons n (n - 1)

--decreasef :: CoAlg (List Integer) Integer
decreasef 0 = Nil
decreasef n = Cons n (n - 1)

endsWith9 n = Cons n (n + 10)

------------------------- Abstraction ----------------------

type family Base t :: Type -> Type

class (Functor (Base t)) => Recursive t where
  project :: t -> Base t t

class (Functor (Base t)) => Corecursive t where
  embed :: Base t t -> t

instance Recursive [a] where
  project [] = Nil
  project (x : xs) = Cons x xs

instance Corecursive [a] where
  embed Nil = []
  embed (Cons x xs) = x : xs

newtype Fix f = Fix {unFix :: f (Fix f)}

type instance Base (Fix f) = f

type Alg f a = f a -> a

type CoAlg f a = a -> f a

type Algebra f a = Base f a -> a

type CoAlgebra f a = a -> Base f a

type Algebra2 f b a = Base f b -> a

type CoAlgebra2 f b a = a -> Base f b

data FreeM f a = Pure a | FreeM a (f (FreeM f a)) deriving (Functor)

data CofreeM f a = a :< (f (CofreeM f a))

------------------------ Data types----------------------------------

data ListF a r = Nil | Cons a r deriving (Show, Functor)

type List a = Fix (ListF a)

type instance Base [a] = ListF a

toList :: List a -> [a]
toList (Fix Nil) = []
toList (Fix (Cons x xs)) = x : toList xs

-- data TreeF a l r = Leaf a | Node a l r deriving Functor
-- type Tree a = Fix (TreeF a)
-- type instance Base Tree a

------------------------- Helper functions ----------------------

fold :: (Recursive f) => Algebra f a -> (f -> a)
fold = cata

unfold :: (Corecursive f) => CoAlgebra f a -> (a -> f)
unfold = ana

-- loop' :: (Recursive f, Corecursive f) => (a -> Base f a) -> (Base f b -> b) -> (a -> b)
refold' f g = fold g . unfold f

refold :: (Functor f) => CoAlg f a -> Alg f b -> (a -> b)
refold = hylo

dissolve :: (Recursive f) => Algebra2 f (f, a) a -> f -> a
dissolve = para

evolve :: (Corecursive f) => CoAlgebra2 f (Either f a) a -> a -> f
evolve = apo

dissolveWith :: (Recursive f) => Algebra2 f (b, a) a -> Algebra f b -> f -> a
dissolveWith = zygo

evolveWith :: (Corecursive f) => CoAlgebra2 f (Either b a) a -> CoAlgebra f b -> a -> f
evolveWith = gapo

-------------------------------------------------------------------

cata :: (Recursive f) => Algebra f a -> (f -> a)
cata f = f . fmap (cata f) . project

cataf :: (Functor f) => Alg f a -> (Fix f -> a)
cataf f = f . fmap (cataf f) . unFix

ana :: (Corecursive f) => CoAlgebra f a -> (a -> f)
ana f = embed . fmap (ana f) . f

anaf :: (Functor f) => CoAlg f a -> (a -> Fix f)
anaf f = Fix . fmap (anaf f) . f

hylo :: (Functor f) => CoAlg f a -> Alg f b -> (a -> b)
hylo f g = g . fmap (hylo f g) . f -- no mention of Fix!

-- hylo :: Functor f => CoAlg f a -> Alg f b -> a -> b
-- hylo f g = g . fmap (hylo f g) . f  -- no mention of Fix!

para :: (Recursive f) => Algebra2 f (f, a) a -> f -> a
para f = f . fmap ((,) <*> para f) . project

-- para :: Functor f => RAlgebra f a -> Fix f -> a
-- para f = f . fmap (\x -> (id x, (para f x))) . out

apo :: (Corecursive f) => CoAlgebra2 f (Either f a) a -> a -> f
apo f = embed . fmap (either id (apo f)) . f

-- apo :: Functor f => RCoAlgebra f a -> a -> Fix f
-- apo f = In . (fmap (either id (apo f))) . f

zygo :: (Recursive f) => Algebra2 f (b, a) a -> Algebra f b -> f -> a
zygo g f = g . fmap ((,) <$> cata f <*> zygo g f) . project

-- zygo :: Recursive f => Algebra f b -> Algebra2 f (b, a) a -> f -> a
-- zygo f g = g . fmap (\x -> (cata f x, (zygo f g x))) . project

-- zygo :: Functor f => Algebra f b ->  (f (b, a) -> a) -> Fix f -> a
-- zygo f g = snd . cata (\x -> (f $ fmap fst x, g x))

gapo :: (Corecursive f) => CoAlgebra2 f (Either b a) a -> CoAlgebra f b -> a -> f
gapo g f = embed . fmap (either (ana f) (gapo g f)) . g

mutu :: (Recursive f) => Algebra2 f (b, a) a -> Algebra2 f (b, a) b -> f -> a
mutu g f = snd . cata ((,) <$> f <*> g)

-- mutu :: Functor f => (f (b, a) -> b) -> (f (b, a) -> a) -> Fix f -> a
-- mutu f g = snd . cata (\x -> (f x, g x))

-- loop ::
