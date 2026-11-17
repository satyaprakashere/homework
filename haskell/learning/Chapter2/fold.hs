{-# LANGUAGE BangPatterns #-}

module Main where

import System.Random (randomRIO)

randomList :: Int -> IO([Int])
randomList 0 = return []
randomList n = do
    r  <- randomRIO (1,9999)
    rs <- randomList (n-1)
    return (r:rs) 

folds f !z []            = z
folds f !z (x:xs)        = folds f (f z x) xs

foldrs f z []     = z
foldrs f z (x:xs) = x `f` foldrs f z xs

sum1 = folds (+) 0

try1 = sum [1, 4, 2,45 ,57 ,67, 6, 76, 7,67,67,6,7,6, 7,6,7,67,6,45,6,34,5,4]

try2 = randomList 10000000 >>= print . sum1

main :: IO ()
main = try2
