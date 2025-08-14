{-# LANGUAGE BangPatterns, TypeSynonymInstances #-}
module Main (main) where

import Data.List
import Data.Functor.Identity
import Control.Monad
import Text.Printf (printf)
import System.Random (randomRIO)

lowerb = 10
upperb = 100

randomNum n = return randomRIO (lowerb, upperb)

randomList n | n < 1 = return []
randomList n         = do
    r  <- randomRIO (lowerb,upperb)
    rs <- randomList (n-1)
    return (r:rs)
    
type List a = [a]
newtype Mat a = Mat [[a]]

class Matrix mat where
    add :: mat a -> mat a -> mat a
    subt :: mat a -> mat a -> mat a

--class MatrixMutl m where
--    (*) :: Matrix m1 => m a -> m1 a -> m1 a
--

--instance Matrix Mat where
--  add :: Mat a -> Mat a -> Mat a
--  subt :: Mat a -> Mat a -> Mat a
--
--  add = zipWith . zipWith $ (+)
--  subt = zipWith . zipWith $ (-)

--instance MatrixMutl Mat where
--    (*) = mult
--    
--instance MatrixMutl List where
--    (*) = mult
--
--instance MatrixMutl Identity where
--    (*) = mult

randomMatrix n _ | n < 1   = return []
randomMatrix n m           = do
    r  <- randomList m
    rs <- randomMatrix (n-1) m
    return (r:rs)

trace t []          = t
trace t [m]         = trace (t + head m) []
trace t (m:ms)      = trace (t + head m) (map tail ms)

--zipWithM :: (Int -> Int -> Int) -> [[Int]] -> [[Int]] -> [[Int]]
--zipWithM f [] mat2            = []
--zipWithM f mat1 []            = []
--zipWithM f (m1:ms1) (m2:ms2)  = zipWithM f m1 m2 : add ms1 ms2

--add = zipWith . zipWith $ (+)
--
--subt = zipWith . zipWith $ (-)

mult m1 m = map (`multV` m) m1

multR m = map (`multV` m)

multV [] _ = repeat 0
multV _ [] = repeat 0
multV v m = zipWith (+) (uncurry multS (head v, head m)) (uncurry multV (tail v, tail m))

--transpose :: Num a => Mat a -> Mat a
--transpose (m:ms) = reduce (map (\x -> [x] m)) (\x -> [x]) (a, x -> _ ) // TODO

multS s = map (*s)

multOld m1 m2 = multOldHelper m1 (transpose m2)

multOldHelper [] _ = []
multOldHelper !(m1:ms1) !m = multOldV m1 m : multOldHelper ms1 m

multOldV _ [] = []
multOldV v (m:ms) = sum (zipWith (*) v m) : multOldV v ms

--Solution
--solve :: Mat Int -> Mat Int -> Bool
--solve m1 m2 = mult m1 m2 == multOld m1 m2

--Input/Output
main :: IO ()
main = testWithRandoms

----------------------------------Test code-----------------------------------------------
testWithRandoms = do
    tc <- randomRIO (10, 10)
    replicateM_ tc $ do
        mat1  <- randomMatrix 99 234::IO ([[Int]])
        mat2  <- randomMatrix 234 110::IO ([[Int]])
--      print $  (multR mat2 mat1) == (multOld mat1 mat2)
--      print . trace 0 $ multOld mat1 mat2
        print . trace 0 $ multR mat1 mat2
--      print . trace 0 $ transpose mat2
--      print $ mult mat1 mat2