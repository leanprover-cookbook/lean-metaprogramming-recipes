import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Viewing and Closing Goals" =>

%%%
tag := "viewing-closing-goals"
number := false
htmlSplit := .never
%%%

::: contributors
:::


{index}[Viewing and Closing Goals]

Tactics can work with goals in various ways. They can inspect the goals, modify them, or even close them. In this section, we will explore how to write tactics that view and close goals using elaborators.

# Viewing Goals

Let's start by writing a basic elaborator that retrieves and displays the expression representing the type of the main goal. The type of the main goal is given by the `getMainTarget` function.

```lean
elab "goalExpr" : tactic => do
  let goalExpr ← getMainTarget
  logInfo m!"Main Target Expression: {goalExpr}"

example: 2 + 3 = 5 := by
  goalExpr
  simp
```
Check out {ref "displaying-in-the-infoview"}[Displaying in the Infoview] on how to use string formatting in the InfoView.

# Closing Goals: Custom `sorry` Tactic

We next illustrate how to close goals using an elaborator. We will make a customized version of the `sorry` tactic that not only closes the goal but also logs a custom message to the Infoview.

If you formalize mathematics in Lean, you are likely familiar with the `sorry` tactic. We use it frequently as a placeholder for proofs yet to be written. The `sorry` tactic closes the current main goal but leaves a warning in the Infoview.

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

# Modifying Goals

Often tactics cannot fully close goals but instead modify them. We illustrate this with a dummy tactic that creates a new goal meta-variable and replaces the current goal with it. This does not have any real effect as the new meta-variable has the same type as the original goal, but it serves to demonstrate how to manipulate goals.
