import VersoManual
import Cookbook.Lean
import Std

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command Std.Internal.IO.Async Std.Time

set_option pp.rawOnError true

#doc (Manual) "Putting a Process to Sleep" =>

%%%
htmlSplit := .never
%%%

::: contributors
:::

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

Asynchronous sleep operates on the principle of Yielding. Instead of telling the OS "Stop this thread," the program tells the Lean Runtime "I have nothing to do for the next N milliseconds. Take my current execution state, save it, and give this CPU time to another task." The underlying OS thread remains Active and Running. It immediately looks at the queue of other pending Lean tasks and begins executing them. When the timer expires, the original task is moved back into the "Ready" queue to be resumed.

While {lean}`IO.sleep` is the standard way to pause in a task, Lean's internal library provides a more specialized event-driven asynchronous I/O framework in `Std.Internal.IO.Async`. Within this framework, {lean}`Std.Internal.IO.Async.sleep` is used to pause execution without blocking the task manager's thread pool. 
This framework is an implementation of an Event Loop. It is designed to handle thousands of concurrent operations (like network requests or timers) using a small, fixed number of OS threads (usually equal to the number of CPU cores).

```lean
/-- 
  Computes the sum of first n numbers.
  This represents the "Work" the agent does after waking up.
--/
def sumFirstN (n : Nat) (acc : Nat := 0) : Nat :=
  match n with
  | 0 => acc
  | n + 1 => sumFirstN n (acc + (n + 1))

/--
  A helper to print the current Process ID. 
  This confirms we are in the same OS process.
--/
def printSystemIdentity (label : String) : IO Unit := do
  let pid ← IO.Process.getPID
  -- If you want to check thread ID,
  -- let tid ← IO.getTID
  IO.println s!"[{label}] PID: {pid}"

/--
  The Enhanced Async Sleeper.
  It performs: 1. Identity Check -> 2. Async Sleep 
  -> 3. Computation -> 4. Identity Check
--/
def persistentAsyncSleeper (n : Nat) : IO Unit := do
  IO.println "[Sleeper] --- Phase 1: Pre-Sleep ---"
  printSystemIdentity "Sleeper-Start"
  
  let duration := Millisecond.Offset.ofInt 2000
  let computation : Async Unit := do
    -- This block runs inside the Async context
    Std.Internal.IO.Async.sleep duration
    -- After waking up, perform the computation
    let total := sumFirstN n
    IO.println s!"[Sleeper] Computation Complete: 
      Sum of 1 to {n} = {total}"

  -- Execute the async block
  computation.block
  
  IO.println "[Sleeper] --- Phase 2: Post-Sleep ---"
  printSystemIdentity "Sleeper-End"
  -- now returns to taskPulse task

/--
  A Concurrent Worker (taskPulse) to prove 
  the thread pool is active.
--/
def taskPulse (iterations : Nat) : IO Unit := do
  for i in [0:iterations] do
    IO.println s!"[taskPulse] Pulse {i+1}..."
    printSystemIdentity s!"taskPulse-Loop-{i+1}"
    IO.sleep 500 -- Sleep for 500ms

def asyncSleepEg : IO Unit := do
  IO.println "Starting Async Workflow..."

  -- Spawn the taskPulse as a background Task
  let hTask ← IO.asTask (taskPulse 6)

  -- Run our sleeper/computer on the main execution path
  persistentAsyncSleeper 10000
  
  -- Synchronize
  let _ ← IO.wait hTask
  IO.println "Workflow Finished."

/-
Starting Async Workflow...
[Sleeper] --- Phase 1: Pre-Sleep ---
[Sleeper-Start] PID: 59432
[taskPulse] Pulse 1...
[taskPulse-Loop-1] PID: 59432
[taskPulse] Pulse 2...
[taskPulse-Loop-2] PID: 59432
[taskPulse] Pulse 3...
[taskPulse-Loop-3] PID: 59432
[taskPulse] Pulse 4...
[taskPulse-Loop-4] PID: 59432
[Sleeper] Computation Complete: Sum of 1 to 10000 = 50005000
[Sleeper] --- Phase 2: Post-Sleep ---
[Sleeper-End] PID: 59432
[taskPulse] Pulse 5...
[taskPulse-Loop-5] PID: 59432
[taskPulse] Pulse 6...
[taskPulse-Loop-6] PID: 59432
Workflow Finished.
-/
-- #eval asyncSleepEg
```

You might notice the use of `.block` in the example. What does this do?

- *Local vs. Global Blocking:* `computation.block` executes the current Task, but it does not block the underlying OS Thread.

- *The Event Loop:* When you call `.block` on an Async object, you are essentially telling the Lean runtime, "I am going to sit here and wait for this specific result. In the meantime, use my thread to run any other tasks in the queue." Since the async thread went to sleep, after it is done sleeping and yields control(via an interrupt), the original task is continued, computing the sum of the first N numbers, which when done goes back to the {lean}`taskPulse` task and finished it.

*If the thread is not blocked, who is waking up the sleeping task?*

A task cannot go to waitqueue of the OS. Instead, the runtime uses `epoll` to delegate the timer to the OS kernel, which serves as the global timekeeper. While the {lean}`Task` is moved into a logical wait queue in the runtime's memory, the OS Thread remains unblocked and free to rotate to other pending work. Note that *tid* may be different, but *pid* remains the same for sure.
