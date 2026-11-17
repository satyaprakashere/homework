import Control.Monad

valid :: [(Int, Int)] -> Bool
valid f = True

list2Tup (a:b:[]) = (a, b)

main = do
    t <- readLn
    replicateM t $ do
        n <- fmap read getLine
        func <- replicateM n . fmap (list2Tup.map read.words) $ getLine
        putStrLn $ if valid func then "YES" else "NO"