module Main where

import Debug.Trace

ackermannStrict :: Int -> Int -> Int
--ackermannStrict m n | trace("Calculating Ackerman of " ++ show m ++ " " ++ show n) False = undefined
ackermannStrict 0 !n  = n + 1
ackermannStrict !m 0  = ackermannStrict (m - 1) 1
ackermannStrict !m !n = ackermannStrict (m - 1) inner where
    inner = ackermannStrict m (n - 1)

main :: IO ()
main = do
    print (ackermannStrict 4 0)
