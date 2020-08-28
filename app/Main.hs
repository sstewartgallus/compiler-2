module Main where

import AsCallByName
import Cbpv (Cbpv)
import qualified Cbpv.AsEval as AsEval
import qualified Cbpv.AsView as AsViewCbpv
import qualified Cbpv.Sort
import Data.Word
import qualified Id
import Lambda
import Lambda.AsBound
import Lambda.AsPointFree
import Lambda.AsView
import Lambda.Exp
import Lambda.Hoas
import Lambda.Labels
import Lambda.Product
import Lambda.Type
import Lambda.Vars
import Prelude hiding ((<*>))

main :: IO ()
main = do
  Id.Stream _ (Id.Stream _ x y) (Id.Stream _ z (Id.Stream _ w u)) <- Id.stream

  putStrLn "The Program"
  putStrLn (view (bound x))

  putStrLn ""
  putStrLn "Point-Free Program"
  putStrLn (view (compiled y))

  putStrLn ""
  putStrLn "Cbpv Program"
  putStrLn (AsViewCbpv.view (cbpv w))

  putStrLn ""
  putStrLn "Result"
  putStrLn (show (result u))

program :: (Lambda k, Hoas k) => k Unit U64
program =
  u64 42 `letBe` \x ->
    u64 3 `letBe` \y ->
      u64 3 `letBe` \z ->
        add <*> z <*> (add <*> x <*> y)

bound :: (Labels k, Vars k, Lambda k) => Id.Stream -> k Unit U64
bound str = bindPoints str program

compiled :: Lambda k => Id.Stream -> k Unit U64
compiled str = pointFree (bound str)

cbpv :: Cbpv c d => Id.Stream -> d (Cbpv.Sort.U (Cbpv.Sort.F Cbpv.Sort.Unit)) (Cbpv.Sort.U (AsAlgebra U64))
cbpv str = toCbpv (compiled str)

result :: Id.Stream -> Word64
result str = AsEval.reify (cbpv str)
