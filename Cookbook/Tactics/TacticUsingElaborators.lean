import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Tactics using elaborators" =>

%%%
tag := "tactic-using-elaborators"
number := false
htmlSplit := .never
%%%

::: contributors
:::


{index}[Tactics using elaborators]

Let's start by writing a basic elaborator that retrieves and displays the expression representing the type of the main goal.

```lean
elab "goalExpr" : tactic => do
  let goalExpr ← getMainTarget
  logInfo m!"Main Target Expression: {goalExpr}"

example: 2 + 3 = 5 := by
  goalExpr
  simp
```

If you formalize mathematics in Lean, you are likely familiar with the `sorry` tactic. We use it frequently as a placeholder for proofs yet to be written. The `sorry` tactic artificially closes the current main goal but leaves a warning in the Infoview.

```lean
example : 847 + 153 = 1000 := by sorry
```
Under the hood, the sorry tactic works by creating a term of the main goal's type using the sorryAx axiom. You can inspect these internal components directly:

```lean
#check sorryAx
-- sorryAx.{u} (α : Sort u) (synthetic :  Bool) : α
```
Now, let's write a custom tactic called `toDo` using `elab` and `sorryAx`. The `toDo` tactic will close the main goal just like `sorry`, but it will also accept a string argument to log a custom reminder to the Infoview.

```lean
elab "toDo" s: str : tactic => do
  withMainContext do
  logInfo m!"Message:{s}"
  let targetExpr ← getMainTarget
  let sorryExpr ←
      mkAppM ``sorryAx #[targetExpr, mkConst ``false]
  closeMainGoal `todo sorryExpr

example : 34 ≤ 47 := by
  toDo "This should be easy to do"
```
Let's break down the specific metaprogramming functions used to make this work:
- `getMainTarget` retrieves the expression for the type of the current main goal.
- `mkAppM` is a highly useful function that constructs a function application expression. It takes the `Name` of the function, in this case `sorryAx`, and an array of expressions representing the arguments you want to pass to it.
