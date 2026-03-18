import VersoManual
import Cookbook.Lean
import Lake.Toml

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean
open Lake Toml Lean Parser

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "TOML" =>

%%%
tag := "toml"
number := false
%%%

::: contributors
:::

TOML is a popular configuration format, used by Lean 4's build tool, Lake. Lean 4 provides a built-in TOML parser and encoder within the `Lake.Toml` module.

# Parsing TOML

%%%
tag := "parsing-toml"
number := false
%%%

{index}[Parsing TOML]

To parse a TOML string, you first use the TOML parser to get 
a {lean}`Syntax` object, and then elaborate that syntax into 
a {name}`Lake.Toml.Table`.

```lean
def parseToml (input : String) : CoreM Table := do
  let env ← getEnv
  let ictx := mkInputContext input "<string>"
  let pctx := { env, options := {} }
  let s := toml.fn.run ictx pctx {} 
    (mkParserState ictx.inputString)
  if let some err := s.errorMsg then
    throwError s!"Parse error: {err}"
  else
    elabToml ⟨s.stxStack.back⟩

def testParse : CoreM String := do
  let input := "name = \"Cookbook\"\nversion = \"1.0.0\""
  let table ← parseToml input
  return s!"Parsed table with {table.size} entries."

#eval testParse
```

# Decoding TOML into Lean Structures

%%%
tag := "decoding-toml"
number := false
%%%

{index}[Decoding TOML]

The {name}`Lake.DecodeToml` class allows you to automatically 
transform a TOML table into a Lean structure.

```lean
structure ProjectConfig where
  name    : String
  version : String
  active  : Bool := true
deriving Inhabited, Repr

instance : DecodeToml ProjectConfig where
  decode v := do
    let tbl ← v.decodeTable
    let name ← tbl.decode `name
    let version ← tbl.decode `version
    let active ← tbl.decode? `active
    return { name, version, active := active.getD true }

def tomlProjectDecode (input : String) : CoreM String := do
  let table ← parseToml input
  -- Convert the Table back to a Value for decoding
  let val := Value.table .missing table
  let res : EStateM.Result Unit (Array DecodeError) 
    ProjectConfig := decodeToml val #[]
  match res with
  | .ok config _ => 
    return s!"Project: {config.name}, Version: {config.version}"
  | .error _ errs => 
    let msgs := errs.toList.map (fun (e : DecodeError) => e.msg)
    throwError s!"Decode error: {msgs}"

#eval tomlProjectDecode "name = \"Lean4\"\nversion = \"4.15.0\""
```

# Encoding and Modifying TOML

%%%
tag := "encoding-toml"
number := false
%%%

{index}[Encoding TOML]

You can convert Lean structures back to TOML by implementing 
the {name}`Lake.ToToml` class. To "modify" a TOML file, you 
typically decode it, update the Lean structure, and re-encode it.

```lean
instance : ToToml ProjectConfig where
  toToml c :=
    let tbl := Table.empty
      |> Table.insert `name c.name
      |> Table.insert `version c.version
      |> Table.insert `active c.active
    Value.table .missing tbl

def testEncode : CoreM String := do
  let cfg : ProjectConfig := 
    { name := "Metaprogramming", version := "0.1.0" }
  return toString (toToml cfg)

#eval testEncode
```

# Reading and Writing TOML Files

%%%
tag := "reading-writing-toml"
number := false
%%%

{index}[Reading TOML files]
{index}[Writing TOML files]

You can combine `IO.FS` with the parser and encoder to 
work with files on disk.

```lean
def loadConfig (path : System.FilePath) : CoreM ProjectConfig := do
  let content ← IO.FS.readFile path
  let table ← parseToml content
  let val := Value.table .missing table
  let res : EStateM.Result Unit (Array DecodeError) ProjectConfig := 
    decodeToml val #[]
  match res with
  | .ok cfg _ => return cfg
  | .error _ errs => 
    let msgs := errs.toList.map (fun (e : DecodeError) => e.msg)
    throwError s!"Failed to decode: {msgs}"

def saveConfig (path : System.FilePath) (cfg : ProjectConfig) : IO Unit := do
  IO.FS.writeFile path (toString (toToml cfg))

#eval do
  let cfg : ProjectConfig := 
    { name := "Verso Manual", version := "0.1.0" }
  saveConfig "config.toml" cfg
```
