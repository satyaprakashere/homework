module Main where
import Data.Primitive.Array

arr = arrayFromList [10, 20, 30] :: Array Int

main :: IO ()
main = do
	putStrLn "Hello World"
	print $ indexArray arr 1  -- => 20
