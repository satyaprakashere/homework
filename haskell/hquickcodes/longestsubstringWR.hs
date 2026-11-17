module Main where

import Data.Array
import Data.Map

find :: String -> String
find str = helper "" "" empty::Map Char  str
    where helper res x used str = case lookup (head str) used of
        Just _ -> case size x > size res of
            True -> helper x "" empty (tail str)
            False -> helper res "" empty (tail str)
        Nothing -> case used == [] of
            True -> res
            False -> Helper res (x+1) (addElem (head str) used) (tail str))

main :: IO ()
main = putStrLn "Hello World"