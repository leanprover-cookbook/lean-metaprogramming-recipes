import VersoManual
import Cookbook.Lean
import Std

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Miscellaneous IO" =>

::: contributors
:::

These are some Miscellaneous IO functions that you might find useful in your Lean code.

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
def sleepProcessHello : IO Unit := do
  IO.println "Wait for it..."
  IO.sleep 2000 -- Wait for 2 seconds
  IO.println "Hello Lean!"
```

Note that {lean}`IO.sleep` is non-blocking for other Lean tasks; it only pauses the current execution flow.

# Async Sleep

%%%
tag := "async-sleep"
number := false
%%%

{index}[Async Sleep]

Async Sleep (Asynchronous Sleep) refers to a sleep operation that yields the current execution fiber for a specific time without blocking the entire OS thread or the runtime's scheduler. This allows other concurrent tasks to continue running while the current task waits. 

While {lean}`IO.sleep` is the standard way to pause in a task, Lean's internal library provides a more specialized event-driven asynchronous I/O framework in {lean}`Std.Internal.IO.Async`. Within this framework, {lean}`Std.Internal.IO.Async.sleep` is used to pause execution without blocking the task manager's thread pool.

```lean
open Std.Internal.IO.Async
open Std.Time

def asyncSleepExample : IO Unit := do
  IO.println "Starting async sleep..."
  
  -- Create an Async computation that sleeps for 2 seconds
  -- Std.Internal.IO.Async.sleep takes a Millisecond.Offset
  let duration := Millisecond.Offset.ofInt 2000
  let computation : Async Unit := Std.Internal.IO.Async.sleep duration
  
  -- Use Async.block to execute the computation in the IO monad
  computation.block
  
  IO.println "Woke up from async sleep!"
```

The {lean}`Async` framework is designed for high-performance, event-driven I/O and provides better primitives for composing many concurrent operations than raw tasks alone.

# Deadlocking the Task System

%%%
tag := "deadlocking-the-task-system"
number := false
%%%


{index}[Deadlock]
{index}[Task]

Lean 4's task system uses a fixed-size thread pool (typically equal to the number of CPU cores). A common pitfall is to call a blocking operation like {lean}`IO.wait` or {lean}`Task.get` from within another task. 

Because the thread pool is finite, if you have more tasks waiting on other tasks than there are available threads, the system will **deadlock**. The blocked tasks continue to occupy their threads while waiting for work that can never be scheduled because all threads are already full.

### Example of a Deadlock Scenario

If you try to run more tasks than you have CPU cores, and each task waits for another task to finish, you might run into this issue:

```lean
-- Potentially deadlocks if the thread pool is exhausted
def potentialDeadlock : IO Unit := do
  let tasks ← (List.range 100).mapM fun i => IO.asTask do
    let subTask ← IO.asTask do
      IO.sleep 100
      return i
    -- Blocking wait inside a task!
    let res ← IO.wait subTask
    return res
  
  let _ ← tasks.mapM IO.wait
```

### Avoiding Deadlocks

To avoid deadlocks, prefer asynchronous composition using {lean}`IO.bindTask`. This allows you to chain tasks together without holding a thread idle while waiting for the result.

```lean
def safeComposition (t : Task α) (f : α → IO (Task β)) : IO (Task β) := do
  IO.bindTask t f
```

By using {lean}`IO.bindTask`, the scheduler only runs the next part of the computation once the first task is complete, freeing up the thread in the meantime.

