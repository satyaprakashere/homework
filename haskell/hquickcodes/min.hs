module Main where

import Data.List

mins = head.sort

main :: IO ()
main = do
    print $ mins [43,67,3,4,43,5]
    print $ sum [1..100000000]