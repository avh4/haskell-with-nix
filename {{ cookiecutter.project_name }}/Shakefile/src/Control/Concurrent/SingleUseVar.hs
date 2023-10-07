module Control.Concurrent.SingleUseVar (SingleUseVar, newSingleUseVar, setSingleUseVar, readSingleUseVar) where

import Data.IORef (IORef, atomicModifyIORef', newIORef, readIORef)

newtype SingleUseVar a = SingleUseVar (IORef (Maybe a))

newSingleUseVar :: IO (SingleUseVar a)
newSingleUseVar =
  SingleUseVar <$> newIORef Nothing

-- | NOTE: If you want to block for a value to be set, you should use `Control.Concurrent.MVar` instead,
-- | since you know that there will be exactly one writer.
readSingleUseVar :: SingleUseVar a -> IO (Maybe a)
readSingleUseVar (SingleUseVar ref) =
  readIORef ref

-- | Immediately throws the given error message if the ref is already set.
setSingleUseVar :: String -> SingleUseVar a -> a -> IO ()
setSingleUseVar errorMessage (SingleUseVar ref) c =
  atomicModifyIORef' ref set
    >>= either (const $ error errorMessage) return
  where
    set = \case
      Just prev -> (Just prev, Left ())
      Nothing -> (Just c, Right ())
