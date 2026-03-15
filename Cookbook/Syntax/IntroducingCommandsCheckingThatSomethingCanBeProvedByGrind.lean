import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Adding command syntax" =>

%%%
tag := "introducing-commands-checking-that-something-can-be-proved-by-grind"
number := false
%%%

::: contributors
:::


{index}[Introducing commands]
