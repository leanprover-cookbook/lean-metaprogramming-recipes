import VersoManual
import Cookbook.Lean
import Lake.Toml
import Cookbook.DataStructures.TOML.ParsingToml
import Cookbook.DataStructures.TOML.AccessingModifyingToml

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean
open Lake Toml Lean Parser

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Working with lakefile.toml" =>

%%%
tag := "lakefile-toml"
number := false
%%%

::: contributors
:::

Lean 4 uses *lakefile.toml* for package configuration. While you usually edit this file manually, you might want to read or update it programmatically using `Lake.Toml`.

# Parsing a lakefile.toml

%%%
tag := "parsing-lakefile-toml"
number := false
%%%

{index}[Parsing lakefile.toml]

A *lakefile.toml* is essentially a TOML table. We can define structures to match specific sections like `[[lean_lib]]` or `[[require]]`.

```lean
structure LibConfig where
  name : String
  moreLeanArgs : Array String
deriving Inhabited, Repr

instance : DecodeToml LibConfig where
  decode v := do
    let tbl ← v.decodeTable
    return { 
      name := ← tbl.decode `name, 
      moreLeanArgs := ← tbl.decode `moreLeanArgs 
    }

/-- Reads the library name from the [[lean_lib]] section -/
def readLibName (path : System.FilePath) : 
    CoreM String := do
  let content ← IO.FS.readFile path
  let table ← parseToml content

  let libVal : Value := getTomlValue table "lean_lib"
  
  -- We decode to Array lean_lib 
  -- since it's an array of tables
  let result : EStateM.Result Unit (Array DecodeError) 
    (Array LibConfig) := decodeToml libVal #[]
  
  match result with
  | .ok libs _ => 
      match (libs[0]? : Option LibConfig) with
      | some { name := n, moreLeanArgs := args } =>
          return s!"Library name: {n} and Args: {args}"
      | none => return "No library found"
  | .error .. => return "Failed to decode lean_lib section."

#eval readLibName "lakefile.toml"
```

# Updating Dependencies in lakefile.toml

%%%
tag := "updating-lakefile-toml"
number := false
%%%

{index}[Updating lakefile.toml]

To add a dependency, we define a structure that matches the `[[require]]` format, decode the existing list, and then push our new entry.

```lean
structure Dependency where
  name : String
  git  : String
  rev  : String
deriving Inhabited, Repr

instance : DecodeToml Dependency where
  decode v := do
    let tbl ← v.decodeTable
    return { 
      name := ← tbl.decode `name, 
      git  := ← tbl.decode `git,
      rev  := ← tbl.decode `rev 
    }

instance : ToToml Dependency where
  toToml d := Value.table .missing <| Table.empty
    |> Table.insert `name d.name
    |> Table.insert `git  d.git
    |> Table.insert `rev  d.rev

def addDependency (path : System.FilePath) 
  (dep : Dependency) : CoreM Unit := do
  let content ← IO.FS.readFile path
  let table ← parseToml content
  
  -- 1. Extract the existing array
  let reqVal : Value := getTomlValue table "require"
  let result : EStateM.Result Unit (Array DecodeError) 
    (Array Dependency) := decodeToml reqVal #[]
    
  let deps := match result with
    | .ok d _ => d
    | .error .. => #[]
    

  let updatedDeps := deps.push dep
  let updatedTable := 
    updateValue table "require" updatedDeps

  IO.FS.writeFile path (ppTable updatedTable)

/-
#eval addDependency "lakefile.toml" { 
  name := "mathlib", 
  git := "https://github.com/leanprover-community/mathlib4",
  rev := "v4.11.0" 
}
-/
```
