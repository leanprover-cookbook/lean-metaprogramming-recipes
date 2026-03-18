import VersoManual
import Cookbook.Lean
import Lake.Toml
import Cookbook.DataStructures.TOML.NestedToml

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

Working with files involves reading strings from disk and passing them to our parser, or taking a {name}`Table` and pretty-printing it back to a file. We will use the {name}`ServerConfig` structure defined in the previous section.

# Reading TOML Files

To read a TOML file, we read the file content as a string, parse it into a {name}`Table`, and then decode that table into a Lean structure.

```lean
def loadConfig (path : System.FilePath) : CoreM ServerConfig := do
  -- 1. Read the raw string from the file
  let content ← IO.FS.readFile path
  
  -- 2. Parse the string into a Table
  let table ← parseToml content
  
  -- 3. Wrap in a Value and decode
  let val := Value.table' .missing table
  let result : EStateM.Result Unit (Array DecodeError) ServerConfig := 
    decodeToml val #[]
    
  match result with
  | .ok cfg _ => return cfg
  | .error _ errs => 
    let msgs := errs.toList.map (fun (e : DecodeError) => e.msg)
    throwError s!"Failed to decode {path}: {msgs}"
```

# Writing TOML Files

To write TOML, we convert our Lean structure into a {name}`Value` using `toToml`, extract the underlying {name}`Table`, and then use `ppTable` to format it as a standard multi-line TOML string.

```lean
def saveConfig (path : System.FilePath) (cfg : ServerConfig) : IO Unit := do
  -- 1. Convert Lean structure to a TOML Value
  let val := toToml cfg
  
  -- 2. Extract the Table and pretty-print it
  let content := match val with
    | .table' _ tbl => ppTable tbl
    | _ => toString val -- Fallback to inline format
    
  -- 3. Write the string to disk
  IO.FS.writeFile path content
```

## Example: Nested Round-trip

```lean
def egRoundTrip : CoreM String := do
  let path : System.FilePath := "server_config.toml"
  let config : ServerConfig := {
    name := "Production",
    endpoints := #[{ host := "127.0.0.1", port := 80 }]
  }
  
  -- Save it
  saveConfig path config
  
  -- Load it back
  let loaded ← loadConfig path
  return s!"Loaded config for: {loaded.name}"

#eval egRoundTrip
```
