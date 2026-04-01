import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Checking validity of Tactics" =>

%%%
tag := "checking-if-a-tactic-is-valid"
number := false
htmlSplit := .never
%%%

::: contributors
:::


{index}[Checking validity of Tactics]
