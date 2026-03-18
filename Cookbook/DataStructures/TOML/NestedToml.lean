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

# Defining Nested Structures

First, we define our Lean structures and provide the logic to convert them to and from TOML.

```lean
structure Address where
  host : String
  port : Nat
deriving Inhabited, Repr

instance : DecodeToml Address where
  decode v := do
    let tbl ← v.decodeTable
    return { 
      host := ← tbl.decode `host, 
      port := ← tbl.decode `port 
    }

instance : ToToml Address where
  toToml e := Value.table' .missing <| Table.empty
    |> Table.insert `host e.host
    |> Table.insert `port e.port

structure ServiceConfig where
  name      : String
  addresses : Array Address
deriving Inhabited, Repr

instance : DecodeToml ServiceConfig where
  decode v := do
    let tbl ← v.decodeTable
    return { 
      name := ← tbl.decode `name, 
      addresses := ← tbl.decode `addresses 
    }

instance : ToToml ServiceConfig where
  toToml c := Value.table' .missing <| Table.empty
    |> Table.insert `name c.name
    |> Table.insert `addresses c.addresses
```

# Encoding (Representing as TOML)

To see what the nested structure looks like in TOML format, we use {name}`Lake.Toml.ppTable`.

```lean
def egEncodeNested : CoreM String := do
  let config : ServiceConfig := {
    name := "Production",
    addresses := #[
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

When reading, we use {name}`decodeToml` to transform the entire table back into our {name}`ServiceConfig` structure.

```lean
def egDecodeNested : CoreM String := do
  let input := "
name = \"Staging\"

[[addresses]]
host = \"localhost\"
port = 3000
"
  let table ← parseToml input
  let val := Value.table' .missing table
  
  -- 1. Use decodeToml for the whole structure
  let result : EStateM.Result Unit (Array DecodeError) ServiceConfig := 
    decodeToml val #[]
  match result with
  | .ok cfg _ => 
    return s!"Config '{cfg.name}' has {cfg.addresses.size} addresses."
  | .error _ e => 
    let msgs := e.toList.map (fun (err : DecodeError) => err.msg)
    throwError s!"Error: {msgs}"

#eval egDecodeNested
```

# Modifying Nested TOML

To modify a nested structure, you can either update the Lean object and re-encode it, or use helper functions like {name}`decodeTomlValue` and {name}`updateValue` to manipulate the {name}`Table` directly.

```lean
def egModifyNested : CoreM String := do
  let input := "name = \"Dev\"\naddresses = []"
  let table ← parseToml input

  -- 1. Retrieve the existing array of addresses
  -- We use decodeTomlValue for a type-safe retrieval
  let addresses : Array Address ← match (decodeTomlValue table "addresses" : Except String (Array Address)) with
    | .ok v => pure v
    | .error _ => pure #[]

  -- 2. Add a new address to the array
  let newAddress : Address := { host := "127.0.0.1", port := 5000 }
  let updatedAddresses := addresses.push newAddress
    
  -- 3. Update the 'addresses' key in the table
  let updatedTable := updateValue table "addresses" updatedAddresses
  
  -- 4. Rename the service using updateValue
  let finalTable := updateValue updatedTable "name" "Dev-Local"
  
  -- 5. Format the result back to TOML
  return ppTable finalTable

#eval egModifyNested
```
