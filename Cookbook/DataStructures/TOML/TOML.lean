import VersoManual
import Cookbook.Lean
import Lake.Toml

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean
open Lake Toml Lean Parser

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Parsing TOML" =>

%%%
tag := "parsing-toml"
number := false
%%%

::: contributors
:::

{index}[Parsing TOML]


To parse a TOML string, you first use the TOML parser to get 
a {lean}`Syntax` object, and then elaborate that syntax into 
a {name}`Lake.Toml.Table`. We have provided a general purpose TOML parser
function that you can use in your own code. It takes a TOML string as input and returns a `Table` or throws an error if parsing fails.

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

def egTomlParse : CoreM String := do
  let input := "name = \"Cookbook\"\nversion = \"1.0.0\""
  let table ← parseToml input
  return s!"Parsed table with {table.values} entries."

#eval egTomlParse
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

def testDecode : CoreM String := do
  -- Standard multi-line TOML
  let input := "name = \"Lean4\"\nversion = \"4.15.0\"\nactive = true"
  let table ← parseToml input
  let val := Value.table .missing table
  let res : EStateM.Result Unit (Array DecodeError) ProjectConfig := 
    decodeToml val #[]
  match res with
  | .ok config _ => 
    return s!"Project: {config.name}, Version: {config.version}"
  | .error _ errs => 
    let msgs := errs.toList.map (fun (e : DecodeError) => e.msg)
    throwError s!"Decode error: {msgs}"

#eval testDecode
```

The above {name}`parseToml` can also parse multi-nested TOML files like the following:


# Nested TOML and Arrays of Tables

%%%
tag := "nested-toml"
number := false
%%%

{index}[Nested TOML]
{index}[TOML Arrays of Tables]

TOML supports nested tables using the `[table.subtable]` syntax and 
arrays of tables using `[[array]]`. You can handle these by 
nesting your `DecodeToml` and `ToToml` instances.

```lean
structure Endpoint where
  host : String
  port : Nat
deriving Inhabited, Repr

instance : DecodeToml Endpoint where
  decode v := do
    let tbl ← v.decodeTable
    return { host := ← tbl.decode `host, port := ← tbl.decode `port }

instance : ToToml Endpoint where
  toToml e := Value.table .missing <| Table.empty
    |> Table.insert `host e.host
    |> Table.insert `port e.port

structure ServerConfig where
  name      : String
  endpoints : Array Endpoint
deriving Inhabited, Repr

instance : DecodeToml ServerConfig where
  decode v := do
    let tbl ← v.decodeTable
    return { 
      name := ← tbl.decode `name, 
      endpoints := ← tbl.decode `endpoints 
    }

def testNested : CoreM String := do
  let input := "
name = \"Production\"

[[endpoints]]
host = \"api1.example.com\"
port = 80

[[endpoints]]
host = \"api2.example.com\"
port = 8080
"
  let table ← parseToml input
  let res : EStateM.Result Unit (Array DecodeError) ServerConfig := 
    decodeToml (Value.table .missing table) #[]
  match res with
  | .ok cfg _ => return s!"Server {cfg.name} has {cfg.endpoints.size} endpoints."
  | .error _ e => throwError s!"Error: {e.toList.map (·.msg)}"

#eval testNested
```

# Encoding and Modifying TOML

%%%
tag := "encoding-toml"
number := false
%%%

{index}[Encoding TOML]

You can convert Lean structures back to TOML by implementing 
the {name}`Lake.ToToml` class. 

Note that {name}`Value.toString` produces an **inline table** 
(e.g., `{a = 1, b = 2}`), which is valid TOML but often not 
preferred for whole files. To produce the standard multi-line 
format, use {name}`Lake.Toml.ppTable` on the underlying table.

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
    { name := "Metaprogramming", version := "0.1.0", active := true }
  let val := toToml cfg
  if let .table _ tbl := val then
    return ppTable tbl
  else
    return toString val

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
  let val := toToml cfg
  let content := if let .table _ tbl := val then ppTable tbl else toString val
  IO.FS.writeFile path content
```
