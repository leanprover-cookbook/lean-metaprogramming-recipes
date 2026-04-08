import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Reading & Writing JSON Files" =>

::: contributors
:::

{index}[Handling JSON files]

This section covers how to interact with the file system to read and write JSON data. For details on how to construct or manipulate JSON objects themselves, see {ref "creating-json-objects"}[Creating JSON Objects].

# How to read a JSON file

%%%
tag := "reading-json-file"
number := false
%%%

{index}[Reading a JSON file]

To read a JSON file, you can use the {lean}`Lean.Json` module in Lean. You read the file as a string using {lean}`IO.FS.readFile` and then parse it using {lean}`Lean.Json.parse`:

```lean
def readJsonFile (path : System.FilePath) : IO Json := do
  let content ← IO.FS.readFile path
  match Json.parse content with
  | Except.ok json => return json
  | Except.error err =>
    throw <| IO.userError
      s!"Failed to parse JSON from {path}: {err}"
```
 
# How to write to JSON files

%%%
tag := "writing-json-file"
number := false
%%%

{index}[Writing to JSON files]

To write JSON data to a file, you first convert the `Json` object to a string. You can use `toString` for a compact representation or `.pretty` for a formatted version.

```lean
def writeJsonToFile (path : System.FilePath) (data : Json)
  : IO Unit := do IO.FS.writeFile path (data.pretty)
```

If you need more control, such as setting the indentation level, you can use the `.pretty` method with an argument:

```lean
def writeJsonIndented (path : System.FilePath) (data : Json)
  : IO Unit := do  IO.FS.writeFile path (data.pretty 2)
  -- .pretty(2) formats the JSON with an indent of 2 spaces
```
