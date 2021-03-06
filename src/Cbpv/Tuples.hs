{-# LANGUAGE GADTs #-}
{-# LANGUAGE NoStarIsType #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}

-- | Tuples
module Cbpv.Tuples (tuples) where

import Cbpv
import Cbpv.Hom
import Cbpv.Sort
import Data.Kind
import Prelude hiding ((.), id, fst, snd)

tuples :: Term stack code => code a b -> Closed a b
tuples x = Closed (out (foldCode x))

into :: Hom k a b -> Expr k a b
into x = Pure x

out :: Expr k a b -> Hom k a b
out x = case x of
  Pure x -> x
  Fst -> fst
  Snd -> snd
  Fanout x y -> out x &&& out y

data Expr (k :: Set -> Set -> Type) (a :: t) (b :: t) where
  Pure :: Hom k a b -> Expr k a b

  Fanout :: (KnownSet a, KnownSet b, KnownSet c) => Expr k c a -> Expr k c b -> Expr k c (a * b)
  Fst :: (KnownSet a, KnownSet b) => Expr k (a * b) a
  Snd :: (KnownSet a, KnownSet b) => Expr k (a * b) b

instance Stack (Expr f) where
  skip = into skip
  f <<< g = into (out f <<< out g)

instance Code (Expr g) where
  id = into id

  Fanout x y . f = (x . f) &&& (y . f)
  Fst . Fanout x _ = x
  Snd . Fanout _ x = x
  f . g = into (out f . out g)

  unit = into unit
  fst = Fst
  snd = Snd

  Fst &&& Snd = id
  x &&& y = Fanout x y

instance Cbpv (Expr f) (Expr f) where
  thunk f = into (thunk $ \x -> out (f (into x)))
  pop f = into (pop $ \x -> out (f (into x)))
  zeta f = into (zeta $ \x -> out (f (into x)))

  force x = into (force (out x))
  push x = into (push (out x))
  pass x = into (pass (out x))

  u64 n = into (u64 n)
  constant pkg name = into (constant pkg name)
  cccIntrinsic x = into (cccIntrinsic x)
  cbpvIntrinsic x = into (cbpvIntrinsic x)
