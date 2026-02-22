{-# LANGUAGE OverloadedStrings #-}

module Main where

import Ashtadhyayi.Parser
import Ashtadhyayi.Phonology
import Ashtadhyayi.Sandhi
import Ashtadhyayi.Types
import qualified Data.Text as T
import qualified Data.Text.IO as TIO

main :: IO ()
main = do
  putStrLn "--- Ashtadhyayi Phonology Model ---"

  putStrLn "\n1. Pratyahara Generation 'ik' (i, u, r, l):"
  let startI = I Hrasva Udatta False
  let endK = Ka
  let ik = formPratyahara startI endK
  print ik -- Uses new Show instance
  putStrLn "\n2. Pratyahara Generation 'ac' (vowels):"
  let startA = A Hrasva Udatta False
  let endC = Ca
  let ac = formPratyahara startA endC
  -- print ac

  putStrLn "\n3. Sandhi Example: Eco yanaci (6.1.77)"
  putStrLn "Input: sudhi + upasya"

  -- Using Parser for input!
  let word1 = parseDevanagari "सुधि"
  let word2 = parseDevanagari "उपास्य"
  putStrLn $ "Word 1: " ++ show (Pratyahara word1)
  putStrLn $ "Word 2: " ++ show (Pratyahara word2)

  -- Note: "उपास्य" in parser might need to handle 'उ' as vowel initial.
  -- "सुधि" -> s u dh i.

  let input = word1 ++ word2
  putStrLn $ "Input Varnas: " ++ show (Pratyahara input)

  let output = ecoYanaci input
  putStrLn $ "Output Varnas: " ++ show (Pratyahara output)

  putStrLn ""
