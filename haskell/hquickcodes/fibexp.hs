{-# LANGUAGE
     DeriveFunctor,
     DeriveFoldable,
     BangPatterns,
     DeriveTraversable #-}
module Main where

import Data.Foldable
import Data.Traversable
import Data.Matrix

import qualified Data.Vector as V (replicate, Vector, generate)

fibm 0 = 0
fibm 1 = 1
fibm n = getElem 1 2 res
    where
        res = multStd rowV transM
        rowV = rowVector (V.generate 2 toInteger)
        transM = power (n-1) (fromList 2 2 [0, 1, 1, 1])
        power n mat = fastE n mat --mat ^ n

--fastE :: Int -> Matrix Integer -> Matrix Integer
fastE n mat = fastExpH (identity 2, mat, n)
    where
        fastExpH (x, a, 0) = x -- End condition
        fastExpH (x, a, b)
            | even b    = fastExpH (x, a*a, div b 2)
            | otherwise = fastExpH (x*a, a, b-1)


main :: IO ()
main = do
--  print $ rem (fibm 34538883) 999999999
--  print $ rem (fibs 345383) 10
    print (digitCount (fibm 34538))
--  print (fibm 333)
--  print (fibc 333)


----------------------Rough Work---------------------------


newtype Mu f = In {out :: f (Mu f)}
type Fix = Mu

type Algebra f a   = f a -> a
type CoAlgebra f a = a -> f a

cata :: Functor f => Algebra f a -> (Mu f -> a)
cata f = f . fmap (cata f) . out

ana :: Functor f => CoAlgebra f a -> (a -> Mu f)
ana f = In. fmap (ana f) . f

hylo :: Functor f => (a -> f a) -> (f b -> b) -> a -> b
hylo f g = g . fmap (hylo f g) . f  -- no mention of Fix!


fastExp :: Int -> Matrix Integer -> Matrix Integer
fastExp n mat = (fst3.head) . dropWhile ((/=0).trd) $ (iterate op (identity 2, mat, n))
    where
        op (x, a, b) = case even b of
            True  -> (x, a*a, div b 2)
            False -> (x*a, a, b-1)
            
fastExp2 n mat = fst3 $ hylo f g (identity 2, mat, n)
    where
        f = (take 1) . (iterate op) :: (Matrix Integer, Matrix Integer, Int) -> [(Matrix Integer, Matrix Integer, Int)]
        op (x, a, b) = case even b of
            True  -> (x, a*a, div b 2)
            False -> (x*a, a, b-1)
        g = head . dropWhile ((/=0).trd) :: [(Matrix Integer, Matrix Integer, Int)] -> (Matrix Integer, Matrix Integer, Int)
        
fst3 (a, _, _) = a
trd (_,_,c) = c

digitCount :: Integer -> Int
digitCount = go 1 . abs
    where
        go ds n = if n >= 10 then go (ds + 1) (n `div` 10) else ds
        
fibc n = round $ phi ** fromIntegral n / sq5
    where
        sq5 = sqrt 5 :: Double
        phi = (1 + sq5) / 2
        
fibs n = fib 1 0 n where
    fib res x 0 = x
    fib res x 1 = res
    fib !res x n = fib (res+x) res (n-1)
    
refold :: Functor s => (s b -> b) -> (a -> s a) -> a -> b
refold f g = go where go a = f (fmap go (g a))

--fibsr = refold f g where
--  f (x, y) = x+y
--  g (x, y) = 

almostFibs :: [(Integer, Integer)]
almostFibs = iterate (\(x, y) -> (y, x + y)) (0, 1)

fibsi :: [Integer]
fibsi = map snd almostFibs
