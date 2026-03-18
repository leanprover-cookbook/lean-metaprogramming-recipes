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
