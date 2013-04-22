{-# LANGUAGE ScopedTypeVariables, DeriveDataTypeable,
             ExistentialQuantification #-}
module Test.Tasty.Options
  ( OptionSet
  , IsOption(..)
  , setOption
  , changeOption
  , lookupOption
  , safeRead
  ) where

import Data.Typeable
import qualified Data.Map as Map
import Data.Map (Map)
import Data.Monoid
import Data.Proxy

class Typeable v => IsOption v where
  defaultValue :: v
  parseValue :: String -> Maybe v
  optionName :: Proxy v -> String

data OptionValue = forall v . IsOption v => OptionValue v

newtype OptionSet = OptionSet (Map TypeRep OptionValue)

setOption :: IsOption v => v -> OptionSet -> OptionSet
setOption v (OptionSet s) =
  OptionSet $ Map.insert (typeOf v) (OptionValue v) s

lookupOption :: forall v . IsOption v => OptionSet -> v
lookupOption (OptionSet s) =
  case Map.lookup (typeOf (undefined :: v)) s of
    Just (OptionValue x) | Just v <- cast x -> v
    Just {} -> error "OptionSet: broken invariant (shouldn't happen)"
    Nothing -> defaultValue

changeOption :: forall v . IsOption v => (v -> v) -> OptionSet -> OptionSet
changeOption f s = setOption (f $ lookupOption s) s

-- | Safe read function. Defined here for convenience to use for
-- 'parseValue'.
safeRead :: Read a => String -> Maybe a
safeRead s
  | [(x, "")] <- read s = Just x
  | otherwise = Nothing
