import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Running Tasks in Parallel" =>

%%%
htmlSplit := .never
%%%

::: contributors
:::

To know what {lean}`Task`s are and how to spawn and handle them, check out {ref "spawning-tasks-and-worker-threads"}[Spawning Tasks and Worker Threads] recipe before.

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
  IO.println "Starting heavy work..."

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

In this example, the outputs of A and B are interleaved, demonstrating that they are running concurrently. Notice that even when flushed, the "Starting heavy work..." is coming later. When printing the output do to the terminal, but to a buffer and so does other worker thread's output too, and hence based on more interrupts and thread behaviour, the order may differ among main thread and worker threads {margin}[If you have a better explanation, Please share].

However in many cases due to spawning too many threads, you might create a deadlock. Check out the {ref "deadlocking-the-task-system"}[Deadlocking the Task System] section for more information on how to avoid deadlocks when spawning too many threads.
