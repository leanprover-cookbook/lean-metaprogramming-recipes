import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Spawning Tasks and Worker Threads" =>

%%%
htmlSplit := .never
%%%

::: contributors
:::

# Spawning Tasks and Worker Threads

%%%
tag := "spawning-tasks-and-worker-threads"
number := false
%%%


{index}[Spawning Tasks and Worker Threads]

Lean 4 supports lightweight concurrency through {lean}`Task`. You can spawn tasks to perform {lean}`IO` in the background and wait for their results later. {lean}`Task` `α` is a primitive for asynchronous computation. It represents a computation that will resolve to a value of `type α`, possibly being computed on another thread.

Do check out information about the {lean}`Task` API can be found in the Lean 4 reference manual [Task and Threads](https://lean-lang.org/doc/reference/latest/IO/Tasks-and-Threads) section.


## Spawning a Task

If you have a pure computation that is very heavy, you can use {lean}`Task.spawn` to run it in parallel without the {lean}`IO` monad. As mentioned before, when a {lean}`Task` `α` is spawned, it will give you output of type `α`. Each {lean}`Task` `α` is done by a Worker Thread spawned by Lean. 

```lean
def computeSomething : Nat :=
  let t := Task.spawn (fun _ => 2 + 2)
  t.get
```

## Spawning Background Tasks

%%%
tag := "spawning-background-task"
number := false
%%%


Tasks which have side effects beyond computation, you should use {lean}`IO.asTask` to run an {lean}`IO` action in a background thread. It returns a {lean}`Task` that will eventually contain the result (wrapped in an {lean}`Except`). These are asynchronous and automatically runs in the background.

```lean
def backgroundWork : IO Unit := do
  let task ← IO.asTask do
    for i in [1:5] do
      IO.println s!"Working... {i}"
      for _ in [1:10000] do
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

## *IO.asTask* and *BaseIO.Task*

%%%
tag := "io-baseio-astask"
number := false
%%%

{index}[IO.asTask and BaseIO.asTask]

{lean}`IO.asTask` creates a task for operations that might fail, wrapping the result in an {lean}`Except IO.Error` box, whereas {lean}`BaseIO.asTask` is used for guaranteed, error-free logic and returns the raw value directly. 

Basically, {lean}`IO.asTask` will help you in better handling if you want to use {name}`throw`, {lean}`IO.userError`, etc. while {lean}`BaseIO.asTask` will not. Hence you will have to do appropriate error handling to extract value or show error. But if you know for sure that your {lean}`Task` will succeed for sure and you just need the raw value directly, then {lean}`BaseIO.asTask` can be used.

```lean
/-- A division which fails in IO monad if d is 0 -/
def realDiv (n d : Int) : IO Int := do
  if d == 0 then 
    throw (IO.userError "Error: Division by zero detected!")
  else 
    pure (n / d)

-- Using IO.asTask
-- This is designed to catch the error.
def computeWithIO : IO Unit := do
  let task ← IO.asTask (realDiv 10 0)
  -- wait returns Except IO.Error Int
  -- because realDiv is IO
  let result ← IO.wait task 
  IO.println s!"IO.asTask result: {result}"

-- Using BaseIO.asTask
-- This cannot run realDiv directly because
-- realDiv is not BaseIO. Hence we use pure
def computeWithBaseIO : IO Unit := do
  let task ← BaseIO.asTask (pure (10 / 0))
  -- wait returns Int directly
  let result ← IO.wait task
  IO.println s!"BaseIO.asTask result: {result}"

#eval computeWithIO
#eval computeWithBaseIO
```


# Get Thread ID's

%%%
tag := "get-thread-ids"
number := false
%%%

{index}[Get Thread IDs]

Lean spawns worker threads to execute tasks in parallel for the same process for performing any {lean}`Task`. Thus there can be multiple threads running for the same process. Since these are all asynchronous tasks, the output may come in any order as well.{lean}`Task` execution is scheduled on a bounded worker thread pool, hence it maynot be always done by a separate worker thread. 

This example illustrates that separate worker threads run for each {lean}`Task` hence having different TID's but same PID. You can get the Thread ID using {lean}`IO.getTID`.


```lean
/- 
All will share the same PID but likely report distinct TIDs.
-/
def showWorkerThreadInfo : IO Unit := do
  let pid ← IO.Process.getPID
  IO.println s!"Main Process PID: {pid}"

  -- Create a list of 4 asynchronous tasks
  let tasks ← (List.range 4).mapM fun i => 
    IO.asTask do
      let tid ← IO.getTID
      IO.println s!"Task {i} has TID: {tid} (PID: {pid})"

  -- Wait for all tasks to complete
  for t in tasks do
    let _ ← IO.wait t

  IO.println s!"For the main thread, 
    TID: {← IO.getTID} (PID: {pid})"

/-
Task 1 has TID: 348178 (PID: 23379)
Task 0 has TID: 348148 (PID: 23379)
Task 2 has TID: 348177 (PID: 23379)
Task 3 has TID: 348179 (PID: 23379)
Main Process PID: 23379
For the main thread, TID: 348175 (PID: 23379)
-/
-- #eval showWorkerThreadInfo
```


