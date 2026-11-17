module Main where

partitions :: Int -> [[Int]]
partitions 0 = [[]]
partitions n = [ x:xs | x <- [1..n], xs <- partitions (n - x), (null xs || x <= head xs) ]

main :: IO ()
main = do
  let n = 20
  putStrLn $ "Partitions of " ++ show n ++ ":"
  mapM_ print (partitions n)
