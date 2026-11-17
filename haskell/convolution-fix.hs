module Main where

import Numeric.FFT (fft, ifft)
import Data.Complex (Complex(..), realPart)
import qualified Data.Vector.Unboxed as V

-- FFT transformation converting list to unboxed vector, then running FFT in IO
fftTransform :: [Double] -> IO (V.Vector (Complex Double))
fftTransform xs = fft (V.fromList (map (:+ 0) xs))

-- IFFT transformation running in IO, then converting the resulting vector back to a list
ifftTransform :: V.Vector (Complex Double) -> IO [Double]
ifftTransform xs = do
    res <- ifft xs
    return (V.toList (V.map realPart res))

-- Generalized convolution wrapped in IO using unboxed vectors
convolveFFT :: [Double] -> [Double] -> IO [Double]
convolveFFT xs ys = do
    fx <- fftTransform xs
    fy <- fftTransform ys
    -- Element-wise vector multiplication
    let multiplied = V.zipWith (*) fx fy
    ifftTransform multiplied

-- Main function running the test case
main :: IO ()
main = do
    putStrLn "Running FFT Convolution Test..."

    let signal1 = [1.0, 2.0, 1.0, 0.0]
        signal2 = [0.5, 1.0, 0.5, 0.0]

    convolved <- convolveFFT signal1 signal2

    putStrLn $ "Input Signal 1: " ++ show signal1
    putStrLn $ "Input Signal 2: " ++ show signal2
    putStrLn $ "Convolved Result: " ++ show convolved