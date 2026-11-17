module Main where

import Test.QuickCheck

main :: IO ()
main = do
  unitTests
  putStrLn "\nRunning randomized property checks (varying sizes):"
  quickCheck prop_lengthPreserved
  quickCheck prop_isSorted

-- Core QuickSort Implementation
quickSort :: Ord a => [a] -> [a]
quickSort [] = []
quickSort (x:xs) = quickSort left ++ [x] ++ quickSort right
  where
    left  = [a | a <- xs, a <= x]
    right = [b | b <- xs, b > x]

-------------------------------------------------------------------

-- Properties to Test Across List Sizes

-- 1. Length preservation (Size property)
prop_lengthPreserved :: [Int] -> Bool
prop_lengthPreserved xs = length (quickSort xs) == length xs

-- 2. Output is actually ordered
prop_isSorted :: [Int] -> Bool
prop_isSorted xs = isOrdered (quickSort xs)
  where
    isOrdered (a:b:rest) = a <= b && isOrdered (b:rest)
    isOrdered _          = True

-- 3. Correctness on explicit size classes
unitTests :: IO ()
unitTests = do
  putStrLn "Running explicit size-based unit tests..."
  assert "Empty list"          (quickSort ([] :: [Int]) == [])
  assert "Single element"      (quickSort [42] == [42])
  assert "Two elements"        (quickSort [5, 2] == [2, 5])
  assert "Small list"          (quickSort [3, 0, 20, 100, 47] == [0, 3, 20, 47, 100])
  assert "Duplicates list"     (quickSort [5, 1, 5, 3, 1] == [1, 1, 3, 5, 5])
  assert "Large list (10,000)" (quickSort [10000, 9999 .. 1] == [1 .. 10000])
  where
    assert label cond = putStrLn $ "  " ++ label ++ ": " ++ if cond then "PASSED" else "FAILED"
    