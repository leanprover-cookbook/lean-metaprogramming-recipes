import VersoManual
import Cookbook.Lean
import Lake.Toml
import Cookbook.DataStructures.TOML.ParsingToml

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean
open Lake Toml Lean Parser

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Encoding and Decoding TOML" =>

%%%
tag := "encoding-decoding-toml"
number := false
%%%

::: contributors
:::

The {name}`Lake.DecodeToml` and {name}`Lake.ToToml` classes allow you to automatically 
transform TOML tables into Lean structures and vice versa.

# Decoding TOML into Lean Structures

{index}[Decoding TOML]

To transform TOML into Lean types, we primarily use two methods: high-level type-safe decoding via the {name}`Lake.DecodeToml` class, and low-level extraction using {name}`Lake.Toml.Table` methods.

1. *{lean}`Value.decodeTable`*: This is used to "cast" a generic {name}`Lake.Toml.Value` into a {name}`Table`. This is usually the first step when decoding a structure, as most TOML files or nested sections are tables of key-value pairs.
2. *{name}`Table.decode`*: A high-level method on {name}`Table` that retrieves a value for a key and immediately attempts to decode it into a specific Lean type (like {lean}`String` or {lean}`Nat`) using its {name}`DecodeToml` instance.
3. *{name}`Table.decodeValue`*: A lower-level method that simply retrieves the raw {name}`Lake.Toml.Value` associated with a key, without attempting any type conversion. This is useful when you want to manually inspect the TOML structure or handle dynamic keys.

```lean
structure ProjectConfig where
  name    : String
  version : String
  active  : Bool := true
deriving Inhabited, Repr

instance : DecodeToml ProjectConfig where
  decode v := do
    -- We first convert the Value into a Table
    let tbl ← v.decodeTable
    -- Then we decode each key into the expected Lean type
    let name ← tbl.decode `name
    let version ← tbl.decode `version
    let active ← tbl.decode? `active
    return { name, version, active := active.getD true }

/-- A helper to get the raw TOML Value from a Table -/
def getValue (table : Table) (key : String) : Value :=
  match (table.decodeValue key.toName).run #[] with
  | .ok v _ => v
  | .error _ errs => panic! 
      s!"Key '{key}' not found: {errs.toList.map (·.msg)}"

/-- A type-safe helper to decode a specific key
  into a Lean type.-/
def getTomlValue [DecodeToml α] (table : Table) 
    (key : String) : Except String α :=
  match (table.decode key.toName).run #[] with
  | .ok v _ => .ok v
  | .error _ errs => .error 
    s!"Decode error for '{key}': {errs.toList.map (·.msg)}"

def egGetValue : CoreM String := do
  let input := 
    "name = \"Lean4\"\nversion = \"4.15.0\"\nactive = true"
  let table ← parseToml input
  let nameValue := getValue table "name"
  match nameValue with
  | .string _ s => return s!"Do you know about {s}!"
  | _ => throwError "Expected string"

#eval egGetValue
```

# Encoding and Modifying TOML

{index}[Encoding TOML]

You can convert Lean structures back to TOML by implementing 
the {name}`Lake.ToToml` class. 

Note that {name}`Value.toString` produces an *inline table* 
(e.g., `{a = 1, b = 2}`), which is valid TOML but often not 
preferred for whole files. 
To produce the standard multi-line format, use {name}`Lake.Toml.ppTable` on the underlying table.

```lean
instance : ToToml ProjectConfig where
  toToml c :=
    let tbl := Table.empty
      |> Table.insert `name c.name
      |> Table.insert `version c.version
      |> Table.insert `active c.active
    /- .missing is to fill up missing metadata 
    in input table -/
    Value.table .missing tbl

def egTomlEncode (cfg : ProjectConfig) : CoreM String := do
  let val := toToml cfg
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

