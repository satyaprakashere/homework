{-# LANGUAGE BangPatterns, DeriveFunctor, TypeFamilies, TypeSynonymInstances, FlexibleInstances, FlexibleContexts, RankNTypes, MultiWayIf #-}

module Main where

import Data.Array
import Data.Either


import Data.Array (Array, Ix (rangeSize), bounds, (!))
import LCUtils.Utils (array)
import Optics

solve ::
  forall a b f.
	( Foldable f,
		Bounded a,
		Ord a,
		Real a,
		Fractional b
	) =>
	f a ->
	f a ->
	b
solve ((^. array) -> lhs) ((^. array) -> rhs) = solve' lhs rhs
	where
		solve' :: Array Int a -> Array Int a -> b
		solve' larr@(rangeSize . bounds -> llen) rarr@(rangeSize . bounds -> rlen)
			| rlen < llen = solve' rarr larr
			| otherwise = go (1, llen)
			where
				totalLen = llen + rlen
				(half, rem) = totalLen `divMod` 2
				
				go :: (Int, Int) -> b
				go (!l, !r) =
						if
							| lei <= rei'next && rei <= lei'next -> case rem of
								0 -> realToFrac (min lei'next rei'next + max lei rei) / 2
								_ -> min lei'next rei'next & realToFrac
							| rei'next < lei -> go (l, li -1)
							| otherwise -> go (li + 1, r)
					where
						li = (l + r) `div` 2
						ri = half - li
						lei
							| 1 <= li = larr ! li
							| otherwise = minBound @a
						lei'next
							| li + 1 <= llen = larr ! (li + 1)
							| otherwise = maxBound @a
						rei
							| 1 <= ri = rarr ! ri
							| otherwise = minBound @a
						rei'next
							| ri + 1 <= rlen = rarr ! (ri + 1)
							| otherwise = maxBound @a
										

main :: IO ()
main = do
	print $ solve [3,4,5] [1, 2, 3, 7, 8]

------------------------- Helper functions ----------------------

type family Base t :: * -> *

class Functor (Base t) => Recursive t where
	project :: t -> Base t t
	
class Functor (Base t) => CoRecursive t where
	embed :: Base t t -> t
	
newtype Fix f = In { out :: f (Fix f)}

type instance Base (Fix f) = f
instance Functor f => Recursive (Fix f) where
	project (In a) = a
instance Functor f => CoRecursive (Fix f) where
	embed = In

data ListF a r = Nil a | Cons a r deriving (Show, Functor)
type List a = Fix (ListF a)
type instance Base [a] = ListF a

instance Recursive [a] where
	project [a] = Nil a
	project (x:xs) = Cons x xs

instance CoRecursive [a] where
	embed (Nil a) = [a]
	embed (Cons x xs) = (x:xs)

type Algebra f a   = f a -> a
type CoAlgebra f a = a -> f a
type RAlgebra f a = f (Fix f, a) -> a
type RCoAlgebra f a = a -> f (Either (Fix f) a)

type Alg t a = Base t a -> a

data FreeM f a = Pure a | FreeM a (f (FreeM f a)) deriving (Functor)
data CofreeM f a = a :< (f (CofreeM f a))

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


--
------------------------ Rough work -----------------------------------
--
--solve :: Int -> Int -> Array Int Int -> Array Int Int -> Int
--solve n m nums1 nums2
--	| a == b && (n == (y-m)) = a
--	| m == (div m 2) && n < (y-m) = solve n x nums1 nums1
--	| n == (div (n + x) 2) && n < (y-m) = solve 0 m nums2 nums2
--	| a < b && n <= (y-m) = solve (div (n+x) 2) m nums1 nums2
--	| a > b  && n >= (y-m) = solve n (div (y+m) 2) nums1 nums2
--	| otherwise = -1
--	where
--		a = nums1 ! n
--		b = nums2 ! m
--		x = length nums1
--		y = length nums2
--		nm = n + m
--		
--solveAbstract :: Array Int Int -> Array Int Int -> Float
--solveAbstract nums1 nums2 = fn nums1 nums2
--	where
--		median sorted = case (rem len 2) of
--			0 -> div 2 (sorted!len + sorted!(len+1))
--			1 -> sorted!((div 2 len) + 1)
--			where
--				len = length sorted
--		fn = fnH 0 ((length nums1) - 1) 0 ((length nums2) - 1) (div (length nums1 - 1 ) 2) (div (length nums2 - 1) 2)
--		g e a = a
--		avgI a b = div (a+b) 2
--		avg :: Int -> Int -> Float
--		avg a b = (fromIntegral a + fromIntegral b) / 2
--		fnH:: Int -> Int -> Int -> Int -> Int -> Int -> Array Int Int -> Array Int Int -> Float
--		fnH l1 r1 l2 r2 mid1 mid2 nums1 nums2
--			| (s < t) && mid1 /= r1 && mid2 /= l2 = fnH mid1 r1 l2 mid2 (avgI mid1 r1) (avgI l2 mid2) nums1 nums2
--			| (s > t) && mid1 /= l1 && mid2 /= r2 = fnH l1 mid1 mid2 r2 (avgI l1 mid1) (avgI mid2 r2) nums1 nums2
--			| l1 /= r1 && l2 /= r2 = avg s t
--			| l1 /= r1 && l2 == r2 = avg s x
--			| l1 == r1 && l2 == r2 = avg a x
--			| l1 == r1 && l2 /= r2 = avg a t
--			| (s == t) = fromIntegral s
--			| otherwise = undefined
--			
--			
--			where
--				a = nums1!l1
--				b = nums1!r1
--				x = nums2!l2
--				y = nums2!r2
--				
--				s = nums1!mid1
--				t = nums2!mid2
--				totalL = (length nums1) + (length nums2)