module Main where

import Control.Monad.Loops(iterateM_)
import Data.Set as Set
import System.Random (randomRIO)
--import Diagram

randomList :: Int -> IO [(Int, Int)]
randomList n | n < 1 = return []
randomList n         = do
    r  <- randomRIO (1,100)
    s  <- randomRIO (1,100)
    rs <- randomList (n-1)
    return ((r,s):rs)

--iterateM f mx n = sequence . Prelude.take n . iterate (>>= f) $ mx

main :: IO ()
main = do
    state <- randomList 700
    iterateM_ runWithTestData (fromList state)

runWithTestData :: Grid -> IO Grid
runWithTestData state = do
    print result
    getLine
    return result where result = nextGen state

type Point = (Int, Int)
type Grid  = Set Point

-- Checks whether a point is alive in the given grid
isAlive :: Grid -> Point -> Bool
isAlive g p = member p g

-- Returns a point's 8 neighbouring points
neighbours :: Point -> Set Point
neighbours p = Set.fromList [
        offset p (dx, dy)
        | dx <- [-1..1], dy <- [-1..1],
        not (dx == 0 && dy == 0)
    ]

-- Offsets a coordinate by given delta
offset :: Point -> (Int, Int) -> Point
offset p d = (fst p + fst d, snd p + snd d)

-- Returns a set of points which includes the living points in the grid and
-- all of thier neighbours
extendGrid :: Grid -> Grid
extendGrid g = union g $ unions [neighbours p | p <- toList g]

-- Returns a set of living neighbours to the given point
livingNeighbours :: Grid -> Point -> Grid
livingNeighbours g p = Set.filter (isAlive g) (neighbours p)

-- Returns the number of living neighbours of the given point
livingNeighbourCount :: Grid -> Point -> Int
livingNeighbourCount g p = Set.size $ livingNeighbours g p

-- Checks whether the given point will be alive in the next generation
lives :: Grid -> Point -> Bool
lives g p
    | isAlive g p = livingNeighbourCount g p `elem` [0,1]
    | otherwise   = livingNeighbourCount g p `elem` [4]
    
-- Gives the next generation of the grid
nextGen :: Grid -> Grid
nextGen g = Set.filter (lives g) (extendGrid g)