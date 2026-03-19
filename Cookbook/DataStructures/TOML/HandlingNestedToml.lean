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
tag := "handling-nested-toml"
number := false
%%%

{index}[Handling Nested TOML]

::: contributors
:::

TOML supports nested structures through tables (sections like `[server]`) and arrays of tables (indicated by `[[endpoints]]`). These are handled by nesting {name}`DecodeToml` and {name}`ToToml` instances.

In `Lake.Toml`, you may see both {name}`Value.table` and {name}`Value.table'`. They are almost identical:
*   *`Value.table'`*: The raw constructor for the {name}`Lake.Toml.Value` inductive type.
*   *`Value.table`*: A shorthand for `table'` that is often used for clarity. 

Both take two arguments: a {name}`Lean.Syntax` (usually `.missing` for manual creation) and a {name}`Lake.Toml.Table`.

# Defining Nested Structures

%%%
tag := "defining-nested-toml"
number := false
%%%

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

%%%
tag := "encoding-nested-toml"
number := false
%%%

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

%%%
tag := "decoding-nested-toml"
number := false
%%%

{index}[Reading Nested TOML]

When reading, you can either decode the entire file at once or target a specific nested section.

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
  
  let result : EStateM.Result Unit (Array DecodeError) 
    ServiceConfig := decodeToml val #[]
  match result with
  | .ok cfg _ => return s!"Config '{cfg.name}' 
      has {cfg.addresses.size} addresses."
  | .error _ e => 
      throwError s!"Error: {e.toList.map (·.msg)}"

#eval egDecodeNested
```

If you only want one part of a complex TOML file, you can extract the raw {name}`Value` first and then decode just that part.

```lean
def egDecodeSection : CoreM String := do
  let input := "
[server]
name = \"Backend\"
[[addresses]]
host = \"127.0.0.1\"
port = 80
"
  let table ← parseToml input
  
  -- Extract the [server] section as a raw Value
  let serverVal : Value := getTomlValue table "server"
  
  -- Decode that Value into a specific structure
  let result : EStateM.Result Unit (Array DecodeError) 
    Address := decodeToml serverVal #[]
    
  match result with
  | .ok addr _ => return s!"Server host is {addr.host}"
  | .error _ e => 
      throwError s!"Error: {e.toList.map (·.msg)}"
```

# Modifying Nested TOML

%%%
tag := "modifying-nested-toml"
number := false
%%%

To modify a nested structure, you can either update the Lean object and re-encode it, or use helper functions like {name}`decodeTomlValue` and {name}`updateValue` to manipulate the {name}`Table` directly.

```lean
def egModifyNested : CoreM String := do
  let input := "name = \"Dev\"\naddresses = []"
  let table ← parseToml input

  -- Retrieve the existing array of addresses
  let addresses : Array Address ← 
    match (decodeTomlValue table "addresses" : 
    Except String (Array Address)) with
    | .ok v => pure v
    | .error _ => pure #[]

  -- Add a new address to the array
  let newAddress : Address := 
    { host := "127.0.0.1", port := 5000 }
  let updatedAddresses := addresses.push newAddress
    
  -- Update the table and pretty-print
  let finalTable := updateValue 
    (updateValue table "addresses" updatedAddresses) 
    "name" "Dev-Local"
  
  return ppTable finalTable

#eval egModifyNested
```
