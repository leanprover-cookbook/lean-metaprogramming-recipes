import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean


set_option pp.rawOnError true

#doc (Manual) "Hello World Tactic" =>

%%%
tag := "hello-world-tactics"
number := false
htmlSplit := .never
%%%

::: contributors
:::


{index}[Hello World Tactic]

# A Basic Tactic

This is a very basic tactic that does nothing. This is just to show how to define a tactic in Lean.


```lean
open Lean Elab Tactic

elab "hello_tactic" : tactic => do
  return

example : 1 = 1 := by
  hello_tactic
  rfl
```
