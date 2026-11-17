{-# LANGUAGE TupleSections #-}

module Main where

-- Primitive functions

-- 1. Zero function
zero :: a -> Integer
zero _ = 0

-- 2. Successor function
succ' :: Integer -> Integer
succ' = (+1)

-- 3. Projection functions
proj1 :: (a, b) -> a
proj1 = fst

proj2 :: (a, b) -> b
proj2 = snd

proj3_1 :: (a, b, c) -> a
proj3_1 (x, _, _) = x

proj3_2 :: (a, b, c) -> b
proj3_2 (_, y, _) = y

proj3_3 :: (a, b, c) -> c
proj3_3 (_, _, z) = z

-- Function building rules

-- 4. Composition
compose :: (b -> c) -> (a -> b) -> a -> c
compose = (.)

-- For multiple argument composition
compose2 :: (b -> c -> d) -> (a -> b) -> (a -> c) -> a -> d
compose2 f g1 g2 x = f (g1 x) (g2 x)

-- 5. Primitive Recursion
primRec :: (a -> Integer) -> (a -> Integer -> Integer -> Integer) -> a -> Integer -> Integer
primRec g h = f
    where
        f x 0     = g x                     -- base case
        f x y     = h x (y-1) (f x (y-1))   -- recursive case

-- Examples built with primitive recursion

-- Addition
add :: Integer -> Integer -> Integer
add = primRec id (\x y r -> succ' r)

-- Multiplication
mul :: Integer -> Integer -> Integer
mul = primRec (const 0) (\x y r -> add x r)

-- Exponentiation
expn :: Integer -> Integer -> Integer
expn = primRec (const 1) (\x y r -> mul x r)

-- Bounded predecessor (safe)
pred' :: Integer -> Integer
pred' 0 = 0
pred' n = n - 1

-- Factorial
fact :: Integer -> Integer
fact n = primRec (const 1) (\_ y r -> mul r (succ' y)) () n

-- Test
main :: IO ()
main = do
  putStrLn "Primitive Recursive Functions in Haskell"
  print $ add 3 4       -- 7
  print $ mul 3 4       -- 12
  print $ expn 2 5      -- 32
  print $ pred' 0       -- 0
  print $ pred' 10      -- 9
  print $ fact 5        -- 120


-- μ-operator (unbounded minimization)
-- Returns the least y such that f x y == 0
mu :: (a -> Integer -> Integer) -> a -> Integer
mu f x = go 0 where
    go y
        | f x y == 0 = y
        | otherwise  = go (y + 1)


muBounded :: Integer -> (a -> Integer -> Integer) -> a -> Maybe Integer
muBounded maxY f x = go 0 where
    go y
        | y > maxY     = Nothing
        | f x y == 0   = Just y
        | otherwise    = go (y + 1)
