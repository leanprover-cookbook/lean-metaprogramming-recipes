import VersoManual
import Cookbook.Lean
import Cookbook.Tactics.CheckingTactics

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Replacing with What Works" =>

%%%
tag := "replacing-with-what-works"
number := false
htmlSplit := .never
%%%

::: contributors
:::


{index}[Replacing with What Works]

It is a common pattern that tactics involve a search but, if a search is succesful, we want to narrow down the search to a specific tactic that we know works. For example, we may want to check if a tactic sequence can be applied to the main target, and if so, apply a specific tactic that we know works. We can achieve this by using the {lean}`TryThis.addSuggestion` function, which adds a suggestion to try a specific tactic at a given syntax node.

Here we use the function defined in the recipe {ref "checking-tactics"}[Checking Tactics] and build a tactic that checks if a given tactic sequence can be applied to the main target, and if so, runs the tactic and adds a suggestion to try the first successful tactic in the sequence.

```lean
syntax (name:= check_tactic) "check_tactic?"
  "[" tacticSeq,* "]" : tactic

@[tactic check_tactic] def checkTacticImpl : Tactic :=
  fun stx => withMainContext do
  match stx with
  | `(tactic| check_tactic? [$tacs,*]) =>
    for tac in tacs.getElems do
      let n? ← checkTactic (← getMainTarget) tac
      match n? with
      | some n =>
        if n = 0 then
          TryThis.addSuggestion stx tac
          evalTactic tac
          return
      | none =>
        logWarning m!"Tactic failed"
  | _ => throwUnsupportedSyntax

example : 2 ≤ 20 := by
  check_tactic? [rfl, decide, grind]
```
