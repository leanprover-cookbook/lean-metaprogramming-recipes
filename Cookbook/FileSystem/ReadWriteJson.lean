import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Handling JSON Files" =>

::: contributors
:::

{index}[Handling JSON files]

# How to read a JSON file

%%%
tag := "reading-json-file"
number := false
%%%

{index}[Reading a JSON file]

To read a JSON file, you can use the {lean}`Lean.Json` module in Lean as `import Lean.Data.Json`. You can read the file as a string and then parse it using {lean}`Lean.Json.parse`:

```lean
def readJsonFile (path : System.FilePath) : IO Json := do
  let content ← IO.FS.readFile path
  match Json.parse content with
  | Except.ok json => return json
  | Except.error err =>
    throw <| IO.userError s!"Failed to parse JSON: {err}"
```

# How to write to JSON files

%%%
tag := "writing-json-file"
number := false
%%%

{index}[Writing to JSON files]

To write to a JSON file, you can use the {lean}`Lean.Json` module to convert your data into JSON format. If you are writing a fresh JSON file, you can create a JSON object and then write it to the file or if you want to load and write to an existing JSON file, you can read the existing content, modify it, and then write it back to the file. Refer {ref "reading-json-file"}[Reading from JSON] for how to read from a JSON file.


1. If you are making a new JSON file:
```lean
def writeToJsonFile (path : System.FilePath) (data : Json)
  : IO Unit := do
  let file := ← IO.FS.Handle.mk path IO.FS.Mode.write
  file.putStr (toString data)
```

2. Writing JSON data inside the function and not as an argument:

```lean 
def writeJsonToFile (path : System.FilePath) : IO Unit := do
  let data: Json := Json.mkObj [("name", "Bob"), ("age", 9)]
  -- you can also use the json macro:
  let _data' : Json := json% {
    name: "Bob",
    age: 9
  }
  IO.FS.writeFile path (toString data)
  -- IO.FS.writeFile path (toString _data')
```

3. Saving a custom structure using {lean}`Lean.ToJson`:

The most common way to write JSON is by defining a structure and deriving a {lean}`Lean.ToJson` instance. This allows you to convert Lean objects directly to JSON.

```lean
structure User where
  name : String
  age  : Nat
  isAdmin : Bool
deriving ToJson, FromJson

def saveUserJson (path : System.FilePath) (user : User)
  : IO Unit := do
  -- .pretty(2) formats the JSON with an indent of 2 spaces
  IO.FS.writeFile path (toJson user).pretty
```

