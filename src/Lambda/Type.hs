{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeFamilyDependencies #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE NoStarIsType #-}

module Lambda.Type (ST (..), T, Void, Unit, type (~>), type (*), type (+), type U64, AsObject, asObject) where
import qualified Hoas.Type as Type

type Void = 'Void

type Unit = 'Unit

type (~>) = 'Exp

type (*) = 'Product

type (+) = 'Sum

type U64 = 'U64

infixr 9 ~>

infixl 0 *

infixl 0 +

data T = U64 | Void | Unit | Sum T T | Product T T | Exp T T

data ST a where
  SU64 :: ST U64
  SVoid :: ST Void
  SUnit :: ST Unit
  (:+:) :: ST a -> ST b -> ST (a + b)
  (:*:) :: ST a -> ST b -> ST (a * b)
  (:->) :: ST a -> ST b -> ST (a ~> b)


type family AsObject a = r | r -> a where
  AsObject (a Type.~> b) = AsObject a ~> AsObject b
  AsObject Type.U64 = U64
  AsObject Type.Unit = Unit

asObject :: Type.ST a -> ST (AsObject a)
asObject t = case t of
  Type.SU64 -> SU64
  Type.SUnit -> SUnit
  a Type.:-> b -> asObject a :-> asObject b
