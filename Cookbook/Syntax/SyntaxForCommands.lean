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

Lean allows you to define custom syntax for a `command`. One convenient way to do this is to use `elab`, which lets you specify both the syntax and its elaboration in one place.

# "Hello World" command
{index}["Hello World" Command]

We start with a simple example of a command that prints "Hello World". The following `elab` declaration tells Lean to parse `#helloWorld` as a command and explains what that command should do.

```lean
elab "#helloWorld" : command => do
    logInfo "Hello World!"

#helloWorld
```
Here, `logInfo s` prints the string `s` in the InfoView.

# Command for checking whether a proposition is solved by grind
{index}[Command for checking whether a proposition is solved by grind]
We define a custom command that tests whether a proposition can be solved automatically by the {lean}`grind` tactic. The goal is to provide a small command-line-style tool that reports whether {lean}`grind` can close a goal.

Again, we can define the command directly with `elab`. In the declaration below, Lean parses inputs of the form `#grindable? <term>` as a command, and the elaborator says how that command should behave.

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

#grindable? ∀ n : Nat, n + 0 = n -- grindable
#grindable? ∃ x : Nat, x > 100 -- not grindable
```

Let's break down the specific metaprogramming functions used in the elaborator above:
- The call to {lean}`Command.liftTermElabM` is needed because command elaboration happens in the {lean}`CommandElabM` monad, while elaborating terms and running tactics here uses the term elaboration machinery in the {lean}`TermElabM` monad.
- Lean's elaborator turns elaboration errors into sorries by default. `withoutErrToSorry` prevents that from happening, so we can catch the exceptions thrown while elaborating.
- We write a `try … catch` block and place `withoutErrToSorry` inside the `try` block.
- `elabTerm t none` elaborates the user-provided proposition into an expression.
- Then `mkFreshExprMVar tExpr` creates a fresh metavariable goal whose type is that proposition.
- {lean}`Elab.runTactic` runs the tactic {lean}`grind` on that fresh goal and returns a tuple of type {lean}`List MVarId × Term.State`. In this example, the first component is exactly the list of goals left open after `grind`, while the second component is the updated state of the {lean}`TermElabM` monad, which we ignore with `_`.
- Finally, we inspect the remaining goals. If the list is empty, then `grind` managed to prove the proposition completely.

If you prefer to separate the syntax declaration from the elaboration logic, Lean also lets you define the syntax first with `syntax` and then add elaboration rules with `elab_rules`.

```lean
syntax "#grindable'?" term : command

elab_rules : command
|`(command| #grindable'? $t:term ) => do
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

The `elab_rules` command lets us define elaboration rules by pattern matching on the command syntax that was parsed. Both styles are useful, but the direct `elab` form is often a good starting point for a compact one-off command, while `syntax` plus `elab_rules` is helpful when you want to separate the parser and elaborator more explicitly.
