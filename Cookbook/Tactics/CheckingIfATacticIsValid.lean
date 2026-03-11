import VersoManual
import Cookbook.Lean

open Verso.Genre Manual
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command
open Cookbook

set_option pp.rawOnError true

#doc (Manual) "Checking validity of Tactics" =>

%%%
tag := "checking-if-a-tactic-is-valid"
number := false
%%%

{index}[Checking validity of Tactics]
