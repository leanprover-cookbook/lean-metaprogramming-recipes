import VersoManual
import Cookbook.Lean
import Lake.Toml
import Cookbook.DataStructures.TOML.ParsingToml

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean
open Lake Toml Lean Parser

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Accessing and Modifying TOML" =>

%%%
tag := "accessing-modifying-toml"
number := false
%%%

::: contributors
:::

The {name}`Lake.DecodeToml` and {name}`Lake.ToToml` classes allow you to automatically 
transform TOML tables into Lean structures and vice versa.

# Reading values from TOML

{index}[Reading values from TOML]

To transform TOML into Lean types, we primarily use two methods: high-level type-safe decoding via the {name}`Lake.DecodeToml` class, and low-level extraction using {name}`Lake.Toml.Table` methods.

1. *decodeTable*: Converts a generic {name}`Lake.Toml.Value` into a {lean}`Table`. This is how you "open the box" to access the keys inside a nested section.
2. *decode*: A high-level method on {lean}`Table` that retrieves a key and immediately converts it to a Lean type (like {lean}`String`).
3. *decodeValue*: A low-level method that simply retrieves the raw {name}`Lake.Toml.Value` for a key.

```lean
structure ToolConfig where
  name    : String
  version : String
  active  : Bool := true
deriving Inhabited, Repr

instance : DecodeToml ToolConfig where
  decode v := do
    -- Cast the generic Value to a Table
    let tbl ← v.decodeTable
    -- Decode specific keys into Lean types
    let name ← tbl.decode `name
    let version ← tbl.decode `version
    let active ← tbl.decode? `active
    return { name, version, active := active.getD true }

/-- 
  A general helper to get any type from a Table.
  If the key is missing or the type is wrong, it panics.
-/
def getTomlValue [DecodeToml α] [Inhabited α] 
    (table : Table) (key : String) : α :=
  match (table.decode key.toName).run #[] with
  | .ok v _ => v
  | .error _ errs => panic! 
      s!"Failed to get '{key}': {errs.toList.map (·.msg)}"

/-- Another safe helper to decode a
  specific key into a Lean type. -/
def decodeTomlValue [DecodeToml α] (table : Table) 
    (key : String) : Except String α :=
  match (table.decode key.toName).run #[] with
  | .ok v _ => .ok v
  | .error _ errs => .error 
    s!"Decode error for '{key}': {errs.toList.map (·.msg)}"

def egGetValue : CoreM String := do
  let input := "
name = \"Dragonbot\"
version = 4
is_active = true
"
  let table ← parseToml input
  
  let name : String := getTomlValue table "name"
  let ver  : Int    := getTomlValue table "version"
  let act  : Bool   := getTomlValue table "is_active"
  
  -- You can even get the raw 'Value' box if you want
  let _raw : Value := getTomlValue table "name"
  return s!"{name} v{ver} (Active: {act})"

#eval egGetValue
```

# Encoding and Modifying TOML

{index}[Encoding TOML]
{index}[Modifying TOML objects]

To convert Lean structures back to TOML, implement the {name}`Lake.ToToml` class. When creating a table, we use `Value.table .missing tbl` to wrap our dictionary into a TOML value.

```lean
instance : ToToml ToolConfig where
  toToml c :=
    let tbl := Table.empty
      |> Table.insert `name c.name
      |> Table.insert `version c.version
      |> Table.insert `active c.active
    -- We use .missing because this Value 
    -- is being generated programmatically
    Value.table .missing tbl

def egTomlEncode (cfg : ToolConfig) : CoreM String := do
  let val := toToml cfg
  -- If it's a table, we can pretty-print it for a file
  if let .table _ tbl := val then
    return ppTable tbl
  else
    return toString val

#eval egTomlEncode
  { name := "my-tool", version := "0.1.0", active := true }
```

For a given {lean}`Table`, if you want to modify it (e.g., add or update keys), you can use {name}`Table.insert` to create a new table with the desired changes. For default values, you can use the {name}`Table.insertD` method instead.

```lean
def updateValue [ToToml α] (table : Table) (key : String) 
    (newValue : α) : Table :=
  -- If the key exists, this replaces it; else, it adds it
  Table.insert key.toName newValue table

def safeUpdateValue [ToToml α] (table : Table)
  (key : String) (newValue : α) : Table :=
  -- Check if the key exists before updating
  match (table.decodeValue key.toName).run #[] with
  | .ok .. => updateValue table key newValue
  | .error .. => 
    panic! s!"Key '{key}' does not exist in the table."

def egUpdate : CoreM String := do
  let input := "name = \"Lean4\"\nversion = \"4.15.0\""
  let table ← parseToml input
  -- Update existing key
  let table := updateValue table "version" "4.16.0"
  -- Add new key
  let table := updateValue table "active" true
  return ppTable table

#eval egUpdate
```
