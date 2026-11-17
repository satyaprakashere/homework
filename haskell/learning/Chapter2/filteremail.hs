module Main where

import Prelude
import Data.Set (Set, empty, insert, size)
import Data.List (isInfixOf, elemIndex)
import Data.Maybe(fromMaybe)


filterEmail :: Set String -> [String] -> Int
filterEmail uniqueEmails [] = size uniqueEmails
filterEmail uniqueEmails (x:xs) = filterEmail (insert fx uniqueEmails) xs where
    fx = case x of
        x | isInfixOf "." x -> filter (\c -> c == '.') x
        x | isInfixOf "+" x -> (take (fromMaybe (length x) (elemIndex '+' x)) x) ++ (drop (fromMaybe (length x) (elemIndex '@' x)) x)
        x -> x

main :: IO ()
main = do
--    emails <- fmap lines getContents
--    print emails
    print (filterEmail empty ["sds", "dfsdfsd", "sd.s", "dfsdfsd+", "asdf@co", "asdf+sds@co"])