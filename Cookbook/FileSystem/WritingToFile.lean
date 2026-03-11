import VersoManual
import Cookbook.Lean

open Verso.Genre Manual
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command
open Cookbook

set_option pp.rawOnError true

#doc (Manual) "Writing to a file" =>

# How to write to a file

%%%
tag := "writing-to-file"
number := false
%%%

{index}[Writing to a file]


Writing to a file in Lean can be done using the `IO.FS` module. To create a new file and write a string to it, you can use `IO.FS.Handle.mk` to create a file handle using a string path and the `IO.FS.Mode.write` mode to indicate that you want to write to the file. The `file` has type `IO.FS.Handle`, which means you are given the handle to the file and can do operations on it.

To write a string to the file, you can use the `putStr` method on the file handle. This will overwrite the contents of the file with the string you provide. If the file does not exist, it will be created.

```lean
def writeToFile (path : String) (s : String) : IO Unit := do
  let file := ← IO.FS.Handle.mk path IO.FS.Mode.write
  file.putStr s
```

# How to append text to a file

%%%
tag := "appending-to-file"
number := false
%%%

{index}[Appending to a file]

To append text to a file instead of overwriting it, you can use the `IO.FS.Mode.append` mode when creating the file handle. This will allow you to add new content to the end of the file without deleting the existing content. Note that it will not add a newline character automatically, you would have to include it.

*Important:* `flush` is necessary to ensure that the file handler writes the content to the file immediately. Otherwise, the content may be buffered and not written until later.

```lean
def appendToFile (path : String) (s : String) : IO Unit := do
  let file := ← IO.FS.Handle.mk path IO.FS.Mode.append
  file.putStr s
  file.flush

-- Another way
def appendToFile' (path : System.FilePath) (s : String) : IO Unit := do
  IO.FS.withFile path IO.FS.Mode.append fun handle =>
    handle.putStr s

```
Note, `withFile` is recommended because it ensures the handle is closed and the buffer is flushed, even if an exception is thrown.


Now if you wanted to write the string in the beginning of the file and keep the existing content, you can read the existing content first, then write the new string followed by the old content.

```lean
def prependToFile (path : String) (s : String) : IO Unit := do
  let file := ← IO.FS.Handle.mk path IO.FS.Mode.read
  let oldContent ← file.readToEnd
  let file := ← IO.FS.Handle.mk path IO.FS.Mode.write
  file.putStr (s ++ oldContent)
  file.flush

-- Another way
def prependToFile' (path : System.FilePath) (s : String) : IO Unit := do
  let oldContent ← IO.FS.readFile path
  IO.FS.writeFile path (s ++ oldContent)
```

