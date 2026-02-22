module Main where

import Prelude
import Effect (Effect)
import Effect.Console (log)

fact :: Int -> Int -> Int
fact res 1 = res
fact res n = fact (res * n) (n - 1)

main :: Effect Unit
main = do
  log $ show $ fib 0 1 98765432

fib :: Int -> Int -> Int -> Int
fib a b n
  | n == 0 = a
  | otherwise = fib b (b + a) (n - 1)