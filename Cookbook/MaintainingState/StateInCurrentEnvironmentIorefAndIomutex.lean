import VersoManual
import Cookbook.Lean

open Verso.Genre Manual
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command
open Cookbook

set_option pp.rawOnError true

#doc (Manual) "State using `IO.Ref`" =>

%%%
tag := "state-in-current-environment-ioref-and-iomutex"
number := false
%%%

{index}[State using `IO.Ref`]
