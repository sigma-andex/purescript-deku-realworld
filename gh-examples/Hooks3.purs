module Hooks3 where

import Prelude

import Control.Alt ((<|>))
import Data.Foldable (oneOf)
import Data.Int (floor)
import Data.Profunctor (lcmap)
import Data.Tuple (curry)
import Data.Tuple.Nested ((/\))
import Deku.Attribute ((:=))
import Deku.Control (dyn_, text_)
import Deku.Core (Nut, bus, insert_, remove)
import Deku.DOM as D
import Deku.Do (useMailboxed, useMemoized)
import Deku.Do as Deku
import Deku.Listeners (click, numeric)
import Deku.Toplevel (runInBody)
import Effect (Effect)
import FRP.Event (fold, keepLatest)

app :: Nut
app = Deku.do
  setMakeBold /\ makeBold <- useMailboxed
  setMakeNormal /\ makeNormal <- useMailboxed
  setCounter /\ counter <- useMemoized
    ( \i -> fold (const (add 1)) i 0
        <|> pure 0
    )
  let asMailboxed = lcmap (floor >>> { address: _, payload: unit })
  D.div_
    [ D.div_
        [ D.label_ [ text_ "Make bold" ]
        , D.input (numeric $ pure (asMailboxed setMakeBold)) []
        , D.label_ [ text_ "Remove bold" ]
        , D.input (numeric $ pure (asMailboxed setMakeNormal)) []
        ]
    , D.div_ [ D.button (click (pure $ setCounter unit)) [ text_ "Add row" ] ]
    , dyn_
        D.div
        ( counter <#> \i -> keepLatest Deku.do
            setRemoveMe /\ removeMe <- bus <<< curry
            pure
              ( insert_
                  ( D.div_
                      [ D.button
                          ( oneOf
                              [ click $ pure $ setRemoveMe unit
                              , oneOf
                                  [ makeBold i $> true
                                  , makeNormal i $> false
                                  ] <#> \tf -> D.Style := if tf then "font-weight:900;" else ""
                              ]
                          )
                          [ text_ "Remove" ]
                      , D.span_ [ text_ (show i) ]
                      ]
                  )
              ) <|> (removeMe $> remove)
        )
    ]

main :: Effect Unit
main = runInBody app