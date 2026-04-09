import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Tasks and Concurrency" =>

%%%
htmlSplit := .never
%%%

::: contributors
:::

# Tasks and Concurrency

%%%
tag := "tasks-and-concurrency"
number := false
%%%


{index}[Tasks and Concurrency]

Lean 4 supports lightweight concurrency through {lean}`Task`. You can spawn tasks to perform {lean}`IO` in the background and wait for their results later. Do check out information about the {lean}`Task` API can be found in the Lean 4 reference manual [Task and Threads](https://lean-lang.org/doc/reference/latest/IO/Tasks-and-Threads) section.

{lean}`Task` `α` is a primitive for asynchronous computation. It represents a computation that will resolve to a value of `type α`, possibly being computed on another thread.

## Spawning a Task

If you have a pure computation that is very heavy, you can use {lean}`Task.spawn` to run it in parallel without the {lean}`IO` monad.

```lean
def computeSomething : Nat :=
  let t := Task.spawn (fun _ => 2 + 2)
  t.get
```

## Spawning Background Tasks

Tasks which have side effects beyond computation, you should use {lean}`IO.asTask` to run an {lean}`IO` action in a background thread. It returns a {lean}`Task` that will eventually contain the result (wrapped in an {lean}`Except`).

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

## Task Status

You can check if a task is still running using {lean}`IO.TaskState`. This will tell you if it is still running, waiting to be run or has already completed. Note that {lean}`Task` is not a Process or Thread, so you cannot use {lean}`IO.TaskState` to check the status of a child process.

```lean
def monitorTask (task : Task α) : IO String := do
  let state ← IO.getTaskState task
  return match state with
    | .waiting  => "Task is still waiting."
    | .running  => "Task is currently running."
    | .finished => "Task has finished."

def checkTaskStatus : IO Unit := do
  -- Create a task that runs asynchronously
  let task ← IO.asTask (do
    IO.sleep 2000
    pure "Success"
  )
  
  let s1 ← monitorTask task
  IO.println s1 
  
  -- Wait for the task's internal timer to expire
  IO.sleep 2500
  
  -- Check again after completion
  let s2 ← monitorTask task
  IO.println s2

/-
Task is still waiting.
Task has finished.
-/
-- #eval checkTaskStatus
```

You can use {lean}`IO.getTID` to get the thread ID of the current thread, check out {ref "get-thread-ids"}[Get Thread IDs] for more information on how to get thread IDs of a process.

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
