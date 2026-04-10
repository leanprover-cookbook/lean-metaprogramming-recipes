import VersoManual
import Cookbook.Lean
import Cookbook.IO.SpawningChildProcess
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

# Terminating a Process

%%%
tag := "terminating-a-process"
number := false
%%%

{index}[Terminating a Process]

You can use {lean}`IO.Process.exit` to terminate current process with a specific exit code. By convention, an exit code of `0` indicates success, and any non-zero code indicates an error.

```lean
def terminateProcess (someCondition : Bool) : IO Unit := do
  if someCondition then
    IO.Process.exit 0 -- Success
  else
    IO.println s!"Condition not met. Terminating process..."
    IO.Process.exit 1
```

You can also spawn a new process using {lean}`IO.Process.forceExit` to force kill current process abrupty.

Also, you can kill any other process by spawning a child process and giving PID of victim process using Linux's `kill` command(or your machine's version for it) too.

# File Compression and Decompression

%%%
tag := "file-compression-decompression"
number := false
%%%

{index}[File Compression and Decompression]

Lean does not have built-in support for file compression, but we can easily call external programs like `gzip` or `zip` to perform these tasks. See {ref "spawning-child-process"}[Spawning a Child Process] recipe for more information on how to run external commands from Lean.

*Warning*: Since we are using external programs, these are system-dependent and make sure to have the necessary tools installed on your system. Change the commands accordingly for different operating systems or compression formats.

Using the functions defined above, we can easily perform common system tasks like compressing files or creating archives.

1. Using `gzip`

The `gzip` command is a standard tool for single-file compression.

```lean
def compressFile (path : System.FilePath) : IO Unit := do
  let _ ← runExternalProgram "gzip" #["-k", path.toString]
  IO.println s!"Compressed {path}"
```

2. Creating a `.zip` Archive

To archive multiple files or directories, we can use the `zip` utility.

```lean
def createArchive (archiveName : String) 
    (files : Array String) : IO Unit := do
  let _ ← runExternalProgram "zip" (#[archiveName] ++ files)
  IO.println s!"Created archive {archiveName}"
```

To decompress a `.zip` file, we can use the `unzip` command:

```lean
def decompressArchive (archiveName : String) : IO Unit := do
  let _ ← runExternalProgram "unzip" #["-o", archiveName]
  IO.println s!"Decompressed archive {archiveName}"
```

For any other compression formats, you can similarly call the appropriate command-line tool using the {name}`runExternalProgram` function.

# Reading Environment Variables

%%%
tag := "reading-environment-variables"
number := false
%%%


{index}[Reading Environment Variables]

You can use {lean}`IO.getEnv` to retrieve the value of an environment variable. Since a variable might not be set, it returns an {lean}`Option String`.

```lean
def checkUser : IO Unit := do
  let user? ← IO.getEnv "USER"
  match user? with
  | some name => IO.println s!"Hello, {name}!"
  | none      => IO.println "Could not find USER variable."
```

# Deadlocking the Task System

%%%
tag := "deadlocking-the-task-system"
number := false
%%%

{index}[Deadlocking the Task System]

::: contributors
:::

Here we describe about deadlocks and how to prevent yourself from falling into this trap. This is less of a recipe but more of a conceptual understanding about blindly spawning too many Tasks.

To know basics of about {lean}`Task`s, check out {ref "spawning-tasks-and-worker-threads"}[Spawning Tasks and Worker Threads] before this. 

## What is a Deadlock? (The Stuck Pizza Shop)

Imagine a pizza shop with only 4 chefs. These chefs are the Worker Threads. They are the only ones who can actually cook. 

A *Deadlock* happens when all the chefs stop working because they are waiting for each other. Imagine 4 customers order a "Mystery Pizza."
1. Each chef starts making the dough.
2. Then, each chef realizes they need a secret sauce made by another chef.
3. *The Mistake:* Instead of doing other work, every chef stands perfectly still with their hands out, saying: "I will not move until I get my sauce!"

Because all 4 chefs are standing still waiting, there is nobody left to actually cook the sauce. The shop is stuck forever. In programming, we call this *Thread Starvation*.


## The Deadlocked Code

In this example, we try to run 100000 tasks, this will throw an error as mentioned below. Since today machine's are modern, more powerful with multithreading and multicore processing, this number increases before the thread creation stops.

```lean
def potentialDeadlock (n : Nat := 100000) : IO Unit := do
  -- We try to start n tasks
  let tasks ← (List.range n).mapM fun i => 
    IO.asTask do
      let subTask ← IO.asTask (pure i)
      
      -- ERROR: IO.wait blocks the Chef (Thread).
      -- If all Chefs are waiting here,
      -- nobody can start the subTask!
      match (← IO.wait subTask) with
      | .ok val => pure (val+1)
      | .error e => throw e

  -- The program will likely hang here forever
  for t in tasks do
    match (← IO.wait t) with
    | .ok res => IO.println s!"Result: {res}"
    | .error e => IO.println s!"Error: {e}"
/-
libc++abi: terminating due to uncaught exception of type
lean::exception: failed to create thread
-/
-- #eval potentialDeadlock
```

*Why it fails:*
When you call {lean}`IO.wait` inside a task, you are telling the Worker Threads to sit down and wait. Since the number of threads is *finite* (limited), once they are all "sitting and waiting," there is no one left to run the subTask.

## Solution Using {lean}`IO.bindTask` (The "Sticky Note" Way)

The Safe Solution is to use *Asynchronous Composition*. Instead of making a chef wait, we give them a "Sticky Note." 

When a chef finishes the dough, they write a note: "When the sauce is ready, whoever is free should finish this pizza." Then, the chef leaves the kitchen so another chef can use their spot to make the sauce!

```lean
def safeFromDeadlock (n : Nat := 1000000) : IO Unit := do
  let tasks ← (List.range n).mapM fun i => do
    let t1 ← IO.asTask (pure i)
    
    -- Use bindTask to "chain" the next part.
    -- does NOT block a thread but registers a callback.
    IO.bindTask t1 fun
      | .ok val => IO.asTask (pure (val + 1))
      | .error e => throw e

  -- Now it's safe to wait from the "Outside" (Main Thread)
  for t in tasks do
    match (← IO.wait t) with
    | .ok res => IO.println s!"Result: {res}"
    | .error e => IO.println s!"Error: {e}"

-- No error here, but it will take time since `n` is huge.
-- #eval safeFromDeadlock
```

## Why this is Better

- *No Waiting:* {lean}`IO.bindTask` doesn't make a chef stand still. It tells the shop manager to handle the hand-off later.
- *Thread Recycling:* As soon as the first part of the task is done, the *Worker Thread* is released. It can immediately go back to the pool to work on the next task or a sub-task.
- *Efficiency:* This allows you to handle thousands of tasks even if you only have a few CPU cores, because no thread is ever wasted just "sitting and waiting."

