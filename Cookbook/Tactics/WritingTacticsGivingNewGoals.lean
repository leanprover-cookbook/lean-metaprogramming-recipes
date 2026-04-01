import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Tactics giving new goals." =>

%%%
tag := "writing-tactics-giving-new-goals"
number := false
htmlSplit := .never
%%%

::: contributors
:::


{index}[Tactics giving new goals.]
