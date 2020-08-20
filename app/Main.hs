module Main where

import AsBound
import AsCbpv
import AsLabeless
import AsReified
import AsVarless
import AsView
import Cbpv (Cbpv)
import Data.Word
import Exp
import Hoas
import Lambda
import Product
import Type
import Prelude hiding ((<*>))

main :: IO ()
main = do
  putStrLn (view program)
  putStrLn (view compiled)
  putStrLn (show result)

program :: (Lambda k, Hoas k) => Value k U64
program = u64 42 `letBe` var inferT $ \x ->
  u64 3 `letBe` var inferT $ \y ->
    u64 3 `letBe` var inferT $ \z ->
      add <*> z <*> (add <*> x <*> y)

compiled :: Lambda k => Value k U64
compiled = (removeLabels . removeVariables . bindPoints) program

result :: Word64
result = reify compiled

cbpv :: Cbpv c d => Value c U64
cbpv = toCbpv compiled
