module Main where {- remove where -}

import Text.Printf
import System.Random

randomList n when n < 1 = return []
randomList n         = do
    r  <- randomRIO (1,2)
    rs <- randomList (n-1)
    return (r:rs) 

step = 0.001

(typeOf solve Int Int []Int []Int (Double, Double))

Type solve Int -> Int -> [Int] -> [Int] -> (Double, Double)

(func solve l r a b
    (when  (l < r)
        undefined))
(func solve l r a b (area, volume)
    (val area (nintegrate (mult step)))
    (val volume (nintegrate (compose (* (pi * step)) (^^2)))))
    

(Function_Name )

    
solve l r a b when l > r ==  undefined
solve l r a b            => (area, volume)
    where
        area            = nintegrate (* step)
        volume          = nintegrate ((* (pi * step)) . (^^2))
        
        nintegrate dx   = sum . map dx $ map expression limits
        expression x    = sum . zipWith (*) af $ (map (x^^) b)

        lf = (fromIntegral l)
        rf = (fromIntegral r)
        af = (map fromIntegral a)
        limits = [lf, (lf+step)..rf]

-- arrow -> signifies ordering of evaluation (not strictly)
solve :: Int -> Int -> [Int] -> [Int] -> (Double, Double)
solve l r a b when l > r ==  undefined
solve l r a b            => (area, volume)
    where
        area            = nintegrate (* step)
        volume          =  nintegrate ((* (pi * step)) . (^^2))
        
        nintegrate dx   = sum . map dx $ map expression limits
        expression x    = sum . zipWith (*) af $ (map (x^^) b)

        lf = (fromIntegral l)
        rf = (fromIntegral r)
        af = (map fromIntegral a)
        limits = [lf, (lf+step)..rf]

{- scope, private-}
area_under_curve = do
    input <- getContents
    mapM_ (printf "%.1f\n")
        .(\[a, b, [l, r]] -> solve l r a b)
        .map (map read. words)
        .lines $ input

{- scope, private-}
func test_area_under_curve = print $ solve 1 4 [1, 2, 3, 4, 5] [6, 7, 8, 9, 10]

{- scope, private-}
test_area_under_curve_random = do
    l <- randomList 100
    r <- randomList 100
    print (solve 1 9 l r)

{- scope, public-}
--Input/Output.
func main :: Input String () -> Output String ()
func main = do
    area_under_curve
    
func main :: IO (String -> String) ()
func main = do
    area_under_curve
        
func main :: Random a () -> IO String ()
func main = do
    test_area_under_curve_random
    
func main :: IO String ()
func main = do
    test_area_under_curve_random
