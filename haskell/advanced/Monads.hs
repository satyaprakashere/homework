module Advanced.Monads where

-- Maybe Monad for safe division
safeDiv :: Double -> Double -> Maybe Double
safeDiv _ 0 = Nothing
safeDiv x y = Just (x / y)

runDemo :: IO ()
runDemo = do
    putStrLn "\n--- 1. Monads Demo ---"
    let result = do
            x <- safeDiv 10 2
            y <- safeDiv x 2
            return y
    print result

    let failure = do
            x <- safeDiv 10 0
            y <- safeDiv x 2
            return y
    print failure
