import VersoManual
import Cookbook.Lean

open Verso.Genre Manual
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command
open Cookbook

set_option pp.rawOnError true

#doc (Manual) "Running JSON File" =>

# How to read a JSON file

%%%
tag := "reading-json-file"
number := false
%%%

{index}[Reading a JSON file]

To read a JSON file, you can use the `Json` module in Lean as `import Lean.Data.Json`. You can read the file as a string and then parse it using `Json.parse`:

```lean
def readJsonFile (path : System.FilePath) : IO Json := do
  let content ← IO.FS.readFile path
  match Json.parse content with
  | Except.ok json => return json
  | Except.error err =>
    throw <| IO.userError s!"Failed to parse JSON: {err}"
```

