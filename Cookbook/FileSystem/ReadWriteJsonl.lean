import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Handling JSONL File" =>


::: contributors
:::

{index}[Handling JSONL files]

JSONL (JSON Lines) is a format where each line is a valid JSON object. This is particularly useful for large datasets as it allows for stream processing and is less sensitive to file corruption than a single large JSON array.

# How to Read JSONL files

%%%
tag := "reading-jsonl-file"
number := false
%%%

{index}[Reading JSONL files]

To read a JSONL file, we use {lean}`IO.FS.lines` to get an array of strings and then parse each non-empty line.

```lean
def readJsonlFile (path : System.FilePath) :
    IO (Array Json) := do
  let lines ← IO.FS.lines path
  let mut result := #[]
  for line in lines do
    let line := line.trim
    if line.isEmpty then continue
    match Json.parse line with
    | .ok j => result := result.push j
    | .error err =>
      throw <| IO.userError s!"Failed to parse line: {err}"
  return result
```

# How to Write JSONL files

%%%
tag := "writing-jsonl-file"
number := false
%%%

{index}[Writing JSONL files]

When writing JSONL, each object must be rendered as a single line without internal newlines. You can use {lean}`Lean.Json.compress` to ensure the output is compact.

1. Writing an array of JSON objects

```lean
def writeJsonlFile (path : System.FilePath)
  (data : Array Json) : IO Unit := do
  let lines := data.map (·.compress)
  IO.FS.writeFile path (String.intercalate "\n"
    lines.toList ++ "\n")
```

2. Writing custom structures to JSONL

For large logs or datasets, it is better to use a handle and write line by line.

```lean
structure LogEntry where
  timestamp : String
  level     : String
  message   : String
deriving ToJson

def writeLogs (path : System.FilePath)
    (logs : Array LogEntry) : IO Unit := do
  IO.FS.withFile path .write fun handle => do
    for log in logs do
      handle.putStrLn (toJson log).compress
```
