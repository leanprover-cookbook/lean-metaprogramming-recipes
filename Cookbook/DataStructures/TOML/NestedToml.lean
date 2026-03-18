import VersoManual
import Cookbook.Lean
import Lake.Toml
import Cookbook.DataStructures.TOML.ParsingToml
import Cookbook.DataStructures.TOML.EncodingDecodingToml

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean
open Lake Toml Lean Parser

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Nested TOML & Arrays of Tables" =>

%%%
tag := "nested-toml"
number := false
%%%

{index}[Nested TOML]
{index}[TOML Arrays of Tables]

::: contributors
:::

TOML supports nested structures through tables (sections like `[server]`) and arrays of tables (indicated by `[[endpoints]]`). These are handled by nesting {name}`DecodeToml` and {name}`ToToml` instances.

In `Lake.Toml`, you may see both {name}`Value.table` and {name}`Value.table'`. They are almost identical:
*   *`Value.table'`*: The raw constructor for the {name}`Lake.Toml.Value` inductive type.
*   *`Value.table`*: A shorthand for `table'` that is often used for clarity. 

Both take two arguments: a {name}`Lean.Syntax` (usually `.missing` for manual creation) and a {name}`Lake.Toml.Table`.

# Defining Nested Structures

First, we define our Lean structures and provide the logic to convert them to and from TOML.

```lean
structure Endpoint where
  host : String
  port : Nat
deriving Inhabited, Repr

instance : DecodeToml Endpoint where
  decode v := do
    let tbl ← v.decodeTable
    return { 
      host := ← tbl.decode `host, 
      port := ← tbl.decode `port 
    }

instance : ToToml Endpoint where
  toToml e := Value.table' .missing <| Table.empty
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

instance : ToToml ServerConfig where
  toToml c := Value.table' .missing <| Table.empty
    |> Table.insert `name c.name
    |> Table.insert `endpoints c.endpoints
```

# Encoding (Representing as TOML)

To see what the nested structure looks like in TOML format, we use {name}`Lake.Toml.ppTable`.

```lean
def egEncodeNested : CoreM String := do
  let config : ServerConfig := {
    name := "Production",
    endpoints := #[
      { host := "api1.io", port := 80 },
      { host := "api2.io", port := 8080 }
    ]
  }
  let val := toToml config
  if let .table' _ tbl := val then
    return ppTable tbl
  else
    return toString val

#eval egEncodeNested
```

# Decoding (Reading and Accessing)

When reading, we use {name}`decodeToml` to transform the entire table back into our {name}`ServerConfig` structure.

```lean
def egDecodeNested : CoreM String := do
  let input := "
name = \"Staging\"

[[endpoints]]
host = \"localhost\"
port = 3000
"
  let table ← parseToml input
  let val := Value.table' .missing table
  
  -- 1. Use decodeToml for the whole structure
  let result : EStateM.Result Unit (Array DecodeError) ServerConfig := 
    decodeToml val #[]
  match result with
  | .ok cfg _ => 
    return s!"Config '{cfg.name}' has {cfg.endpoints.size} endpoints."
  | .error _ e => 
    let msgs := e.toList.map (fun (err : DecodeError) => err.msg)
    throwError s!"Error: {msgs}"

#eval egDecodeNested
```

# Modifying Nested TOML

To modify a nested structure, you can either update the Lean object and re-encode it, or use helper functions like {name}`getTomlValue` and {name}`updateValue` to manipulate the {name}`Table` directly.

```lean
def egModifyNested : CoreM String := do
  let input := "name = \"Dev\"\nendpoints = []"
  let table ← parseToml input

  -- 1. Retrieve the existing array of endpoints
  -- We use getTomlValue for a type-safe retrieval
  let endpoints : Array Endpoint ← match (getTomlValue table "endpoints" : Except String (Array Endpoint)) with
    | .ok v => pure v
    | .error _ => pure #[]

  -- 2. Add a new endpoint to the array
  let newEndpoint : Endpoint := { host := "127.0.0.1", port := 5000 }
  let updatedEndpoints := endpoints.push newEndpoint
    
  -- 3. Update the 'endpoints' key in the table
  let updatedTable := updateValue table "endpoints" updatedEndpoints
  
  -- 4. Rename the server using updateValue
  let finalTable := updateValue updatedTable "name" "Dev-Local"
  
  -- 5. Format the result back to TOML
  return ppTable finalTable

#eval egModifyNested
```
