module ParseExpr (parseExpr) where

import LispVal
import Text.ParserCombinators.Parsec hiding (spaces)
import Spaces (spaces)
import Symbol (symbol)

parseExpr :: Parser LispVal
parseExpr = parseAtom
          <|> parseString
          <|> parseNumber
          <|> parseQuoted
          <|> do char '('
                 x <- try parseList <|> parseDottedList
                 char ')'
                 return x

parseAtom :: Parser LispVal
parseAtom = do
              first <- letter <|> symbol
              rest <- many (letter <|> digit <|> symbol)
              let atom = first:rest
              return $ case atom of
                         "#t" -> Bool True
                         "#f" -> Bool False
                         _    -> Atom atom

parseString :: Parser LispVal
parseString = do
                _ <- char '"'
                x <- many (noneOf "\"")
                _ <- char '"'
                return $ String x

parseNumber :: Parser LispVal
parseNumber = do
                val <- many1 digit
                return $ Number (read val)

parseQuoted :: Parser LispVal
parseQuoted = do
                _ <- char '\''
                x <- parseExpr
                return $ List [Atom "quote", x]

parseList :: Parser LispVal
parseList = do
              x <- sepBy parseExpr spaces
              return $ List x

parseDottedList :: Parser LispVal
parseDottedList = do
    head' <- endBy parseExpr spaces
    tail' <- char '.' >> spaces >> parseExpr
    return $ DottedList head' tail'
