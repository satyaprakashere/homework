module LispVal where

import Text.ParserCombinators.Parsec hiding (spaces)

data LispVal = Atom String
              | List [LispVal]
              | DottedList [LispVal] LispVal
              | Number Integer
              | String String
              | Bool Bool
