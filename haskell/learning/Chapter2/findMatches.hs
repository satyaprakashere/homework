module Main where

main :: IO ()
main = do
    txt <- readFile "day2.txt"
    print $ findMatch . lines txt

findMatch :: [String] -> String

ditance :: (String, String) -> String
distance = sum . fmap fromBool . uncurry (zipWith (/=))

fromBool False = 0
fromBool True = 1