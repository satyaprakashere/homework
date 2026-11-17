{-# LANGUAGE BangPatterns #-}
module Main (main) where

import Data.List
import Control.Monad
import Text.Printf (printf)
import System.Random (randomRIO)

ll = 1
ul = 10

randomList n | n < 1 = return []
randomList n         = do
    r  <- randomRIO (ll,ul)
    rs <- randomList (n-1)
    return (r:rs)

randomMatrix n _ | n < 1   = return []
randomMatrix n m           = do
    r  <- randomList m
    rs <- randomMatrix (n-1) m
    return (r:rs)

trace t 0 _          = t
trace t 1 (m:[])     = trace (t + head m) 0 []
trace !t size (m:ms) = trace (t + head m) (size-1) (map tail ms)

irows res  size []     = res
irows !res size (x:xs) = irows (res + (fromEnum $ iirows size x)) size xs

iirows size []   = False
iirows size list = (product list) /= (size * (size+1)) `div` 2

--Solution
solve :: Int -> [[Int]] -> (Int, Int, Int)
solve size mat = (trace 0 size mat, irows 0 size mat, irows 0 size $ transpose mat)

solveTestCases _ []     = []
solveTestCases tc (x:xs) = uncurry solve x : solveTestCases (tc-1) xs

--Input/Output
main :: IO ()
main = do
    testWithConstants
    testWithRandoms
--    testWithInput

----------------------------------Test code-----------------------------------------------
testWithConstants = print $ solveTestCases 3 [
    (4,[[1, 2, 3, 4],[2, 1, 4, 3],[3, 4, 1, 2],[4, 3, 2, 1]]),
    (4,[[2, 2, 2, 2],[2, 3, 2, 3],[2, 2, 2, 3],[2, 2, 2, 2]]),
    (3,[[2, 1, 3],[1, 3, 2],[1, 2, 3]])]

testWithRandoms = do
    tc <- randomRIO (10, 10)
    replicateM_ tc $ do
        size <- curry randomRIO 99 999
        mat  <- randomMatrix size size
        print $ solve size mat

testWithInput = do
    tc <- readLn
    replicateM_ tc $ do
        size <- readLn
        mat  <- replicateM size $ map read.words <$> getLine
        print $ solve size mat
