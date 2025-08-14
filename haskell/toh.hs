module Main where

import Data.Bits

hanoi :: Int -> [(Int, Int)]
hanoi n = map (\x -> ((x .&. (x-1)) `mod` 3, ((x .|. (x-1)) + 1) `mod` 3)) [1..shift 1 n]

main = print $ hanoi 5