import VersoManual
import Cookbook.Lean

open Verso.Genre Manual
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command
open Cookbook

set_option pp.rawOnError true

#doc (Manual) "Exact Pattern-Matching" =>

%%%
tag := "matching-expressions-exact-match"
number := false
%%%

{index}[Exact Pattern-Matching]
