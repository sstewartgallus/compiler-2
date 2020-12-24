{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NoStarIsType #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE TypeOperators #-}

-- | Simplify various identities
module Ccc.AsSimplified (Expr, simplify) where

import Ccc
import Control.Category
import Ccc.HasExp
import Ccc.HasProduct
import Ccc.HasUnit
import Ccc.Type
import Prelude hiding ((.), id, curry, uncurry, Monad (..), Either (..))

simplify :: Expr f a b -> f a b
simplify x = out (simp x)

data Expr f a b where
  E :: f a b -> Expr f a b

  Id :: Category f => Expr f a a
  Compose ::  Category f => Expr f b c -> Expr f a b -> Expr f a c

  Unit :: HasUnit f => Expr f a Unit

  Kappa :: HasProduct f => ST a -> (Expr f Unit a -> Expr f b c) -> Expr f (a * b) c
  Lift :: HasProduct f => Expr f Unit a -> Expr f b (a * b)

  Zeta :: HasExp f => ST a -> (Expr f Unit a -> Expr f b c) -> Expr f b (a ~> c)
  Pass :: HasExp f => Expr f Unit a -> Expr f (a ~> b) b

simp :: Expr f a b -> Expr f a b
simp expr = case opt expr of
  Just x -> simp x
  Nothing -> recurse expr

opt :: Expr f a b -> Maybe (Expr f a b)
opt expr  = case expr of
  Compose Id f -> Just f
  Compose f Id -> Just f

  Compose Unit _ -> Just unit
  Compose (Kappa _ f) (Lift x) -> Just (f x)
  Compose (Pass x) (Zeta _ f) -> Just (f x)

  Compose (Compose f g) h  -> Just (f . (g . h))

  _ -> Nothing

recurse :: Expr f a b -> Expr f a b
recurse expr = case expr of
  E x -> E x
  Id -> id

  Compose f g -> simp f . simp g

  Unit -> unit

  Zeta t f -> zeta t (\x -> simp (f x))
  Pass x -> pass (simp x)

  Kappa t f -> kappa t (\x -> simp (f x))
  Lift x -> lift (simp x)

out :: Expr f a b -> f a b
out expr = case expr of
  E x -> x
  Id -> id
  Compose f g -> out f . out g

  Unit -> unit

  Zeta t f -> zeta t (\x -> out (f (E x)))
  Pass x -> pass (out x)

  Kappa t f -> kappa t (\x -> out (f (E x)))
  Lift x -> lift (out x)

instance Category f => Category (Expr f) where
  id = Id
  (.) = Compose

instance HasUnit f => HasUnit (Expr f) where
  unit = Unit

instance HasProduct f => HasProduct (Expr f) where
  lift = Lift
  kappa = Kappa

instance HasExp f => HasExp (Expr f) where
  zeta = Zeta
  pass = Pass

instance Ccc f => Ccc (Expr f) where
  u64 x = E (u64 x)
  constant t pkg name = E $ constant t pkg name
  cccIntrinsic x = E $ cccIntrinsic x