{-# LANGUAGE TemplateHaskell #-}
module Main where
import Language.Haskell.TH

main :: IO ()
main = do
    print (listToTuple 3 [1,2,3])


listToTuple :: Int -> [a] -> Q Exp
listToTuple n xs = [| $(tupE $ map varE vars) |]
	where vars = [ mkName $ "x" ++ show i | i <- [0..n-1] ]
	
	
compos h gs = undefined