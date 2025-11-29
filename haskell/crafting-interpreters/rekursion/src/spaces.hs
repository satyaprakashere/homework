module Spaces where

import Text.ParserCombinators.Parsec hiding (spaces)

spaces :: Parser ()
spaces = skipMany1 space
