module Main (main) where

import System.Environment (getArgs)
import ReadExpr(readExpr)

main :: IO ()
main = do
    args <- getArgs
    case readExpr (head args) of
        Left err -> print err
        Right val -> print val
