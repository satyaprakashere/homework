import Control.Concurrent
import Control.Monad (forM, forM_)
import qualified Data.ByteString.Char8 as BS

main :: IO ()
main = do
  putStrLn "Starting threads with join..."

  mvars <- forM [1..10000] $ \i -> do
    mvar <- newEmptyMVar
    forkIO $ worker i mvar
    return mvar

  -- Wait for all threads to signal completion
  forM_ mvars takeMVar

  putStrLn "All threads finished."

worker :: Int -> MVar () -> IO ()
worker i doneSignal = do
  let fastString = BS.pack "This is a fast string print example."
  BS.putStrLn fastString
--putStrLn $ "Thread " ++ show i ++ " started."
--threadDelay 1000000
--putStrLn $ "Thread " ++ show i ++ " finished."
  putMVar doneSignal ()
  
