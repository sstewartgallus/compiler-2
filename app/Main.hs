{-# LANGUAGE GADTs #-}

module Main where

import qualified AsCallByName
import qualified AsCcc
import qualified Cbpv.AsOpt as Cbpv
import qualified Cbpv.Hom as Cbpv
import qualified Ccc.Optimize as Ccc
import qualified Ccc.Type
import Data.Text.Prettyprint.Doc
import qualified Interpreter
import Lam
import Lam.Type
import Pretty
import Prettyprinter.Render.Terminal
import Prelude hiding ((*), (+), (-), (<*>))

program :: Program U64
program = Program

data Program a where
  Program :: Program U64

instance Lam.Term Program where
  foldTerm Program =
    u64 3 `be` \z ->
      (z * z) + (z + z)

header :: AnsiStyle
header = underlined <> bold

toAnsi :: Style -> AnsiStyle
toAnsi s = case s of
  None -> mempty
  Keyword -> bold
  Variable -> italicized

main :: IO ()
main = do
  putDoc $
    annotate header (pretty "The Program:")
      <> hardline
      <> reAnnotate toAnsi (prettyLam program)
      <> hardline
      <> hardline

  let compiled = AsCcc.asCcc program

  putDoc $
    annotate header (pretty "Kappa/Zeta Decomposition:")
      <> hardline
      <> reAnnotate toAnsi (prettyCcc compiled)
      <> hardline
      <> hardline

  let optimized = Ccc.optimize compiled

  putDoc $
    annotate header (pretty "Optimized Kappa/Zeta Decomposition:")
      <> hardline
      <> reAnnotate toAnsi (prettyCcc optimized)
      <> hardline
      <> hardline

  let cbpv = AsCallByName.toCbpv optimized

  putDoc $
    annotate header (pretty "Call By Push Value:")
      <> hardline
      <> reAnnotate toAnsi (prettyCbpv cbpv)
      <> hardline
      <> hardline

  let optCbpv = Cbpv.opt cbpv

  putDoc $
    annotate header (pretty "Optimized Call By Push Value:")
      <> hardline
      <> reAnnotate toAnsi (prettyCbpv optCbpv)
      <> hardline
      <> hardline

  let result = case Interpreter.interpret optCbpv (Interpreter.Thunk (Interpreter.Unit Interpreter.:&)) of
        Interpreter.Thunk y -> case y (Interpreter.Effect 0) of
          Interpreter.U64 x Interpreter.:& _ -> x

  putDoc $
    annotate header (pretty "Result:")
      <> hardline
      <> pretty (show result)
      <> hardline
      <> hardline
