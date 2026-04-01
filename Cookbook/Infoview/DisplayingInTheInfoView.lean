import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Displaying in the Infoview" =>

%%%
tag := "displaying-in-the-infoview"
number := false
htmlSplit := .never
%%%

::: contributors
:::

{index}[Displaying in the Infoview]

This recipe demonstrates how to display messages in the Lean Infoview, an essential technique for debugging and providing user feedback during metaprogramming.

The functions described here rely on {name}`MessageData`, which allows you to log rich text and expressions. To easily construct a {name}`MessageData` object, Lean provides the `m!` interpolated string macro, which seamlessly combines plain text and Lean terms into a format the Infoview can render.

The logging functions do not accept just any term directly. To print something in the Infoview, Lean must know how to turn it into {name}`MessageData`, usually via an instance of {name}`ToMessageData`. In many cases, these instances come for free. For example, a {name}`ToFormat` instance gives rise to a {name}`ToMessageData` instance, and a {name}`ToString` instance can in turn be used to build a {name}`ToFormat` instance.

Built-in types like {name}`Nat` already have a {name}`ToMessageData` instance, so `m!"The number is {42}"` works out of the box. For a custom type, you need to tell Lean how it should appear in the Infoview:

```lean
structure Point where
  x : Nat
  y : Nat

instance : ToMessageData Point where
  toMessageData p :=
    m!"Point({p.x}, {p.y})"

def showPoint : MetaM Unit := do
  let p : Point := { x := 3, y := 5 }
  logInfo m!"Current point: {p}"
```

Here, the interpolation `{p}` works because the {lean}`ToMessageData Point` instance tells Lean how to convert a `Point` into something printable.

# `logInfo`, `logWarning`, and `logError`

The three primary logging functions are monadic and are most commonly used in the {name}`CoreM`, {name}`MetaM`, {name}`TermElabM`, and {name}`TacticM` monads.

Unlike {name}`Lean.throwError`, none of these logging functions interrupt or abort execution. They simply post a message to the Infoview and allow the program to continue.

## {name}`Lean.logInfo`

{index}[`logInfo`]
{name}`logInfo` displays standard informational messages in the Infoview. Because it is monadic, it can be used in tactics, commands, and other elaboration contexts.

```lean
def message (msg: String) : MetaM Unit :=
  logInfo m!"Here is the message: {msg}"

#eval message "logInfo worked"
```
Below is an example of a tactic called `readGoal` that fetches the expected type of the current goal using {name}`getMainTarget`. It then uses `logInfo` together with the `m!` macro to pretty-print that goal directly in the Infoview.

```lean
elab "readGoal" : tactic => do
  let goal ← getMainTarget
  logInfo m!"Current goal: {goal}"

example : 2 + 3 = 5 := by
  readGoal
  rfl
```
Notice how the `m!` macro handles the interpolation expression: `m!"Current goal: {goal}"` expands into a `MessageData` object containing both a text part (`"Current goal: "`) and an expression part (the pretty-printed `goal`). `logInfo` accepts this object and pushes it to the Infoview.

## {name}`Lean.logWarning`
{index}[`logWarning`]
`logWarning` displays warning messages in yellow in the Infoview. It is ideal for flagging noncritical issues or edge cases.

```lean
def warningMessage (msg : String) : CoreM Unit := do
  Lean.logWarning m!"Warning: {msg}"

#eval warningMessage "something might be wrong"
```

In this tactic example, we use `logWarning` to alert the user if a tactic splits the state into multiple goals:

```lean
elab "warnIfMultipleGoals" : tactic => do
  let goals ← getUnsolvedGoals
  if goals.length > 1 then
    logWarning m!"More than one goal left!"

example : ∀ x : Nat, (x = x ↔ x - x = 0) := by
  intro x
  apply Iff.intro
  warnIfMultipleGoals
  · simp
  · simp
```


## {name}`Lean.logError`
{index}[`logError`]

`Lean.logError` displays error messages in red in the Infoview. While it marks the associated code with a red squiggly line indicating an error, it does not interrupt execution.

```lean+error
def errorMessage (msg : String) : CoreM Unit := do
  Lean.logError m!"Error: {msg}"
#eval errorMessage "something went wrong"
```

This is particularly useful when you want to report an error but continue processing the rest of the file or command. For example, `#requireProp` is a command that checks whether a given term has type `Prop`. If it does not, it logs an error but still continues execution and logs the term's expression:

```lean+error
elab "#requireProp" t:term : command => do
  Command.liftTermElabM do
    let tExpr ← Term.elabTerm t none
    unless ← isProp tExpr do
      logError m!"Goal must be a proposition: {tExpr}"
    logInfo m!"The expression of the term: {tExpr} "

#requireProp Nat
#requireProp (Nat → Nat)
#requireProp 2 = 0
```

Notice the difference if we replace `logError` with `throwError`. Because `throwError` immediately halts execution, the subsequent `logInfo` is never run when the term fails to be a proposition:

```lean+error
elab "#requireProp" t:term : command => do
  Command.liftTermElabM do
    let tExpr ← Term.elabTerm t none
    unless ← isProp tExpr do
      throwError m!"Goal must be a proposition: {tExpr}"
    logInfo m!"The expression of the term: {tExpr} "

#requireProp Nat
#requireProp (Nat → Nat)
#requireProp 2 = 0
```
