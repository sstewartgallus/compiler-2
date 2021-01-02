{-# LANGUAGE DataKinds #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE NoStarIsType #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE MultiParamTypeClasses #-}

-- | Intrinsify intrinsics
module Cbpv.AsIntrinsified (intrinsify) where

import Cbpv
import qualified Cbpv.Hom as Hom
import Cbpv.Sort
import Data.Kind
import Prelude hiding ((.), id, fst, snd)
import qualified Ccc.Type as Ccc
import qualified Ccc as Ccc

intrinsify :: Hom.Closed @SetTag a b -> Hom.Closed a b
intrinsify x = Hom.Closed (outC (Hom.fold x))

newtype Stk f (g :: Set -> Set -> Type) (a :: Algebra) (b :: Algebra) = K (f a b)
newtype Cde (f :: Algebra -> Algebra -> Type) g (a :: Set) (b :: Set) = C { outC :: g a b }

instance (Category f, Category g) => Category (Stk f g) where
  id = K id
  K f . K g = K (f . g)

instance (Category f, Category g) => Category (Cde f g) where
  id = C id
  C f . C g = C (f . g)

instance Cbpv f g => Code (Cde f g) where
  unit = C unit
  lift (C f) (C x) = C (lift f x)
  kappa f = C $ kappa $ \x -> case f (C x) of
    C y -> y

instance Cbpv f g => Stack (Stk f g) where

instance Cbpv f g => Cbpv (Stk f g) (Cde f g) where
  thunk f = C $ thunk $ \x -> case f (C x) of
    K y -> y
  force (C x) = K (force x)

  pass (K f) (C x) = K (pass f x)
  push (K f) (C x) = K (push f x)

  zeta f = K $ zeta $ \x -> case f (C x) of
    K y -> y
  pop f = K $ pop $ \x -> case f (C x) of
    K y -> y

  u64 x = C (u64 x)

  constant pkg name = K (constant pkg name)

  cccIntrinsic x = K $ case x of
    Ccc.AddIntrinsic -> addIntrinsic
    _ -> cccIntrinsic x
  cbpvIntrinsic x = C (cbpvIntrinsic x)

-- | fixme.. cleanup this mess
addIntrinsic :: Cbpv stack code => stack (AsAlgebra (Ccc.U64 Ccc.* Ccc.U64)) (AsAlgebra Ccc.U64)
addIntrinsic = doAdd

doAdd :: Cbpv stack code => stack (F (U (F U64) * U (F U64))) (F U64)
doAdd =
  pop $ \tuple -> (
  (pop $ \x -> (
  (pop $ \y ->
  push id (lift addi x . y)) .
  force (snd . tuple))) .
  force (fst . tuple))

addi :: Cbpv stack code => code (U64 * U64) U64
addi = cbpvIntrinsic AddIntrinsic
