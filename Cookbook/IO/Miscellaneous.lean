import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Miscellaneous IO" =>

::: contributors
:::

# Get a Random Number

%%%
tag := "get-a-random-number"
number := false
%%%


{index}[Get a Random Number]

You can get a random number with lower `low` and upper `high` bounds using the {lean}`IO.rand` function.

```lean
def getRandomNumber (low high : Nat) : IO Unit := do
  let random ← IO.rand low high
  IO.println s!"Random number between 
    {low} and {high}: {random}"
```

# Putting a Process to Sleep

%%%
tag := "sleep-process"
number := false
%%%


{index}[Putting a Process to Sleep]

You can pause the current thread using {lean}`IO.sleep`. It takes the duration in *milliseconds*.

```lean
def delayedHello : IO Unit := do
  IO.println "Wait for it..."
  IO.sleep 2000 -- Wait for 2 seconds
  IO.println "Hello Lean!"
```

Note that {lean}`IO.sleep` is non-blocking for other Lean tasks; it only pauses the current execution flow.

