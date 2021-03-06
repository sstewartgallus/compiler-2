{-# LANGUAGE TypeOperators #-}

module Lam (Lam (..), Term (..)) where

import Data.Word (Word64)
import Lam.Type
import Prelude hiding (id, (.), (<*>))

-- | A simple high level intermediate language based off the simply
-- typed lambda calculus. Evaluation is lazy.
class Lam t where
  lam :: (KnownT a, KnownT b) => (t a -> t b) -> t (a ~> b)
  (<*>) :: (KnownT a, KnownT b) => t (a ~> b) -> t a -> t b

  be :: (KnownT a, KnownT b) => t a -> (t a -> t b) -> t b

  u64 :: Word64 -> t U64
  constant :: KnownT a => String -> String -> t a

  (+) :: t U64 -> t U64 -> t U64
  x + y = constant "core" "add" <*> x <*> y
  (-) :: t U64 -> t U64 -> t U64
  x - y = constant "core" "subtract" <*> x <*> y
  (*) :: t U64 -> t U64 -> t U64
  x * y = constant "core" "multiply" <*> x <*> y

class Term t where
  foldTerm :: Lam v => t a -> v a
