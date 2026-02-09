{-# LANGUAGE BangPatterns,DeriveFunctor,TypeFamilies,TypeSynonymInstances, FlexibleInstances #-}

module Main where

import Data.Array

data State = Null
           | Node String State State deriving (Show)

valid :: State -> Bool
valid state = case state of
                  Null            -> undefined
                  Node string _ _ -> null string

pat = "bab"

match :: String -> String -> [Int]
match pattern = map fst . filter (valid . snd) . scanl step (0, root)

root = build Null pat

step (length, state) token = (length + 1, op state token)
   op state token = case state of
      Null                   -> root
      Node [] left _         -> op left token
      Node (x:xs) left right -> if x /= token then op left token else right

build left pattern = case pattern of
    []   -> Node [] left Null
    x:xs -> Node pattern left (build (op left x) xs)

refold :: Functor s => (s b -> b) -> (a -> s a) -> a -> b
refold f g = go where go a = f (fmap go (g a))

matches :: String -> String -> [Int]
matches pat str = refold f g (pat, str, listArray (0, length pat) [], 0, 0) where
   f = undefined
   g (pat, str, helper, j, k) = case (head pat) == (head str) of
      True -> case k == length pat of
         True -> Cons (j-k) (tail pat, tail str, helper, j+1, k+1)
         False -> Cons (-1) (tail pat, tail str, helper, j+1, k+1)
      False -> case k < 0 of
         True -> Cons (-1) (tail pat, tail str, helper, j+1, k+1)
         False -> Cons (-1) (tail pat, tail str, helper, j, helper ! k)


main = do
--     pattern <- getLine
--     text    <- getLine
--     print $ match pattern text
      print $ root
--    print $ match "bab" "bababbab"

newtype Fix f = Fix { unfix :: f (Fix f)}

data ListF a r = Nil a | Cons a r deriving (Show, Functor)
type List a = Fix (ListF a)

--algorithm kmp_search:
-- input:
--    an array of characters, S (the text to be searched)
--    an array of characters, W (the word sought)
-- output:
--    an array of integers, P (positions in S at which W is found)
--    an integer, nP (number of positions)
--
-- define variables:
--    an integer, j ← 0 (the position of the current character in S)
--    an integer, k ← 0 (the position of the current character in W)
--    an array of integers, T (the table, computed elsewhere)
--
-- let nP ← 0
--
-- while j < length(S) do
--    if W[k] = S[j] then
--       let j ← j + 1
--       let k ← k + 1
--       if k = length(W) then
--          (occurrence found, if only first occurrence is needed, m ← j - k  may be returned here)
--          let P[nP] ← j - k, nP ← nP + 1
--          let k ← T[k] (T[length(W)] can't be -1)
--    else
--       let k ← T[k]
--       if k < 0 then
--          let j ← j + 1
--          let k ← k + 1
