module Main where

main::IO()
main = do
 args <- getArgs
 let evaled = liftM show $ readExpr (head args) >>= eval in
     putStrLn $ extractValue $ trapError evaled