import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Reading from a file" =>

%%%
tag := "reading-from-file"
number := false
%%%

::: contributors
:::

{index}[Reading from a file]

Reading from a file is needs to be done in the {lean}`IO` monad. To read the whole file as a string, you can use {lean}`IO.FS.readFile`:

```lean
def readWholeFile (path : System.FilePath) : IO String :=
  IO.FS.readFile path
```

If you want to use the file text in a variable, you can get the result of {lean}`IO.FS.readFile` and manipulate it as a string:

```lean
def readAndUse (path : System.FilePath) : IO String := do
  let content ← IO.FS.readFile path
  -- Do something with content, like convert it to uppercase
  return content.toUpper
```

If you want to read the file line by line, you can use {lean}`IO.FS.withFile` to get a handle to the file and then read lines from it. The {lean}`IO.FS.Handle.getLine` method reads a line from the file:

```lean
def readFirstLine (path : System.FilePath) : IO String :=
  IO.FS.withFile path .read fun handle => do
    handle.getLine
```

If you want to read all lines into an array, you can use {lean}`IO.FS.lines`:

```lean
def readAllLines (path : System.FilePath) :
    IO (Array String) :=
  IO.FS.lines path
```

Now say you want to trim the line you read by removing leading and trailing whitespace. You can use the {lean}`String.trimAscii` method to do that. This will also remove `\n` characters at the end of the line:

```lean
def readTrimmedLines (path : System.FilePath) :
    IO String := do
  let line ← readFirstLine path
  return line.trimAscii.toString 
```
