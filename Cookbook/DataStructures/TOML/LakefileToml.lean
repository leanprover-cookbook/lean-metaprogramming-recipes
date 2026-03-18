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

Lean 4 uses `lakefile.toml` for package configuration. While you usually edit this file manually, you might want to read or update it programmatically using `Lake.Toml`.

# Parsing a lakefile.toml

A typical `lakefile.toml` contains a `[[lean_lib]]` or `[[lean_exe]]` section and a `[package]` section. We can define structures that match these and use the tools we've learned to parse them.

```lean
structure PackageConfig where
  name : String
  version : Option String := none
deriving Inhabited, Repr

instance : DecodeToml PackageConfig where
  decode v := do
    let tbl ← v.decodeTable
    let name ← tbl.decode `name
    let version ← tbl.decode? `version
    return { name, version }

def readPackageName (input : String) : CoreM String := do
  let table ← parseToml input
  -- Access the [package] section
  let pkgVal := getTomlValue table "package"
  let res : EStateM.Result Unit (Array DecodeError) PackageConfig := 
    decodeToml pkgVal #[]
  match res with
  | .ok cfg _ => return cfg.name
  | .error _ errs => 
    throwError s!"Decode error: {errs.toList.map (·.msg)}"

#eval readPackageName "[package]\nname = \"my_project\""
```

# Updating Dependencies in lakefile.toml

If you want to add a dependency to your `lakefile.toml`, you can manipulate the `[[require]]` array of tables.

```lean
structure Dependency where
  name : String
  scope : String := ""
deriving Inhabited, Repr

instance : DecodeToml Dependency where
  decode v := do
    let tbl ← v.decodeTable
    let name ← tbl.decode `name
    let scope ← tbl.decode? `scope
    return { name, scope := scope.getD "" }

instance : ToToml Dependency where
  toToml d := Value.table .missing <| Table.empty
    |> Table.insert `name d.name
    |> Table.insert `scope d.scope

def addDependency (input : String) (dep : Dependency) : CoreM String := do
  let table ← parseToml input
  
  -- 1. Get existing dependencies or start with empty array
  let result : EStateM.Result Unit (Array DecodeError) (Array Dependency) := 
    (table.decode `require).run #[]
  let deps := match result with
    | .ok d _ => d
    | .error .. => #[]
    
  -- 2. Add the new dependency
  let updatedDeps := deps.push dep
  
  -- 3. Update the table and pretty-print
  let updatedTable := updateValue table "require" updatedDeps
  return ppTable updatedTable

#eval addDependency "[package]\nname = \"my_project\"" 
  { name := "mathlib", scope := "leanprover-community" }
```
