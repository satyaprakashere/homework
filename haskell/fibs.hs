{-# LANGUAGE BangPatterns #-}

module Main where

import Data.Function (fix)

-- import Data.Typeable

-- numDigits
numDigits :: Integer -> Integer
numDigits n
  | n < 99999999999 = n
  | otherwise = toInteger . length $ show n

main :: IO ()
main = do
  --  print $ rem (fibss 345383 0 1) 100000000
  print $ take 100 fibsLinearTM

fibss 2 sn1 sn2 = sn1 + sn2
fibss n sn1 !sn2 = fibss (n - 1) sn2 (sn1 + sn2)

-- fn fn-1 [[]]^n fn+1 fn
fibsLinearTM :: [Integer]
fibsLinearTM = 0 : 1 : zipWith (+) fibsLinearTM (tail fibsLinearTM) -- adding and moving infinite series
-- S                  = 0   1   1 2 3 5.........2S..........
-- (tail S)           = 1   1   2 3 5...........2S........
-- (S+(tail S)        = 1   2   3 5..............

fibsLTM :: Int -> Integer
fibsLTM n = fibsLinearTM !! n

fibConstantT n = round $ phi ** fromIntegral n / sq5
  where
    sq5 = sqrt 5 :: Double
    phi = (1 + sq5) / 2

-------------------- Rough Work ------------------------

---- catamorphism
-- cata :: Functor f => (f b -> b) -> Mu f -> b
-- cata f = f . fmap (cata f) . unMu
--
---- anamporhism (catamorphism dual)
-- ana :: Functor f => (a -> f a) -> a -> Mu f
-- ana f a = Mu $ fmap (ana f) (f a)
--
---- hylomorphism (anamorphism and catamorphism composition)
-- hylo :: Functor f => (a -> f a) -> (f b -> b) -> a -> b
-- hylo f g = cata g . ana f
--
---- dynamorphism
-- dyna :: Functor f => (a -> f a) -> (f (Cofree f b) -> b) -> a -> b
-- dyna fa fc = extract . hylo fa (\fb -> fc fb :< fb)

-- Natural numbers
-- data Nat a = Zero | Succ a

-- instance Functor Nat where
-- fmap f (Succ a) = Succ $ f a
-- fmap _ Zero     = Zero

-- nat :: b -> (a -> b) -> Nat a -> b
-- nat b _ Zero     = b
-- nat _ f (Succ a) = f a

-- getN_1 :: Cofree Nat a -> a
-- getN_1 = extract

-- getN_2 :: a -> Cofree Nat a -> a
-- getN_2 a (_ :< as) = nat a getN_1 as

-- fib :: Integer -> Integer
-- fib = dyna gen crush where
-- gen 0 = Zero
-- gen n = Succ (n - 1)
--
-- crush Zero      = 0
-- crush (Succ ns) = let n_1 = getN_1 ns
--                    n_2 = getN_2 1 ns in n_1 + n_2

fib1 = (map fib' [0 ..] !!)
  where
    fib' 1 = 1
    fib' 2 = 1
    fib' n = fib1 (n - 2) + fib1 (n - 1)

fib2 n = map fib' [0 ..] !! n
  where
    fib' 1 = 1
    fib' 2 = 1
    fib' n = fib2 (n - 2) + fib2 (n - 1)

fib3 n = f n
  where
    f i = xs !! i
    xs = map fib' [0 ..]
    fib' 1 = 1
    fib' 2 = 1
    fib' n = f (n - 2) + f (n - 1)

fib4 n = fix (memoize . fib') n
  where
    fib' f 1 = 1
    fib' f 2 = 1
    fib' f n = f (n - 2) + f (n - 1)

memoize f = (map f [0 ..] !!)

fib' f 0 = 0
fib' f 1 = 1
fib' f n | n > 1 = f (n - 1) + f (n - 2)

slow_fib = fib' slow_fib

fibs = map (fib' fib5) [0 ..]

fib5 n = fibs !! n

data Cofree f a = a :< (f (Cofree f a))

-- Fix point
newtype Mu f = Mu {unMu :: f (Mu f)}

extract :: Cofree f a -> a
extract (a :< _) = a
