module FRP.EmitUntil where

import Prelude

import Control.Monad.ST.Class (class MonadST, liftST)
import Control.Monad.ST.Internal as Ref
import Data.Compactable (compact)
import Data.Maybe (Maybe(..))
import Data.Tuple.Nested ((/\))
import FRP.Event (AnEvent, makeEvent, mapAccum, subscribe)

emitUntil
  :: forall s m a b
   . MonadST s m
  => (a -> Maybe b)
  -> AnEvent m a
  -> AnEvent m b
emitUntil aToB e = makeEvent \k -> do
  r <- liftST $ Ref.new true
  u <- liftST $ Ref.new (pure unit)
  usu <- subscribe e \n -> do
    l <- liftST $ Ref.read r
    when l $ do
      case aToB n of
        Just b -> k b
        Nothing -> do
          void $ liftST $ Ref.write false r
          join (liftST $ Ref.read u)
          void $ liftST $ Ref.write (pure unit) u
  void $ liftST $ Ref.write usu u
  pure do
    join (liftST $ Ref.read u)
