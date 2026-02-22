module Ashtadhyayi.Phonology where

import Ashtadhyayi.Types

-- | The 14 Shiva Sutras
-- We represent them as lists of Varnas. The last element is the technical 'It' marker.
-- Note: We need a way to distinguish 'It' markers from actual Varnas in the structure if we want to be precise,
-- but for now we can just store the content and the marker separately or use a specialized type.
-- Here, we'll just list the content Varnas and the It marker as a pair.

shivaSutras :: [([Varna], Varna)]
shivaSutras =
  [ ([A Hrasva Udatta False, I Hrasva Udatta False, U Hrasva Udatta False], Nna) -- 1. a i uN
  , ([R Hrasva Udatta False, L Hrasva Udatta False], Ka)                         -- 2. r lK
  , ([E, O], Nga)                                                                -- 3. e oN
  , ([Ai, Au], Ca)                                                               -- 4. ai auC
  , ([Ha, Ya False, Va False, Ra], Tta)                                          -- 5. ha ya va raT
  , ([La False], Nna)                                                            -- 6. laN
  , ([Nya, Ma, Nga, Nna, Na], Ma)                                                -- 7. na ma nga na naM
  , ([Jha, Bha], Nya)                                                            -- 8. jha bhaNY
  , ([Gha, Ddha, Dha], Sha)                                                      -- 9. gha ddha dhaSH
  , ([Ja, Ba, Ga, Dda, Da], Sha)                                                 -- 10. ja ba ga dda daSH
  , ([Kha, Pha, Cha, Ttha, Tha, Ca, Tta, Ta], Va False)                          -- 11. kha pha cha ttha tha ca tta taV
  , ([Ka, Pa], Ya False)                                                         -- 12. ka paY
  , ([Sha, Ssa, Sa], Ra)                                                         -- 13. sha ssa saR
  , ([Ha], La False)                                                             -- 14. haL
  ]

-- | Helper to find a specific Varna in the global list of sutras (ignoring It markers except for stopping?)
-- Actually, Pratyahara formation logic:
-- "Adir antyena saheta" (1.1.71)
-- Take the initial Varna, and the final It marker. The set includes the initial, up to (but not including) the It marker.

-- Flattened list of (Varna, IsItMarker) to make scanning easier?
-- Or just search through the list of lists.

-- | Generate a Pratyahara from a starting Varna and an ending It marker.
formPratyahara start endIt = scan brokenSutras False
  where
    -- Flatten the Shiva Sutras into a single list of (Varna, IsItMarker)
    brokenSutras = concatMap (\(vs, it) -> map (\v -> (v, False)) vs ++ [(it, True)]) shivaSutras

    scan [] _ = []
    scan ((v, isIt):rest) active
      | active && isIt && v == endIt = [] -- Found the end marker while active: stop.
      | active && isIt = scan rest True   -- Skip generic It markers while active.
      | active = v : scan rest True       -- Collect valid Varnas.
      | not active && v == start && not isIt = v : scan rest True -- Found start non-marker: start collecting.
      | otherwise = scan rest False       -- Keep looking.
