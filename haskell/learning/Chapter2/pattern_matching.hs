module Main where

--identity :: [a] -> Int
--identity []     = []
identity (1:[]) = (2:[])
--identity (x:xs) = undefined


main :: IO ()
main = do
    print (identity (1:[]))
    print (identity (2:[]))