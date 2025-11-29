module Main where

import Data.List (sort)
import Data.Ord

-- Time complexity (nLogn)
twoSum :: (Num a, Ord a) => [a] -> a -> (a, a)
twoSum nums target = find (sort nums) where
		find list = findR list (reverse list)
		findR (x:xs) (y:ys) = case compare (x + y) target of
			EQ -> (x, y)
			LT -> findR xs (y:ys)
			GT -> findR (x:xs) ys

main :: IO ()
main = print (twoSum [-11, 20, -2, 7] 18)
