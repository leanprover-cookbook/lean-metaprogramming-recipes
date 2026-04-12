import VersoManual
import Cookbook.Lean
import Lake.Toml
import Cookbook.DataStructures.TOML.HandlingNestedToml

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean
open Lake Toml Lean Parser

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Reading and Writing TOML Files" =>

%%%
tag := "reading-writing-toml"
number := false
%%%

{index}[Reading TOML files]
{index}[Writing TOML files]

::: contributors
:::

Working with files involves reading strings from disk and passing them to our parser, or taking a {name}`Table` and pretty-printing it back to a file. We will use the {name}`ServiceConfig` structure defined in the previous section.

# Reading TOML Files

To read a TOML file, we read the file content as a string, parse it into a {name}`Table`, and then decode that table into a Lean structure.

```lean
def loadTomlConfig (path : System.FilePath) : 
    CoreM ServiceConfig := do
  let content ← IO.FS.readFile path
  let table ← parseToml content

  let val := Value.table' .missing table
  let result : EStateM.Result Unit (Array DecodeError)
    ServiceConfig := decodeToml val #[]

  match result with
  | .ok cfg _ => return cfg
  | .error _ errs => 
    let msgs := errs.toList.map 
      (fun (e : DecodeError) => e.msg)
    throwError s!"Failed to decode {path}: {msgs}"
```

# Writing TOML Files

To write TOML, we convert our Lean structure into a {name}`Value` using `toToml`, extract the underlying {name}`Table`, and then use `ppTable` to format it as a standard multi-line TOML string.

```lean
def saveTomlConfig (path : System.FilePath) 
  (cfg : ServiceConfig) : IO Unit := do
  let val := toToml cfg
  
  let content := match val with
    | .table' _ tbl => ppTable tbl
    | _ => toString val -- Fallback to inline format

  IO.FS.writeFile path content
```

## Example: Nested Round-trip

```lean
def egRoundTrip : CoreM String := do
  let path : System.FilePath := "service_config.toml"
  let config : ServiceConfig := {
    name := "Production",
    addresses := #[{ host := "127.0.0.1", port := 80 }]
  }
  
  -- Save it
  saveTomlConfig path config
  
  -- Load it back, just for demonstration
  let loaded ← loadTomlConfig path
  return s!"Loaded config for: {loaded.name}"

-- #eval egRoundTrip
```
