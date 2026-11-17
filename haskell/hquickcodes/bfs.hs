module Main where

import qualified Data.Map as Map
import qualified Data.Sequence as Seq
import Data.Sequence (Seq((:<|)), (|>), (><))
import Data.Foldable (toList)

type Node = Int
type Graph = Map.Map Node [Node]

concatq = (><)
--SCons = (:<|)
			
bfs graph start = go (Seq.singleton start) where
	go Seq.Empty = []
	go (node :<| queue) = node : go newQueue where
		neighbors = Map.findWithDefault [] node graph
		newQueue = concatq queue (Seq.fromList neighbors)
	
exampleGraph :: Graph
exampleGraph = Map.fromList
	[ (1, [2, 3])
	, (2, [4])
	, (3, [5])
	, (4, [6])
	, (5, [])
	, (6, [])
	]

main :: IO ()
main = print $ bfs exampleGraph 1
-- Output: [1,2,3,4,5,6]
