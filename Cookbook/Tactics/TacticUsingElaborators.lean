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

In the previous {ref "tactic-using-macro"}[recipe], we saw how to use macros to build a tactic by expanding one piece of syntax into another. In this recipe, we will write tactics using elaborators, which let us construct expressions and also give us access to a lot of information, including the goal state.

# Tactic to print the main goal

%%%
tag := "tactic-to-print-the-main-goal"
number := false
htmlSplit := .never
%%%
{index}[Tactic to print the main goal]

Let's start by writing a basic elaborator that retrieves and displays the expression representing the type of the main goal.

```lean
elab "goalExpr" : tactic => do
  let goalExpr ← getMainTarget
  logInfo m!"Main Target Expression: {goalExpr}"

example: 2 + 3 = 5 := by
  goalExpr
  simp
```
Check out {ref "displaying-in-the-infoview"}[Displaying in the Infoview] on how to use string formatting in the InfoView.

# Tactic to log and close the main goal

%%%
tag := "tactic-to-log-and-close-the-main-goal"
number := false
htmlSplit := .never
%%%
{index}[Tactic to log and close the main goal]

Now, let's write a custom tactic called `toDo` using `elab` and `sorryAx`. If you formalize mathematics in Lean, you are likely familiar with the `sorry` tactic. We use it frequently as a placeholder for proofs yet to be written. The `sorry` tactic artificially closes the current main goal but leaves a warning in the Infoview.

```lean
example : 847 + 153 = 1000 := by sorry
```

Under the hood, the `sorry` tactic works by creating a term of the main goal's type using the [`sorryAx`](https://lean-lang.org/doc/reference/latest/Axioms/?terms=sorryAx#standard-axioms) axiom. We can inspect this internal component directly:

```lean
#check sorryAx
-- sorryAx.{u} (α : Sort u) (synthetic :  Bool) : α
```

The `toDo` tactic will close the main goal just like `sorry`, but it will also accept a string argument to log a custom reminder to the Infoview.

```lean
elab "toDo" s: str : tactic => do
  withMainContext do
    logInfo m!"Message:{s}"
    let targetExpr ← getMainTarget
    let sorryExpr ←
      mkAppM ``sorryAx #[targetExpr, mkConst ``false]
    closeMainGoal `toDo sorryExpr

example : 34 ≤ 47 := by
  toDo "This should be easy to do"
```

Let's break down the specific metaprogramming functions used to make this work:

- `getMainTarget` retrieves the expression for the type of the current main goal.
- `mkAppM` is a highly useful function that constructs a function application expression. It takes the `Name` of the function, in this case `sorryAx`, and an array of expressions representing the arguments we want to pass to it.
- `closeMainGoal` closes the current main goal with the expression we constructed.

This example shows the basic pattern for elaborator-based tactics: inspect the current goal, build an expression of the right type, and use it to update the proof state.
