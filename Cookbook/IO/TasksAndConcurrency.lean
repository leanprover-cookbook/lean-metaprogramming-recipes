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

If you have a pure computation that is very heavy, you can use {lean}`Task.spawn` to run it in parallel without the {lean}`IO` monad. As mentioned before, when a {lean}`Task` `α` is spawned, it will give you output of type `α`. 

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
      for _ in [1:100000] do
        -- Simulate heavy computation
        continue
    IO.println "Background task finished!"
    return "Result Data"
  
  IO.println "Doing other things in the main thread..."

  -- Wait for the task to complete and get the result
  match (← IO.wait task) with
  | .ok val => IO.println s!"Task returned: {val}"
  | .error e => IO.eprintln s!"Task failed with error: {e}"

/-
Working... 1
Working... 2
Working... 3
Working... 4
Background task finished!
Doing other things in the main thread...
Task returned: Result Data
-/
-- #eval backgroundWork
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

# Running Tasks in Parallel

%%%
tag := "running-tasks-in-parallel"
number := false
%%%

{index}[Running Tasks in Parallel]

One of the most powerful uses of tasks is running multiple {lean}`IO` operations at the same time. Since {lean}`Task` `α` is a primitive for asynchronous computation, you can spawn multiple tasks to perform {lean}`IO` in the background and wait for their results later. This allows you to interleave the outputs of different tasks, demonstrating concurrency.

```lean
def heavyWork (name : String) (iters : Nat) : IO Unit := do
  for i in [0:iters] do
    -- We use a small loop to simulate work
    let mut _x := 0
    for _ in [0:1000] do
      _x := _x + 1
    
    -- Printing acts as a synchronization/yield point
    IO.println s!"{name}: step {i}"

def runParallel : IO Unit := do
  let stdout ← IO.getStdout
  IO.println "Starting heavy work..."
  stdout.flush

  -- Spawn Task A
  let taskA ← IO.asTask (heavyWork "Task A" 5)
  -- Spawn Task B
  let taskB ← IO.asTask (heavyWork "Task B" 2)

  -- Wait for both to finish
  let _ ← IO.wait taskA
  let _ ← IO.wait taskB
  IO.println "Both tasks finished!"

/-
Task A: step 0
Task B: step 0
Task A: step 1
Task B: step 1
Task A: step 2
Task A: step 3
Task A: step 4
Starting heavy work...
Both tasks finished!
-/
-- #eval runParallel
```

In this example, the outputs of A and B are interleaved, demonstrating that they are running concurrently. However in many cases due to spawning too many threads, you might create a deadlock. Check out the {ref "deadlocking-the-task-system"}[Deadlocking the Task System] section for more information on how to avoid deadlocks when spawning too many threads.
