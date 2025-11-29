module ReadExpr where

import Text.ParserCombinators.Parsec hiding (spaces)

readExpr :: String -> ThrowsError LispVal
readExpr input = case parse parseExpr "lisp" input of
                   Left err -> throwError $ Parser err
                   Right val -> return val
