{-# LANGUAGE OverloadedStrings #-}

module Main where

import Data.Map (Map)
import Data.Text (Text)

import qualified Data.Map as Map

main :: IO ()
main = putStrLn "Hello World"


type Identifier = Text

data Expression = Boolean Bool
	| String Text
	| Number Double
	| Record (Map Identifier Expression)
	| FieldAccess Expression Identifier
	| Let [(Identifier, Expression)] Expression
	| Variable Identifier
	
data Type
	= BooleanType
	| StringType
	| NumberType
	| RecordType (Map Identifier Type)
	
infer
	:: [(Identifier, Type)]
	-- ^ context, a.k.a. "Γ"
	-> Expression
	-- ^ input expression
	-> Either Text Type
	-- ^ output inferred type
infer context (Boolean _) = do
	return BooleanType
	
infer context (String _) = do
	return StringType
	
infer context (Number _) = do
	return NumberType
	
infer context (Record fields) = do
	fieldTypes <- traverse (infer context) fields
	
	return (RecordType fieldTypes)
	
infer context (FieldAccess expression field) = do
	expressionType <- infer context expression
	
	case expressionType of
		RecordType fieldTypes ->
			case Map.lookup field fieldTypes of
				Just fieldType ->
					return fieldType
				Nothing ->
					Left "missing field"
		_ ->
			Left "not a record"
			
infer context (Let [] expression) = do
	infer context expression
	
infer context (Let ((x, assignment) : assignments) expression) = do
	assignmentType <- infer context assignment
	
	infer ((x, assignmentType) : context) (Let assignments expression)
	
infer context (Variable identifier) = do
	case lookup identifier context of
		Just assignmentType ->
			return assignmentType
		Nothing ->
			Left "unbound variable"