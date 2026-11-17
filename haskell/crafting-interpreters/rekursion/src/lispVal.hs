module LispVal (LispVal(..), LispError(..)) where

import Text.ParserCombinators.Parsec (ParseError)

-- import Text.ParserCombinators.Parsec hiding (spaces)

data LispVal = Atom String
              | List [LispVal]
              | DottedList [LispVal] LispVal
              | Number Integer
              | String String
              | Bool Bool
              deriving (Show, Eq)

data LispError = NumArgs Integer [LispVal]
               | TypeMismatch String LispVal
               | Parser ParseError
               | BadSpecialForm String LispVal
               | NotFunction String String
               | UnboundVar String String
               | Default String

-- For testing purposes, we need Eq instances. 
-- Since ParseError doesn't have an Eq instance, we can't derive it automatically for LispError.
-- We will implement a custom Eq instance that compares the string representation for Parser errors.
instance Eq LispError where
  (NumArgs i1 v1) == (NumArgs i2 v2) = i1 == i2 && v1 == v2
  (TypeMismatch s1 v1) == (TypeMismatch s2 v2) = s1 == s2 && v1 == v2
  (Parser p1) == (Parser p2) = show p1 == show p2 -- Compare via string representation
  (BadSpecialForm s1 v1) == (BadSpecialForm s2 v2) = s1 == s2 && v1 == v2
  (NotFunction s1 s2) == (NotFunction s3 s4) = s1 == s3 && s2 == s4
  (UnboundVar s1 s2) == (UnboundVar s3 s4) = s1 == s3 && s2 == s4
  (Default s1) == (Default s2) = s1 == s2
  _ == _ = False

instance Show LispError where show = showError

showError :: LispError -> String
showError (UnboundVar message varname)  = message ++ ": " ++ varname
showError (BadSpecialForm message form) = message ++ ": " ++ show form
showError (NotFunction message func)    = message ++ ": " ++ show func
showError (NumArgs expected found)      = "Expected " ++ show expected 
                                       ++ " args; found values " ++ unwordsList found
showError (TypeMismatch expected found) = "Invalid type: expected " ++ expected
                                       ++ ", found " ++ show found
showError (Parser parseErr)             = "Parse error at " ++ show parseErr

unwordsList :: [LispVal] -> String
unwordsList = unwords . map show
