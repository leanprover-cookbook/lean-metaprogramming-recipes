import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command Term

set_option pp.rawOnError true

#doc (Manual) "Checking Tactics" =>

%%%
tag := "checking-tactics"
number := false
htmlSplit := .never
%%%

::: contributors
:::


{index}[Checking Tactics]

# Checking Tactics

While writing tactics and for other forms of automation, it is often useful to check if a certain tactic can be applied to a target, and if so, how many goals remain after applying the tactic (in particular, if it closes the goal). It is important that the check does not modify the tactic state. We can achieve this by using the {lean}`@withoutModifyingState` function, which executes a given computation without modifying the tactic state. We run the tactic (more precisely the tactic sequence) using the {lean}`Elab.runTactic` function, which takes a goal and a tactic sequence, and returns the new list of goals and the new tactic state after executing the tactic sequence on the given goal. The following function checks if a tactic can be applied to a target, and if so, returns the number of goals that remain after applying the tactic.

```lean
def checkTactic (target: Expr)(tac: Syntax):
  TermElabM (Option Nat) :=
    withoutModifyingState do
    try
      let goal ← mkFreshExprMVar target
      let (goals, _) ←
        withoutErrToSorry do
        Elab.runTactic goal.mvarId! tac
          (← read) (← get)
      return some goals.length
    catch _ =>
      return none
```

To illustrate this function, we define a tactic that takes a tactic sequence as an argument, checks if it can be applied to the main target, and if so, logs the number of goals that remain after applying the tactic. If the tactic cannot be applied, it logs a warning.

```lean
elab "check_tactic" tac:tacticSeq : tactic =>
  withMainContext do
  let n? ← checkTactic (← getMainTarget) tac
  match n? with
  | some n =>
    logInfo m!"Tactic succeeded; {n} goals remain"
  | none =>
    logWarning m!"Tactic failed"

example : 1 ≤ 5 := by
  check_tactic rfl
  check_tactic decide
  decide
```
