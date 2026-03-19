import VersoManual
import Cookbook.Lean
import Lake.Toml

import Lean.Data.Json
import Lake.Toml

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean
open Lean Elab Meta Lake Toml Lean Parser Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Parsing TOML" =>

%%%
tag := "parsing-toml"
number := false
%%%

::: contributors
:::

{index}[Parsing TOML]

To parse a TOML string, you first use the TOML parser to get  a {lean}`Syntax` object, and then elaborate that syntax into a {name}`Lake.Toml.Table`. A general purpose TOML parser function example that you can use in your own code is given below. It takes a TOML string as input and returns a {name}`Table` or throws an error if parsing fails.

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

The above {name}`parseToml` you can use for nested TOML structures as well. You can use {name}`ppTable` to pretty-print the parsed {name}`Table` back into a TOML string, like below:

```lean
def egNestedParse : CoreM String := do
  let input := "
[database]
server = \"192.168.1.1\"
ports = [ 8000, 8001, 8002 ]

[[users]]
name = \"Alice\"
role = \"admin\"

[[users]]
name = \"Bob\"
role = \"user\"
"
  -- parseToml handles all the nesting for you
  let table ← parseToml input
  return ppTable table

#eval egNestedParse
```

More about Nested TOML handling in {ref "handling-nested-toml"}[Handling Nested TOML] section.

