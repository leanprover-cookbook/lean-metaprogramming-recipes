import VersoManual
import Cookbook.Lean

open Verso.Genre Manual
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command
open Cookbook

set_option pp.rawOnError true

#doc (Manual) "Tactics giving new goals." =>

%%%
tag := "writing-tactics-giving-new-goals"
number := false
%%%

{index}[Tactics giving new goals.]
