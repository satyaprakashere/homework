module Main where

import Debug.Trace
import Data.Foldable

main = do
    print (addTwoNums [9,9,9,9,9,9,9] [9,9,9,9] 0)


addTwoNums :: (Integral a, Show a) => [a] -> [a] -> a -> [a]
addTwoNums m n o | trace ("adding two nums " ++ foldMap show m ++ " + " ++ foldMap show n ++ " using " ++ show o) False = undefined
addTwoNums [] [] m = [rem m 10] -- End condtion
addTwoNums xss [] m = addTwoNums xss [0] m -- Extension for the open loop
addTwoNums [] yss m = addTwoNums [0] yss m -- Extension for the open loop || rem (y+m) 10 : addTwoNums [] ys (div (y+m) 10)
addTwoNums (x:xs) (y:ys) m = rem (x+y+m) 10 : addTwoNums xs ys (div (x+y+m) 10)

--addTwoNum :: (Integral a) => [a] -> [a] -> [a]
addTwoNum x y = zipWith f x y where
    f x y = (rem (x+y) 10, div (x+y) 10)

add2 :: (Show a, Num a) => a -> a -> a
add2 x y  | trace ("adding " ++ show x ++ " and " ++ show y) False = undefined
add2 x y =  x + y
