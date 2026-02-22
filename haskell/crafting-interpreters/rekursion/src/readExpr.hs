module ReadExpr (readExpr, ThrowsError, trapError, extractValue) where

import Control.Monad.Except
import LispVal
import ParseExpr
import Text.ParserCombinators.Parsec hiding (spaces)

readExpr :: String -> ThrowsError LispVal
readExpr input = case parse parseExpr "lisp" input of
                   Left err -> throwError $ Parser err
                   Right val -> return val

type ThrowsError = Either LispError

trapError :: ThrowsError String -> ThrowsError String
trapError action = catchError action (return . show)

extractValue :: ThrowsError a -> a
extractValue (Right val) = val
