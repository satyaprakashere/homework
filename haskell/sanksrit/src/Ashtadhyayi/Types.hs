{-# LANGUAGE OverloadedStrings #-}

module Ashtadhyayi.Types where

import Data.Text (Text)
import qualified Data.Text as T

-- | Represents the duration of a vowel
data Kala = Hrasva | Dirgha | Pluta
  deriving (Eq, Ord)

instance Show Kala where
  show Hrasva = ""
  show Dirgha = " (Dirgha)"
  show Pluta = "3"

-- | Represents the accent of a vowel
data Svara = Udatta | Anudatta | Svarita
  deriving (Eq, Ord)

instance Show Svara where
  show _ = "" -- Not showing accent for now in basic text

-- | Fundamental phonetic unit
data Varna
  = A Kala Svara Bool -- matches 'a', 'aa', etc. Bool is for nasalization (Anunasika)
  | I Kala Svara Bool
  | U Kala Svara Bool
  | R Kala Svara Bool
  | L Kala Svara Bool -- 'lrb'
  | E -- e (always long in Panini terms)
  | O -- o
  | Ai -- ai
  | Au -- au
  | Ka
  | Kha
  | Ga
  | Gha
  | Nga
  | Ca
  | Cha
  | Ja
  | Jha
  | Nya
  | Tta
  | Ttha
  | Dda
  | Ddha
  | Nna
  | Ta
  | Tha
  | Da
  | Dha
  | Na
  | Pa
  | Pha
  | Ba
  | Bha
  | Ma
  | Ya Bool -- Bool for nasal
  | Ra
  | La Bool -- Bool for nasal
  | Va Bool -- Bool for nasal
  | Sha
  | Ssa
  | Sa
  | Ha
  | Anusvara
  | Visarga
  deriving (Eq, Ord)

-- | A term is a sequence of Varnas
type Pada = [Varna]

-- | A Pratyahara is essentially a list of Varnas denoted by a start and end marker
newtype Pratyahara = Pratyahara [Varna]
  deriving (Eq)

instance Show Pratyahara where
  show (Pratyahara vs) = T.unpack (renderPada vs)

instance Show Varna where
  -- For single Varna, we usually show the character.
  -- If it's a consonant, show with Halant to indicate pure consonant.
  show v = T.unpack (varnaToChar v)

-- | Map Varna to its independent Devanagari representation or base form
varnaToChar :: Varna -> Text
-- Simple Vowels
varnaToChar (A Hrasva _ _) = "अ"
varnaToChar (A Dirgha _ _) = "आ"
varnaToChar (A Pluta _ _) = "आ३"
varnaToChar (I Hrasva _ _) = "इ"
varnaToChar (I Dirgha _ _) = "ई"
varnaToChar (I Pluta _ _) = "ई३"
varnaToChar (U Hrasva _ _) = "उ"
varnaToChar (U Dirgha _ _) = "ऊ"
varnaToChar (U Pluta _ _) = "ऊ३"
varnaToChar (R Hrasva _ _) = "ऋ"
varnaToChar (R Dirgha _ _) = "ॠ"
varnaToChar (R Pluta _ _) = "ऋ३"
varnaToChar (L Hrasva _ _) = "ऌ"
varnaToChar (L Dirgha _ _) = "ॡ"
varnaToChar (L Pluta _ _) = "ऌ३"
varnaToChar E = "ए"
varnaToChar O = "ओ"
varnaToChar Ai = "ऐ"
varnaToChar Au = "औ"
-- Consonants (showing with Halant implies pure consonant)
varnaToChar Ka = "क्"
varnaToChar Kha = "ख्"
varnaToChar Ga = "ग्"
varnaToChar Gha = "घ्"
varnaToChar Nga = "ङ्"
varnaToChar Ca = "च्"
varnaToChar Cha = "छ्"
varnaToChar Ja = "ज्"
varnaToChar Jha = "झ्"
varnaToChar Nya = "ञ्"
varnaToChar Tta = "ट्"
varnaToChar Ttha = "ठ्"
varnaToChar Dda = "ड्"
varnaToChar Ddha = "ढ्"
varnaToChar Nna = "ण्"
varnaToChar Ta = "त्"
varnaToChar Tha = "थ्"
varnaToChar Da = "द्"
varnaToChar Dha = "ध्"
varnaToChar Na = "न्"
varnaToChar Pa = "प्"
varnaToChar Pha = "फ्"
varnaToChar Ba = "ब्"
varnaToChar Bha = "भ्"
varnaToChar Ma = "म्"
varnaToChar (Ya _) = "य्"
varnaToChar Ra = "र्"
varnaToChar (La _) = "ल्"
varnaToChar (Va _) = "व्"
varnaToChar Sha = "श्"
varnaToChar Ssa = "ष्"
varnaToChar Sa = "स्"
varnaToChar Ha = "ह्"
-- Modifiers
varnaToChar Anusvara = "ं"
varnaToChar Visarga = "ः"

-- | Map Vowel to Matra (dependent form)
vowelMatra :: Varna -> Text
vowelMatra (A Hrasva _ _) = "" -- Inherent
vowelMatra (A Dirgha _ _) = "ा"
vowelMatra (A Pluta _ _) = "ा३"
vowelMatra (I Hrasva _ _) = "ि"
vowelMatra (I Dirgha _ _) = "ी"
vowelMatra (I Pluta _ _) = "ी३"
vowelMatra (U Hrasva _ _) = "ु"
vowelMatra (U Dirgha _ _) = "ू"
vowelMatra (U Pluta _ _) = "ू३"
vowelMatra (R Hrasva _ _) = "ृ"
vowelMatra (R Dirgha _ _) = "ॄ"
vowelMatra (R Pluta _ _) = "ृ३"
vowelMatra (L Hrasva _ _) = "ॢ"
vowelMatra (L Dirgha _ _) = "ॣ"
vowelMatra (L Pluta _ _) = "ॢ३"
vowelMatra E = "े"
vowelMatra O = "ो"
vowelMatra Ai = "ै"
vowelMatra Au = "ौ"
vowelMatra _ = ""

-- | Check if Varna is a Vowel
isScalarVowel :: Varna -> Bool
isScalarVowel (A _ _ _) = True
isScalarVowel (I _ _ _) = True
isScalarVowel (U _ _ _) = True
isScalarVowel (R _ _ _) = True
isScalarVowel (L _ _ _) = True
isScalarVowel E = True
isScalarVowel O = True
isScalarVowel Ai = True
isScalarVowel Au = True
isScalarVowel _ = False

-- | Consonant without Halant
removeHalant :: Text -> Text
removeHalant t = if T.isSuffixOf "्" t then T.init t else t

-- | Render a list of Varnas (Pada) into a properly joined Devanagari string
renderPada :: [Varna] -> Text
renderPada [] = ""
renderPada (c : v : rest)
  | not (isScalarVowel c) && isScalarVowel v =
      -- Consonant + Vowel -> Combine
      (removeHalant (varnaToChar c) <> vowelMatra v) <> renderPada rest
renderPada (c : rest)
  | not (isScalarVowel c) =
      -- Consonant alone (or followed by another consonant) -> Keep Halant
      varnaToChar c <> renderPada rest
  | otherwise =
      -- Independent Vowel
      varnaToChar c <> renderPada rest
