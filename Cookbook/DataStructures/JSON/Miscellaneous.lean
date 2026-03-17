import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Miscellaneous JSON" =>

::: contributors
:::

# Miscellaneous JSON Operations

%%%
tag := "misc-json-operations"
number := false
%%%

While deriving instances is convenient, real-world JSON often
requires manual control over serialization, default values,
and transformations.

## 1. Field Renaming (Manual Instances)

%%%
tag := "json-field-renaming"
number := false
%%%

{index}[Json Field Renaming]

If your JSON uses `snake_case` but your Lean code uses `camelCase`,
you can manually implement {name}`ToJson` and {name}`FromJson` instances.

The {name}`instance` keyword in Lean is used to provide an implementation for a *type class*. In this case, {name}`ToJson` and {name}`FromJson` are type classes that define how a type should be converted to and from {lean}`Json`. By defining these instances manually, you gain full control over the mapping process, allowing you to bridge the gap between different naming conventions or data structures.

```lean
structure Person where
  firstName : String
  lastName  : String
deriving Repr

instance : ToJson Person where
  toJson p := json% {
    "first_name": $(p.firstName),
    "last_name": $(p.lastName)
  }

instance : FromJson Person where
  fromJson? j := do
    let first ← j.getObjValAs? String "first_name"
    let last  ← j.getObjValAs? String "last_name"
    return { firstName := first, lastName := last }

#eval toJson 
  ({ firstName := "Ada", lastName := "Lovelace" : Person })
#eval (fromJson? (json% { "first_name": "Ada", 
    "last_name": "Lovelace" }) : Except String Person)
```

## 2. Handling Default Values

%%%
tag := "json-default-values"
number := false
%%%

{index}[Json Handling Default Values]

You can use {name}`Json.getObjValAs?` to provide a fallback value if a 
key is missing or not of the expected type.

```lean
def getPort (j : Json) (defaultPort : Nat := 8080) : Nat :=
  match j.getObjValAs? Nat "port" with
  | .ok n => n
  | .error _ => defaultPort

#eval getPort (json% { "host": "localhost", "port": 3000 })
#eval getPort (json% { "host": "localhost" })
```

