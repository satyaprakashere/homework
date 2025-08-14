module Main where

{-# LANGUAGE RankNTypes #-}

import Numeric.FFT (fft, ifft)
import Data.Complex (Complex(..), realPart)
import Numeric.LinearAlgebra (Vector, fromList, toList)
import Control.Applicative (liftA2)

-- Define a Natural Transformation between two functors
type Nat f g = forall a. f a -> g a

-- Functor-based FFT transformation
fftTransform :: (Functor f) => Nat f Vector
fftTransform = fromList . fft . fmap (:+ 0)

-- Functor-based IFFT transformation
ifftTransform :: (Functor f) => Nat Vector f
ifftTransform = fmap realPart . toList . ifft

-- Generalized convolution using natural transformations
convolveFFT :: (Functor f) => f Double -> f Double -> f Double
convolveFFT xs ys =
    ifftTransform $ liftA2 (*) (fftTransform xs) (fftTransform ys)

main :: IO ()
main = putStrLn "Hello World"
