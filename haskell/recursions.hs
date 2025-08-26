module Main where

import Data.List

main :: IO ()
main = do
  putStrLn "Hello World"
  print $ compos head [sort] [1, 3, 2, 9]

compos h g argk = h (fmap (\f -> f argk) g)

