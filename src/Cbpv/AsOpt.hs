{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}

module Cbpv.AsOpt (opt) where

import Cbpv
import Cbpv.Hom
import Cbpv.Intrinsify
import Cbpv.MoveCode
import Cbpv.Tuples
import Cbpv.ZetaToPop
import Cbpv.Inline
import Cbpv.AsLeft
import Cbpv.AsRight
import Cbpv.RemoveDead
import Cbpv.ElimThunkForce
import Control.Category
import Cbpv.Sort
import Prelude hiding ((.), id, round)

opt :: Closed @SetTag a b -> Closed @SetTag a b
opt = intrinsify >>>
      (\x -> iterate round x !! 100)

round :: Closed @SetTag a b -> Closed @SetTag a b
round =
  asLeft >>>
  dopass >>>

  asRight >>>
  dopass

dopass :: Closed @SetTag a b -> Closed @SetTag a b
dopass =
  tuples >>>
  moveCode >>>
  zetaToPop >>>
  elimThunkForce >>>
  inline >>>
  removeDead
