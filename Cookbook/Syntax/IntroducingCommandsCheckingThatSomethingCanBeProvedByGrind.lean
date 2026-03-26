import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command Term

set_option pp.rawOnError true

#doc (Manual) "Adding syntax for commands" =>

%%%
tag := "introducing-commands-checking-that-something-can-be-proved-by-grind"
number := false
%%%

::: contributors
:::


{index}[Adding syntax for commands]

In this recipe, we define a custom command that tests whether a proposition can be solved automatically by the {lean}`grind` tactic. The goal is to provide a small command-line style tool that reports whether {lean}`grind` can close a goal.

We start by introducing a new piece of syntax in the `command` category:

```lean
syntax "#grindable?" term : command
```

This tells Lean to parse inputs of the form `#grindable? <term>` as a command. Since the new syntax lives in the `command` category, we need a command elaborator to explain what the command should do after parsing.

One convenient way to do this is with `elab_rules`:

```lean
elab_rules : command
|`(command| #grindable? $t:term ) => do
    Command.liftTermElabM do
      try
        withoutErrToSorry do
          let tExpr ← elabTerm t none
          let goal ← mkFreshExprMVar tExpr
          Term.synthesizeSyntheticMVarsNoPostponing
          let (goals,_) ← Elab.runTactic goal.mvarId!
                                (← `(tactic|grind))
          if goals.isEmpty then
            logInfo m!"{t} is grindable"
          else
            logInfo m!"grind failed with goals: {goals}"
      catch _ =>
        logInfo m!"{t} is not grindable"

#grindable? ∀ n : Nat, n + 0 = n -- grindable
#grindable? ∃ x : Nat, x > 100 -- not grindable
```

Let's break down the specific metaprogramming functions used in the elaborator above:
- The call to {lean}`Command.liftTermElabM` is needed because command elaboration happens in the {lean}`CommandElabM` monad, while elaborating terms and running tactics here uses the term elaboration machinery in the {lean}`TermElabM` monad.
- Lean's elaborator turns elaboration errors into sorries by default. `withoutErrToSorry` prevents that from happening, so we can catch the exceptions thrown while elaborating.
- We write a `try … catch` block and place `withoutErrToSorry` inside the `try` block.
- `elabTerm t none` elaborates the user-provided proposition into an expression.
- Then `mkFreshExprMVar tExpr` creates a fresh metavariable goal whose type is that proposition.
- {lean}`Elab.runTactic` runs the tactic {lean}`grind` on that fresh goal and returns a tuple of type {lean}`List MVarId × Term.State`.
- Finally, we inspect the remaining goals. If the list is empty, then `grind` managed to prove the proposition completely.

If you prefer, the same command can also be introduced using a single `elab` declaration rather than `syntax` plus `elab_rules`:

```lean
elab "#grindable?" t:term : command => do
  Command.liftTermElabM do
      try
        withoutErrToSorry do
          let tExpr ← elabTerm t none
          let goal ← mkFreshExprMVar tExpr
          Term.synthesizeSyntheticMVarsNoPostponing
          let (goals,_) ← Elab.runTactic goal.mvarId!
                                (← `(tactic|grind))
          if goals.isEmpty then
            logInfo m!"{t} is grindable"
          else
            logInfo m!"grind failed with goals: {goals}"
      catch _ =>
        logInfo m!"{t} is not grindable"
```

This second version is equivalent in spirit, but the first style is often easier to extend when you want to add several elaboration rules for the same command syntax. Use the direct `elab` form when you want a compact one-off command, and use `syntax` plus `elab_rules` when you want to separate the parser and elaborator more explicitly.
