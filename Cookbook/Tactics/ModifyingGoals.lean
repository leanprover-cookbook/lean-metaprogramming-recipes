import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Modifying Goals" =>

%%%
tag := "modifying-goals"
number := false
htmlSplit := .never
%%%

::: contributors
:::


{index}[Modifying Goals]

Tactics can work with goals in various ways. They can inspect the goals, modify them, or even close them. In this section, we will explore how to write tactics that modify goals using elaborators.

# Modifying Goals

The goals in a tactic state, in particular the main goal, are represented by meta-variables. The type of the main goal is called the main target. These are obtained using the {lean}`getMainGoal` and {lean}`getMainTarget` functions, respectively.

A tactic typcially assigns to the main goal an expression that is a proof of the goal, i.e., has type the main target. However, the expression assigned to the main goal may also involve new meta-variables, which in turn become new goals to be solved. In this way, a tactic can modify the goal state without fully closing the main goal.

Note that if the main goal is assigned, we must change the list of goals. The most convenient way to do this is to use the {lean}`replaceMainGoal` function, which replaces the main goal with a new list of goals. The new list of goals typically includes the new meta-variables that were introduced in the expression assigned to the main goal.

We illustrate this with a tactic that reduces the main target.

```lean
elab "reduce" : tactic => do
  let target ← getMainTarget
  let reducedTarget ← reduce (skipTypes := false) target
  let mvar ←  mkFreshExprMVar reducedTarget
  let goal ← getMainGoal
  goal.assign mvar
  replaceMainGoal [mvar.mvarId!]

example : 1 + 1 = 2 := by -- goal `1 + 1 = 2`
  reduce -- goal `2 = 2`
  rfl
```

We emphasize that it is the responsibility of the tactic author to ensure that if a metavariable, such as a goal, is assigned an expression, then the expression has the same type as the goal up to definitional equality. One also has to correctly modify the list of goals to reflect any new meta-variables that were introduced and remove those that were assigned. Otherwise we get a low-level error on using the tactic.
