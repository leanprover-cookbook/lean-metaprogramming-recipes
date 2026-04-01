import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Creating JSON Objects" =>

%%%
tag := "creating-json-objects"
number := false
%%%

::: contributors
:::

{index}[Handling Json Object]


In Lean, the {name}`Lean.Json` type is an inductive type that represents the different types of values that can be in a JSON structure. You can find its definition in `import Lean.Data.Json`:

# Creating JSON objects

There are three main ways to create JSON objects in Lean.

## 1. Using the `json%` macro

The most convenient way to create literal JSON values is with the `json%` macro. It allows you to write JSON syntax directly in your Lean code.

```lean
def myJson : Json := json% {
  "name": "Bob",
  "age": 42,
  "isActive": true,
  "scores": [1, 2, 3]
}
```

## 2. Using `Json.mkObj`

You can manually build a JSON object using `Json.mkObj` which takes a list of key-value pairs (as `String × Json`).

```lean
def manualJson : Json := Json.mkObj [
  ("name", "Bob"),
  ("age", 9)
]
```

## 3. Using custom structures with `Deriving ToJson`

The most idiomatic way to handle JSON in Lean is by defining a structure and deriving a {lean}`Lean.ToJson` instance. This allows you to convert Lean objects directly to JSON using the `toJson` function.

```lean
structure User where
  name : String
  age  : Nat
  isAdmin : Bool
deriving ToJson, FromJson

def userJson (user : User) : Json := toJson user

#eval userJson { name := "Bob", age := 7, isAdmin := false }
```
