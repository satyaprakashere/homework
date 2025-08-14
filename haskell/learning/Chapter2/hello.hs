module Main where

import Data.List

greetUser :: IO ()
greetUser = getLine >>= \x -> putStrLn ("Hello " ++ x)

--refreshUI :: Rest a

(.:) f g x y = f (g x, g y)

main :: IO ()
main = putStrLn (show (sortBy ((<) .: length) ["abc", "sdfdf", "3"]))