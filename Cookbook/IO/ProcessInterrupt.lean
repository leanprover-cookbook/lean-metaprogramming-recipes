import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Process Interruption and Idle Sleep" =>

%%%
tag := "process-interrupt-idle-sleep"
number := false
htmlSplit := .never
%%%

::: contributors
:::

Lean 4 provides several mechanisms to manage concurrent tasks and handle interruptions. This section explores how to implement interruptible sleeps and "idle" states that wait for external signals. Check out how to put a Process to sleep at {ref "sleep-process"}[Putting a Process to Sleep].

# Interruptible Sleep (The "Shift" Pattern)

%%%
tag := "interruptible-sleep-pattern"
number := false
%%%

{index}[Interruptible Sleep]

A common requirement is to put a thread to sleep for a duration, but allow it to be "woken up" or interrupted before the time expires. In Lean, this can be achieved using {lean}`IO.Promise`, see [reference](https://lean-lang.org/doc/reference/latest/IO/Tasks-and-Threads/#The-Lean-Language-Reference--IO--Tasks-and-Threads--Promises). {lean}`IO.Promise` acts as a synchronization primitive that allows one thread to wait for a value that is provided by another thread at a later time. In this context, it serves as a "signal" or a "mailbox" where the sleeping thread waits for the promise to be fulfilled, effectively allowing an external trigger to interrupt the wait.

## Using an Extra Task (Timeout Task)

This method involves spawning a separate task that resolves a promise after a delay. The main worker waits on that same promise.

```lean
def interruptibleWorker (p : IO.Promise Bool) 
    : IO Unit := do
  IO.println "Worker: starting sleep (10s timeout)..."

  let timeoutTask ← IO.asTask do
    IO.sleep 10000
    -- Resolve with 'false' to indicate timeout
    p.resolve false 

  -- Wait for the promise to be resolved 
  -- (either by timeout or interrupt)
  let interrupted ← IO.wait p.result!

  -- CRITICAL: Cancel the timeout task 
  -- so the process can exit immediately
  IO.cancel timeoutTask

  if interrupted then
    IO.println "Worker: interrupted early!"
  else
    IO.println "Worker: finished naturally (timeout)."
```

## Using `IO.waitAny` (Without an Extra Task for Logic)

If you already have multiple tasks running and you want to wait for the *first* one to complete (or a specific "interrupt" task), you can use {name}`IO.waitAny`.

```lean
def waitFirst (t1 t2 : Task α) : IO α := do
  IO.waitAny [t1, t2]
```

You can also use {name}`IO.waitAny` to implement a timeout mechanism by racing a computation task against a timer task.

```lean
/-- Waits for a task to complete or 
  returns a default value after a delay. -/
def waitWithTimeout {α : Type} (action : Task α) 
    (timeoutMs : UInt32) (default : α) : IO α := do
  let timer ← BaseIO.asTask (do 
    IO.sleep timeoutMs
    pure default
  )
  let finished ← IO.waitAny [action, timer]
  return finished
```

# Application: Interrupting Idle Sleep (OS-like Sleep)

%%%
tag := "idle-sleep-application"
number := false
%%%

{index}[Process Idle Sleep]

An "idle sleep" is a state where a process does nothing and consumes minimal resources until it is explicitly woken up by an external event (like a signal or a message).

In Lean, you can implement this by waiting on a promise that has no timeout task associated with it.

```lean
def idleProcess (wakeUpSignal : IO.Promise Unit) 
    : IO Unit := do
  IO.println "Process entering idle state..."
  
  -- This will block indefinitely until 
  -- wakeUpSignal.resolve () is called
  let _ ← IO.wait wakeUpSignal.result!
  
  IO.println "Process woken up! Resuming execution..."

def runSystem : IO Unit := do
  let signal ← IO.Promise.new
  let procTask ← IO.asTask (idleProcess signal)
  
  IO.println "System running... doing other work."
  IO.sleep 3000
  
  IO.println "Main: Triggering wake-up signal."
  signal.resolve ()
  
  let _ ← IO.wait procTask
  IO.println "System shutdown."
```

In this pattern, the "sleep" is truly idle; there is no timer running. The process simply yields until the promise is resolved by another part of the system.
