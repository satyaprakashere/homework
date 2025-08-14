module Main (main) where

import Text.Printf (printf)

import System.Random (randomRIO)

randomList n | n < 1 = return []
randomList n         = do
  r  <- randomRIO (1,2)
  rs <- randomList (n-1)
  return (r:rs)

step = 0.001

solve :: Int -> Int -> [Int] -> [Int] -> (Double, Double)
solve l r a b | l > r = undefined
solve l r a b         = (area, volume)
  where
    area         = nintegrate (* step)
    volume       = nintegrate ((* (pi * step)) . (^^2))

    nintegrate dx = sum (map (dx . expression) limits)
    expression x = sum . zipWith (*) af $ map (x^^) b

    lf = fromIntegral l
    rf = fromIntegral r
    af = map fromIntegral a
    limits = [lf, (lf+step)..rf]

area_under_curve = do
  input <- getContents
  mapM_ (printf "%.1f\n")
    .(\[a, b, [l, r]] -> solve l r a b)
    .map (map read. words)
    .lines $ input

test_area_under_curve = print $ solve 1 4 [1, 2, 3, 4, 5] [6, 7, 8, 9, 10]

test_area_under_curve_random = do
  l <- randomList 100
  r <- randomList 100
  print (solve 1 9 l r)


--Input/Output.
main :: IO ()
main = do
  test_area_under_curve
  test_area_under_curve_random
