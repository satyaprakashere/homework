module Main where

import Data.Foldable (maximumBy)
import Data.Function (on)
import Data.Maybe (catMaybes)
import qualified Data.Vector as V

type PaddedVec a = V.Vector (Maybe a)

-- https://en.wikipedia.org/wiki/Longest_palindromic_substring#Manacher.27s_algorithm
manacher :: (Eq a) => [a] -> [a]
manacher = catMaybes . V.toList . grabLongest . scan . V.fromList . padded
  where grabLongest = maximumBy (compare `on` V.length)
        padded [] = Nothing : []  -- Can't just use Data.List.intersperse; we need them wrapping outside too.
        padded (x : xs) = Nothing : Just x : padded xs
        scan = forEveryIndex 0  -- Starting at 1 could cause a fold1-exception if the input is empty

-- For every index, find the largest palindrome centered there, skipping some per Manacher's algorithm.
forEveryIndex :: (Eq a) => Int -> PaddedVec a -> [PaddedVec a]
forEveryIndex center vec = if center < (V.length vec)
                           then pal : forEveryIndex (center + (max 1 radius))  vec
                           else []
  where (pal, radius) = findAround center 1 vec

-- Find the longest palindorme centered at an index (and its "radius").
findAround :: (Eq a) => Int -> Int -> PaddedVec a -> (PaddedVec a, Int)
findAround center radius vec
  | Nothing <- left   = (priorSlice, priorRadius)  -- This is an "outer" Nothing. 
  | Nothing <- right  = (priorSlice, priorRadius)
  | left /= right     = (priorSlice, priorRadius)
  | otherwise         = findAround center (radius + 1) vec
  where left = vec V.!? (center - radius)  -- left :: Maybe (Maybe a)
        right = vec V.!? (center + radius)  -- use `forall a.` above to make these explicit.
        priorRadius = radius - 1
        priorSlice = V.slice (center - priorRadius) (1 + (priorRadius * 2)) vec

main :: IO()
main = do print $ manacher "hello world"
          print $ manacher "abacaba"
          print $ manacher "helloll world"
          print $ manacher "helloll wowrld"
          print $ manacher ""
          print $ manacher "x"
