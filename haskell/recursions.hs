module Main where

import Data.List

main :: IO ()
main = do
  putStrLn "Hello World"
  print $ compos head [sort] [1, 3, 2, 9]

compos h g argk = h (fmap (\f -> f argk) g)

-- applyN :: (a -> b) -> [a] -> b
-- applyN f (x:xs) = applyN (f x) xs
-- applyN f []     = fgh

-- Usage:
-- f x y z = x + y * z
-- applyN f [2,3,4]  -- 14
