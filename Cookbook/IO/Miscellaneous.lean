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

You can also spawn a new process using {lean}`IO.Process.forceExit` to force kill current process. Also, you can kill any other process by spawning a child process and giving PID of victim process using Linux's `kill` command(or your machine's version for it) too.

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

{index}[Deadlock]

Lean 4's task system uses a fixed-size thread pool (typically equal to the number of CPU cores). A common pitfall is to call a blocking operation like {lean}`IO.wait` or {lean}`Task.get` from within another task. 

Because the thread pool is finite, if you have more tasks waiting on other tasks than there are available threads, the system will *deadlock*. The blocked tasks continue to occupy their threads while waiting for work that can never be scheduled because all threads are already full.

## Example of a Deadlock Scenario

If you try to run more tasks than you have CPU cores, and each task waits for another task to finish, you might run into this issue:

```lean
-- This code will create a deadlock
def potentialDeadlock : IO Unit := do
  let tasks ← (List.range 100).mapM fun i => IO.asTask do
    let subTask ← IO.asTask do
      IO.sleep 100
      return i
    -- CRITICAL ERROR: Blocking wait inside a task
    let res ← IO.wait subTask
    return res
  
  let _ ← tasks.mapM (fun t => IO.wait t)
```

### Avoiding Deadlocks

To avoid deadlocks, prefer asynchronous composition using {lean}`IO.bindTask`. This allows you to chain tasks together without holding a thread idle while waiting for the result.

```lean
/--
  Safe version: Instead of waiting inside a task, 
  we chain the tasks together.
--/
def safeAsyncComposition : IO Unit := do
  let tasks ← (List.range 100).mapM fun i => do
    -- 1. Create the first task
    let t1 ← IO.asTask (pure i)
    
    -- 2. Use bindTask to create a dependency.
    -- This does NOT block a thread. It registers a callback.
    IO.bindTask t1 (fun 
      | .ok val => IO.asTask do 
          IO.sleep 100
          return val
      | .error e => throw e)

  -- 3. Wait for the final results from the main thread
  for t in tasks do
    let res ← IO.wait t
    IO.println s!"Finished task: {res}"
```

By using {lean}`IO.bindTask`, the scheduler only runs the next part of the computation once the first task is complete, freeing up the thread in the meantime.
