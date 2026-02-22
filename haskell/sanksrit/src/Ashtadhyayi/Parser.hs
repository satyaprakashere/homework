{-# LANGUAGE OverloadedStrings #-}

module Ashtadhyayi.Parser where

import Ashtadhyayi.Types
import Data.Text (Text)
import qualified Data.Text as T

-- | Parse a Devanagari string into a list of Varnas
-- This is a simplified direct mapping parser. It assumes standard Unicode Devanagari.
-- It needs to handle:
-- 1. Independent vowels (e.g. 'अ', 'आ') -> Varna
-- 2. Consonants with Halant (e.g. 'क्') -> Pure Consonant
-- 3. Consonants with Matras (e.g. 'का', 'कि') -> Consonant + Vowel
-- 4. Consonants with implicit 'a' (e.g. 'क') -> Consonant + 'a'

-- We process the string character by character (or grapheme by grapheme).
-- Since Haskell's String is [Char], and Text is better for Unicode, we use Text input conceptually but maybe String for list processing.

parseDevanagari :: String -> [Varna]
parseDevanagari [] = []
parseDevanagari (c : rest) =
  case lookupChar c of
    Just (Left v) -> v : parseDevanagari rest -- Independent Vowel or Special
    Just (Right consCtor) ->
      -- Found a consonant base. Check next char for Matra/Halant/Nothing
      case rest of
        (nextChar : rs) ->
          case lookupMatra nextChar of
            Just vMod -> consCtor : vMod : parseDevanagari rs -- Consonant + Matra
            Nothing ->
              if nextChar == '्' -- Halant
                then consCtor : parseDevanagari rs -- Pure Consonant
                else consCtor : (A Hrasva Udatta False) : parseDevanagari (nextChar : rs) -- Implicit 'a', process next normally
        [] -> consCtor : (A Hrasva Udatta False) : [] -- End of string, implicit 'a'
    Nothing -> parseDevanagari rest -- Skip unknown chars (spaces, etc.)
  where
    -- Lookup table returns: Left Varna (Vowel/Special) OR Right Consonant-Constructor
    lookupChar :: Char -> Maybe (Either Varna Varna)
    lookupChar 'अ' = Just $ Left (A Hrasva Udatta False)
    lookupChar 'आ' = Just $ Left (A Dirgha Udatta False)
    lookupChar 'इ' = Just $ Left (I Hrasva Udatta False)
    lookupChar 'ई' = Just $ Left (I Dirgha Udatta False)
    lookupChar 'उ' = Just $ Left (U Hrasva Udatta False)
    lookupChar 'ऊ' = Just $ Left (U Dirgha Udatta False)
    lookupChar 'ऋ' = Just $ Left (R Hrasva Udatta False)
    lookupChar 'ॠ' = Just $ Left (R Dirgha Udatta False)
    lookupChar 'ऌ' = Just $ Left (L Hrasva Udatta False)
    lookupChar 'ॡ' = Just $ Left (L Dirgha Udatta False)
    lookupChar 'ए' = Just $ Left E
    lookupChar 'ऐ' = Just $ Left Ai
    lookupChar 'ओ' = Just $ Left O
    lookupChar 'औ' = Just $ Left Au
    lookupChar 'ं' = Just $ Left Anusvara
    lookupChar 'ः' = Just $ Left Visarga
    lookupChar 'क' = Just $ Right Ka
    lookupChar 'ख' = Just $ Right Kha
    lookupChar 'ग' = Just $ Right Ga
    lookupChar 'घ' = Just $ Right Gha
    lookupChar 'ङ' = Just $ Right Nga
    lookupChar 'च' = Just $ Right Ca
    lookupChar 'छ' = Just $ Right Cha
    lookupChar 'ज' = Just $ Right Ja
    lookupChar 'झ' = Just $ Right Jha
    lookupChar 'ञ' = Just $ Right Nya
    lookupChar 'ट' = Just $ Right Tta
    lookupChar 'ठ' = Just $ Right Ttha
    lookupChar 'ड' = Just $ Right Dda
    lookupChar 'ढ' = Just $ Right Ddha
    lookupChar 'ण' = Just $ Right Nna
    lookupChar 'त' = Just $ Right Ta
    lookupChar 'थ' = Just $ Right Tha
    lookupChar 'द' = Just $ Right Da
    lookupChar 'ध' = Just $ Right Dha
    lookupChar 'न' = Just $ Right Na
    lookupChar 'प' = Just $ Right Pa
    lookupChar 'फ' = Just $ Right Pha
    lookupChar 'ब' = Just $ Right Ba
    lookupChar 'भ' = Just $ Right Bha
    lookupChar 'म' = Just $ Right Ma
    lookupChar 'य' = Just $ Right (Ya False)
    lookupChar 'र' = Just $ Right Ra
    lookupChar 'ल' = Just $ Right (La False)
    lookupChar 'व' = Just $ Right (Va False)
    lookupChar 'श' = Just $ Right Sha
    lookupChar 'ष' = Just $ Right Ssa
    lookupChar 'स' = Just $ Right Sa
    lookupChar 'ह' = Just $ Right Ha
    lookupChar _ = Nothing

    -- Matra lookup returns the Varna corresponding to the Matra
    lookupMatra :: Char -> Maybe Varna
    lookupMatra 'ा' = Just (A Dirgha Udatta False)
    lookupMatra 'ि' = Just (I Hrasva Udatta False)
    lookupMatra 'ी' = Just (I Dirgha Udatta False)
    lookupMatra 'ु' = Just (U Hrasva Udatta False)
    lookupMatra 'ू' = Just (U Dirgha Udatta False)
    lookupMatra 'ृ' = Just (R Hrasva Udatta False)
    lookupMatra 'ॄ' = Just (R Dirgha Udatta False)
    lookupMatra 'ॢ' = Just (L Hrasva Udatta False)
    lookupMatra 'ॣ' = Just (L Dirgha Udatta False)
    lookupMatra 'े' = Just E
    lookupMatra 'ै' = Just Ai
    lookupMatra 'ो' = Just O
    lookupMatra 'ौ' = Just Au
    lookupMatra _ = Nothing
