module ReadExprSpec (spec) where

import Test.Hspec
import ReadExpr
import LispVal

spec :: Spec
spec = do
  describe "readExpr" $ do
    it "parses atoms" $ do
      readExpr "atom" `shouldBe` Right (Atom "atom")
      readExpr "#t" `shouldBe` Right (Bool True)
      readExpr "#f" `shouldBe` Right (Bool False)

    it "parses numbers" $ do
      readExpr "123" `shouldBe` Right (Number 123)
      readExpr "-123" `shouldBe` Right (Number (-123))

    it "parses strings" $ do
      readExpr "\"string\"" `shouldBe` Right (String "string")
      readExpr "\"string with spaces\"" `shouldBe` Right (String "string with spaces")

    it "parses lists" $ do
      readExpr "(a b c)" `shouldBe` Right (List [Atom "a", Atom "b", Atom "c"])
      readExpr "(1 2 3)" `shouldBe` Right (List [Number 1, Number 2, Number 3])
    
    it "parses dotted lists" $ do
      readExpr "(a . b)" `shouldBe` Right (DottedList [Atom "a"] (Atom "b"))
      readExpr "(a b . c)" `shouldBe` Right (DottedList [Atom "a", Atom "b"] (Atom "c"))

    it "parses nested lists" $ do
      readExpr "(a (b c) d)" `shouldBe` Right (List [Atom "a", List [Atom "b", Atom "c"], Atom "d"])

    it "handles whitespace" $ do
      readExpr "   atom   " `shouldBe` Right (Atom "atom")
      readExpr " (  a  b  ) " `shouldBe` Right (List [Atom "a", Atom "b"])
