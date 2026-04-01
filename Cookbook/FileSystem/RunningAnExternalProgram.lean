import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Running an external program" =>

%%%
tag := "running-an-external-program"
number := false
%%%

::: contributors
:::

{index}[Running an external program]

In order to run an external program from inside a Lean file, we can use {lean}`IO.Process.run`, which takes a {lean}`IO.Process.SpawnArgs` structure and returns the command's stdout as a {lean}`String`.

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

# Application: File Compression and Decompression

%%%
tag := "file-compression-decompression"
number := false
%%%

{index}[File Compression and Decompression]

Lean does not have built-in support for file compression, but we can easily call external programs like `gzip` or `zip` to perform these tasks. 

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
