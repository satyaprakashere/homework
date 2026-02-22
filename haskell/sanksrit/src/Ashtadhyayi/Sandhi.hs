module Ashtadhyayi.Sandhi where

import Ashtadhyayi.Types
import Ashtadhyayi.Phonology
import Data.List (findIndex)

-- | Check if a Varna matches a prototype (ignoring duration/accent/nasalization for vowels)
-- This is a simplified "Savarna" check.
isHomogeneous :: Varna -> Varna -> Bool
isHomogeneous (A _ _ _) (A _ _ _) = True
isHomogeneous (I _ _ _) (I _ _ _) = True
isHomogeneous (U _ _ _) (U _ _ _) = True
isHomogeneous (R _ _ _) (R _ _ _) = True
isHomogeneous (L _ _ _) (L _ _ _) = True
isHomogeneous v1 v2 = v1 == v2

-- | Check if a Varna belongs to a Pratyahara (Savarna inclusion)
inPratyahara :: Varna -> [Varna] -> Bool
inPratyahara v pList = any (isHomogeneous v) pList

-- | Eco yanaci (6.1.77)
-- ik (i, u, r, l) -> yan (y, v, r, l) when followed by ac (vowel)
-- Note: 'yan' replacement order corresponds to 'ik' order (1.3.10)
ecoYanaci :: [Varna] -> [Varna]
ecoYanaci [] = []
ecoYanaci (x:y:xs)
  | inPratyahara x ik && inPratyahara y ac = replaceIk x : ecoYanaci (y:xs)
  | otherwise = x : ecoYanaci (y:xs)
  where
    startI = I Hrasva Udatta False
    endK = Ka
    ik = formPratyahara startI endK -- i, u, r, l

    startA = A Hrasva Udatta False
    endC = Ca
    ac = formPratyahara startA endC -- all vowels

    -- Mapping logic (sthane 'ntaratamah - 1.1.50)
    -- Simplified: i->y, u->v, r->r, l->l
    replaceIk (I _ _ _) = Ya False
    replaceIk (U _ _ _) = Va False
    replaceIk (R _ _ _) = Ra
    replaceIk (L _ _ _) = La False
    replaceIk v = v -- Should not happen if guarded by inPratyahara ik

ecoYanaci (x:xs) = x : ecoYanaci xs
