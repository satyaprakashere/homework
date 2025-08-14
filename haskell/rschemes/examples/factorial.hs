module Main where

import Schemes

import Data.List
import Data.Either

import Debug.Trace

main :: IO ()
main = do
    print $ fold multiply [1,2,3,4,5,6] -- Factorial thourough product

multiply :: Num b => Algebra (List b) b
multiply Nil = 1
multiply (Cons x y) = x*y
