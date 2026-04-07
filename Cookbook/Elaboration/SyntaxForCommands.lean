import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command Term Parser
open Category hiding grind


set_option pp.rawOnError true

#doc (Manual) "Adding syntax for commands" =>

%%%
tag := "adding-syntax-for-command"
number := false
htmlSplit := .never
%%%

::: contributors
:::


{index}[Adding syntax for commands]

Lean allows you to define custom syntax for a {name}`command`. One convenient way to do this is to use `elab`, which lets you specify both the syntax and its elaboration in one place.

# "Hello World" command

%%%
tag := "hello-world-command"
number := false
%%%


{index}["Hello World" Command]

We start with a simple example of a command that prints "Hello World". The following `elab` declaration tells Lean to parse `#helloWorld` as a command and explains what that command should do.

```lean
elab "#helloWorld" : command => do
    logInfo "Hello World!"

#helloWorld
```
Here, `logInfo s` prints the string `s` in the InfoView.

# Command for checking whether a proposition is solved by grind

%%%
tag := "command-for-checking-whether-a-proposition-is-solved-by-grind"
number := false
%%%

{index}[Command for checking whether a proposition is solved by grind]
We define a custom command that tests whether a proposition can be solved automatically by the {name}`grind` tactic. The goal is to provide a small command-line-style tool that reports whether {name}`grind` can close a goal.

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
- The call to {name}`Command.liftTermElabM` is needed because command elaboration happens in the {name}`CommandElabM` monad, while elaborating terms and running tactics uses the term elaboration machinery in the {name}`TermElabM` monad.
- Lean's elaborator sometimes turns elaboration errors into sorries. {name}`withoutErrToSorry` prevents that from happening, so we can catch the exceptions thrown while elaborating.
- We write a `try … catch` block and place {name}`withoutErrToSorry` inside the `try` block.
- {name}`Lean.Elab.Term.elabTerm` elaborates the user-provided proposition (i.e., `t`) into an expression.
- Then {name}`mkFreshExprMVar` creates a fresh metavariable goal whose type is given as an expression (i.e., `tExpr`).
- {name}`Elab.runTactic` runs the tactic {lean}`grind` on that fresh goal and returns a tuple of type {lean}`List MVarId × Term.State`. In this example, the first component is exactly the list of goals left open after {name}`grind`, while the second component is the updated state of the {name}`TermElabM` monad, which we ignore with `_`.
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
