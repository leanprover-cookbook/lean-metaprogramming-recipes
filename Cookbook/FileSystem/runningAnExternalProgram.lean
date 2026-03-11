import VersoManual
import Cookbook.Lean

open Verso.Genre Manual
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command
open Cookbook

set_option pp.rawOnError true

#doc (Manual) "Running an external program" =>

%%%
tag := "running-an-external-program"
number := false
%%%

{index}[Running an external program]

In order to run an external program from inside a Lean file, we can use the `IO.Process` API. The easiest way is to use `IO.Process.run`, which takes a `SpawnArgs` structure and returns the command's stdout as a `String`.

```lean
def runExternalProgram (cmd : String) (args : Array String) : IO String :=
  IO.Process.run {
    cmd := cmd
    args := args
  }

-- #eval runExternalProgram "curl" #["https://www.example.com"]
```

If the program fails (returns a non-zero exit code), `IO.Process.run` will throw an exception. To handle the output more gracefully and see the exit code and stderr, you can use `IO.Process.output`.

```lean
def runExternalWithOutput (cmd : String) (args : Array String) : IO Unit := do
  let out ← IO.Process.output {
    cmd := cmd
    args := args
  }
  if out.exitCode == 0 then
    IO.println s!"Command succeeded with output: {out.stdout}"
  else
    IO.println s!"Command failed with exit code {out.exitCode}: {out.stderr}"
```

If you want to know more information about the process, such as its PID, you can use `IO.Process.spawn` to start the process and get a `Process` object.

```lean
def spawnExternalProgram (cmd : String) (args : Array String) : IO Unit := do
  let proc ← IO.Process.spawn {
    cmd := cmd
    args := args
  }
  IO.println s!"Spawned process with PID: {proc.pid}"
  let exitCode ← proc.wait
  IO.println s!"Process exited with code: {exitCode}"

-- #eval spawnExternalProgram "touch" #["test.txt"]
```

