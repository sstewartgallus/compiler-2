{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE NoStarIsType #-}

module Cbpv (Term (..), Stack (..), Code (..), Cbpv (..), Intrinsic (..)) where

import Cbpv.Sort
import qualified Ccc as Ccc
import qualified Ccc.Type as Ccc
import Data.Kind
import Data.Word (Word64)
import qualified Lam.Type as Lam
import Prelude hiding (id, (.))

-- |
-- As opposed to the usual monadic interface call by push value is based
-- around adjoint functors on two different categories.
--
-- There is a different formulation using oblique morphisms and an
-- indexed category instead of using the asymmetric tensor but was
-- difficult to work with.
--
-- Paul Blain Levy. "Call-by-Push-Value: A Subsuming Paradigm".
class Stack (hom :: Algebra -> Algebra -> Type) where
  skip :: KnownAlgebra a => hom a a
  (<<<) :: (KnownAlgebra a, KnownAlgebra b, KnownAlgebra c) => hom b c -> hom a b -> hom a c

class Code code where
  id :: KnownSet a => code a a
  (.) :: (KnownSet a, KnownSet b, KnownSet c) => code b c -> code a b -> code a c

  unit :: KnownSet a => code a Unit

  (&&&) :: (KnownSet a, KnownSet b, KnownSet c) => code c a -> code c b -> code c (a * b)
  fst :: (KnownSet a, KnownSet b) => code (a * b) a
  snd :: (KnownSet a, KnownSet b) => code (a * b) b

class (Stack stack, Code code) => Cbpv stack code | stack -> code, code -> stack where
  thunk :: (KnownSet a, KnownAlgebra b, KnownAlgebra c) => (code Unit a -> stack b c) -> code a (b ~. c)
  force :: (KnownAlgebra a, KnownAlgebra b) => code Unit (b ~. a) -> stack b a

  pop :: (KnownSet a, KnownAlgebra b, KnownAlgebra c) => (code Unit a -> stack b c) -> stack (a & b) c
  push :: (KnownSet a, KnownAlgebra b) => code Unit a -> stack b (a & b)

  zeta :: (KnownSet a, KnownAlgebra b, KnownAlgebra c) => (code Unit a -> stack b c) -> stack b (a ~> c)
  pass :: (KnownSet a, KnownAlgebra b) => code Unit a -> stack (a ~> b) b

  u64 :: Word64 -> code Unit U64

  constant :: Lam.KnownT a => String -> String -> code Unit (U (AsAlgebra (Ccc.AsObject a)))
  cccIntrinsic :: (Ccc.KnownT a, Ccc.KnownT b) => Ccc.Intrinsic a b -> stack (AsAlgebra a) (AsAlgebra b)
  cbpvIntrinsic :: (KnownSet a, KnownSet b) => Intrinsic a b -> code a b

  add :: code (U64 * U64) U64
  add = cbpvIntrinsic AddIntrinsic

class Term stackTerm codeTerm | stackTerm -> codeTerm, codeTerm -> stackTerm where
  foldCode :: Cbpv stack code => codeTerm a b -> code a b
  foldStack :: Cbpv stack code => stackTerm a b -> stack a b

data Intrinsic a b where
  AddIntrinsic :: Intrinsic (U64 * U64) U64
  MulIntrinsic :: Intrinsic (U64 * U64) U64

instance Show (Intrinsic a b) where
  show x = case x of
    AddIntrinsic -> "$add"
    MulIntrinsic -> "$mul"
