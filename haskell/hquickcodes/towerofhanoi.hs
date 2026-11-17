module Main where
import Debug.Trace

moveBlocks a b = (from, to, aux) where
    (from, to, aux, n) = moveBlocksH a b [] (length a)

--moveBlocksH :: [Int] -> [Int] -> [Int] -> Int -> ([Int], [Int], [Int], Int)
moveBlocksH from to aux n
    | trace ("moving Block from " ++ show from ++ " to " ++ show to ++ " uisng " ++ show aux) False = undefined
moveBlocksH from to aux 1
    | (headZ from) < (headZ to)  = (tail from, (head from):to, aux, 0) -- Base case
    | otherwise = (from, to , aux, 0) -- End condition
moveBlocksH from to aux n = (f2, t2, a2, d2) where -- Recursive case
        (a2, t2, f2, d2) = moveBlocksH a t f (n-1)
        (f, t, a, d) = moveBlocksH f1 t1 a1 1
        (f1, a1, t1, d1) = moveBlocksH from aux to (n-1)
                            
headZ :: [Int] -> Int
headZ [] = maxBound
headZ (x:xs) = x

main :: IO ()
main = do
    putStrLn "Hello World"
    print $ hanoi 5 [1, 2, 3, 4, 5] [] []
--  print $ moveBlocks [1, 2, 3, 5, 6] [7, 8]
    
-- Alternative solution
    
hanoi n a b c = hanoiToList n a b c []
    where
        hanoiToList 0 _ _ _ = id
        hanoiToList n a b c = hanoiToList (n-1) a c b . ((a, b) :) . hanoiToList (n-1) c b a