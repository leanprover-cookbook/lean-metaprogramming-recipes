import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Spawning a Child Process" =>

%%%
htmlSplit := .never
%%%

::: contributors
:::


# Spawning a Child Process

%%%
tag := "spawning-child-process"
number := false
%%%

{index}[Spawning a Child Process]

In order to run an external program from inside a Lean file, we can use {lean}`IO.Process.run`, which takes a {lean}`IO.Process.SpawnArgs` structure and returns the command's stdout as a {lean}`String`. You can check out [IO.Process.SpawnArgs](https://lean-lang.org/doc/reference/latest/IO/Processes/#IO___Process___SpawnArgs___mk) in Lean4 reference manual for more details on the available options.

```lean
def runExternalProgram (cmd : String) (args : Array String)
    : IO String :=
  IO.Process.run {
    cmd := cmd
    args := args
  }

-- #eval runExternalProgram "curl" #["https://www.test.com"]
```

If the program fails (returns a non-zero exit code), {lean}`IO.Process.run` will throw an exception. To handle the output more gracefully and see the exit code and stderr, you can use {lean}`IO.Process.output`.

```lean
def runExternalWithOutput (cmd : String)
    (args : Array String) : IO Unit := do
  let out ← IO.Process.output {
    cmd := cmd
    args := args
  }
  if out.exitCode == 0 then
    IO.println s!"Command succeeded: {out.stdout}"
  else
    IO.println s!"Command failed. Exit Code: {out.exitCode},
      Error: {out.stderr}"
```

If you want to know more information about the process, such as its PID, you can use {lean}`IO.Process.spawn` to start the process and get a `IO.Process` object.

```lean
def spawnExternalProgram (cmd : String) 
    (args : Array String) : IO Unit := do
  let proc ← IO.Process.spawn {
    cmd := cmd
    args := args
  }
  IO.println s!"Spawned process with PID: {proc.pid}"
  let exitCode ← proc.wait
  IO.println s!"Process exited with code: {exitCode}"

-- #eval spawnExternalProgram "touch" #["test.txt"]
```

## Get PID of a Process

%%%
tag := "get-pid-process"
number := false
%%%

{index}[Get PID of a Process]

To get the PID a process you spawn, you use {lean}`IO.Process.Child.pid` method.

```lean
def getProcessInfo (cmd : String) (args : Array String) 
  : IO Unit := do
  let proc ← IO.Process.spawn {
    cmd := cmd
    args := args
  }
  -- for current process
  let cpid ← IO.Process.getPID
  IO.println s!"Current Process PID: {cpid}"
  IO.println s!"Child Process PID: {proc.pid}"
```

To check the status of a child process if it is still running, you can use the {lean}`IO.Process.Child.tryWait` method


# Setting Environment Variables for Child Process

%%%
tag := "setting-environment-variables-child-process"
number := false
%%%

{index}[Setting Environment Variables for Child Process]

You can set environment variables when spawning a new child process to configure its environment. Remember that it is not possible to change the environment of the current process since it's already running.

When using [{lean}`IO.Process.SpawnArgs`](https://lean-lang.org/doc/reference/latest/IO/Processes/#IO___Process___SpawnArgs___mk), you can pass an `env` array to specify variables for the new process.

```lean
def runWithCustomEnv : IO Unit := do
  let child ← IO.Process.spawn {
    cmd := "printenv",
    args := #["MY_VAR"],
    env := #[("MY_VAR", "1234")]
  }
  let exitCode ← child.wait
  IO.println s!"Process exited with code: {exitCode}"
```

This ensures that `MY_VAR` is available to the child process without affecting the parent process's environment.
