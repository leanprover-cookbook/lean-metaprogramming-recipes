import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Tasks and Concurrency" =>

::: contributors
:::

# Tasks and Concurrency

%%%
tag := "tasks-and-concurrency"
number := false
%%%


{index}[Tasks and Concurrency]

Lean 4 supports lightweight concurrency through {lean}`Task`. You can spawn tasks to perform {lean}`IO` in the background and wait for their results later.

## Spawning Background Tasks

You can use {lean}`IO.asTask` to run an {lean}`IO` action in a background thread. It returns a {lean}`Task` that will eventually contain the result (wrapped in an {lean}`Except`).

```lean
def backgroundWork : IO Unit := do
  let task ← IO.asTask do
    for i in [1:5] do
      IO.println s!"Working... {i}"
      IO.sleep 500
    IO.println "Background task finished!"
    return "Result Data"
  
  IO.println "Doing other things in the main thread..."
  IO.sleep 500
  
  -- Wait for the task to complete and get the result
  match (← IO.wait task) with
  | .ok val => IO.println s!"Task returned: {val}"
  | .error e => IO.eprintln s!"Task failed with error: {e}"
```

## Spawning Tasks without `IO`

If you have a pure computation that is very heavy, you can use {lean}`Task.spawn` to run it in parallel without the {lean}`IO` monad.

```lean
def computeSomething : Nat :=
  let t := Task.spawn (fun _ => 2 + 2)
  t.get
```

# Parallel IO

%%%
tag := "parallel-io"
number := false
%%%


{index}[Parallel IO]

One of the most powerful uses of tasks is running multiple {lean}`IO` operations at the same time.

```lean
def runParallel : IO Unit := do
  let t1 ← IO.asTask do
    IO.sleep 1000
    return "A"
  let t2 ← IO.asTask do
    IO.sleep 1000
    return "B"
  
  IO.println "Waiting for both tasks..."
  let r1 ← IO.wait t1
  let r2 ← IO.wait t2
  
  IO.println s!"Results: T₁ = {r1.toOption.getD ""}, 
    T₂ = {r2.toOption.getD ""}"
```

In this example, the total wait time is approximately 1 second, even though we performed two 1-second sleeps, because they ran in parallel.
