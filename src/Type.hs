{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE NoStarIsType #-}

module Type (KnownT, inferT, eqT, ST (..), T, Void, Unit, type (~>), type (*), type (+), type U64, Value, Continuation, End) where

import Data.Kind (Type)
import Data.Typeable ((:~:) (..))
import qualified Sort
import Sort (KnownAlgebra (..), SAlgebra, eqAlgebra)

type Value (hom :: T -> T -> Type) a = forall x. hom x a

type Continuation (hom :: T -> T -> Type) a = forall x. hom a x

type End (hom :: T -> T -> Type) = forall x. hom x x

type T = Sort.Algebra

type Void = Sort.Void

type Unit = Sort.Initial

type (~>) a = (Sort.~>) (Sort.U a)

type a * b = Sort.F (Sort.U a Sort.* Sort.U b)

type a + b = Sort.F (Sort.U a Sort.+ Sort.U b)

type U64 = Sort.F Sort.U64

infixr 9 ~>

infixl 0 *

infixl 0 +

data ST a where
  SU64 :: ST U64
  SVoid :: ST Void
  SUnit :: ST Unit
  (:*:) :: ST a -> ST b -> ST (a * b)
  (:+:) :: ST a -> ST b -> ST (a + b)
  (:->) :: ST a -> ST b -> ST (a ~> b)

type KnownT = KnownAlgebra

inferT :: KnownT t => ST t
inferT = algebraToT inferAlgebra

eqT :: ST a -> ST b -> Maybe (a :~: b)
eqT x y = case (x, y) of
  (SVoid, SVoid) -> Just Refl
  (SUnit, SUnit) -> Just Refl
  (SU64, SU64) -> Just Refl
  (x :*: y, x' :*: y') -> do
    Refl <- eqT x x'
    Refl <- eqT y y'
    return Refl
  (x :+: y, x' :+: y') -> do
    Refl <- eqT x x'
    Refl <- eqT y y'
    return Refl
  (x :-> y, x' :-> y') -> do
    Refl <- eqT x x'
    Refl <- eqT y y'
    return Refl
  _ -> Nothing

algebraToT :: SAlgebra a -> ST a
algebraToT t = case t of
  Sort.SVoid -> SVoid
  Sort.SU a Sort.:-> b -> algebraToT a :-> algebraToT b
  Sort.SInitial -> SUnit
  x Sort.:& Sort.SInitial -> case x of
    Sort.SU64 -> SU64
    Sort.SU a Sort.:+: Sort.SU b -> algebraToT a :+: algebraToT b
    Sort.SU a Sort.:*: Sort.SU b -> algebraToT a :*: algebraToT b

instance Show (ST a) where
  show expr = case expr of
    SU64 -> "U64"
    SVoid -> "Void"
    SUnit -> "Unit"
    x :*: y -> "(" ++ show x ++ " * " ++ show y ++ ")"
    x :-> y -> "(" ++ show x ++ " ~> " ++ show y ++ ")"
    x :+: y -> "(" ++ show x ++ " + " ++ show y ++ ")"
