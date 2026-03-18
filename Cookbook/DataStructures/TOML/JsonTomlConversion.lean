import VersoManual
import Cookbook.Lean
import Lake.Toml
import Cookbook.DataStructures.TOML.ParsingToml

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean
open Lake Toml Lean Parser

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "JSON and TOML Conversion" =>

%%%
tag := "json-toml-conversion"
number := false
%%%

::: contributors
:::

# Converting TOML to JSON

%%%
tag := "toml-to-json"
number := false
%%%

{index}[Converting TOML to JSON]

It is often useful to convert TOML data into JSON format for interoperability with other systems. Below is an example of how you can convert your own TOML {lean}`Value` into a {lean}`Json` object by recursively mapping the TOML structure to {lean}`Json`. 

```lean
open Lake Toml Lean

/-- Recursive conversion from TOML Value to Json -/
partial def tomlToJson : Value → Json
  | .string _ s    => toJson s
  | .integer _ i   => toJson i
  | .float _ f     => toJson f
  | .boolean _ b   => toJson b
  | .dateTime _ d  => toJson (toString d)
  | .array _ arr   => toJson (arr.map tomlToJson)
  | .table' _ tbl  =>
      let pairs := tbl.items.toList.map fun (k, v) =>
        (k.toString, tomlToJson v)
      Json.mkObj pairs

def egTomlToJson : CoreM Json := do
  let input := "
[database]
server = \"192.168.1.1\"
ports = [ 8000, 8001, 8002 ]
"
  let table ← parseToml input
  return tomlToJson (Value.table .missing table)

#eval egTomlToJson
```

# Converting JSON to TOML

%%%
tag := "json-to-toml"
number := false
%%%

{index}[Converting JSON to TOML]

Converting JSON back to TOML involves mapping JSON types to their corresponding TOML constructors. Since JSON numbers are represented as {lean}`JsonNumber`, we attempt to convert them to integers or floats.

```lean
open Lake Toml Lean

/-- Recursive conversion from Json to TOML Value -/
partial def jsonToToml : Json → Value
  | .null       => .string .missing "null"
  | .bool b     => .boolean .missing b
  | .num n      => 
      -- Check if it is a simple integer (exponent 0)
      if n.exponent == 0 then 
        .integer .missing n.mantissa
      else 
        .float .missing n.toFloat
  | .str s      => .string .missing s
  | .arr a      => .array .missing (a.map jsonToToml)
  | .obj o      => 
      let tbl := o.toList.foldl (fun t (k, v) => 
        Table.insert k.toName (jsonToToml v) t) Table.empty
      .table .missing tbl

def egJsonToToml : CoreM String := do
  let j := json% {
    "project": "Lean4",
    "meta": { "active": true, "version": 4 }
  }
  let val := jsonToToml j
  if let .table _ tbl := val then
    return ppTable tbl
  else
    return toString val

#eval egJsonToToml
```
