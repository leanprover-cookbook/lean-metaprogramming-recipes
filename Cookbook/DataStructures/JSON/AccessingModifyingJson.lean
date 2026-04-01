import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Accessing and Modifying JSON" =>

::: contributors
:::

# Reading values from JSON

%%%
tag := "accessing-json"
number := false
%%%

{index}[Reading values from JSON]

To read values from a {lean}`Json` object, you can use specialized helper functions like {lean}`Json.getObjValAs?` which attempt to retrieve and convert a value to a specific Lean type.

```lean
def getAge (j : Json) : Except String Nat :=
  j.getObjValAs? Nat "age"

#eval getAge (json% { "name": "Alice", "age": 30 })

def getJsonValue (j : Json) (key : String) : Json :=
  let val := j.getObjVal? key
  match val with
  | .ok v => v
  | .error err => panic! s!"Key '{key}' not found: {err}"

#eval getJsonValue (json% { "name": "Bob", "age": 7 }) "age"
```

To get all the keys in a {lean}`Json` object, you can simply match on the {lean}`Json.obj` constructor:

```lean
def getSortedKeys (j : Json) : List String :=
  match j with
  | .obj m => m.toList.map (·.1) |>.mergeSort
  | _ => []

#eval getSortedKeys (json% { apple: 1, "b": 2, cats: 3 })
```

For more complex structures, you can use the {name}`fromJson?` class to decode the entire object at once:

```lean
structure JsonUser where
  name : String
  age  : Nat
  isAdmin : Bool
deriving FromJson, ToJson, Inhabited

def getUserName (j : Json) : String :=
  match (fromJson? j : Except String JsonUser) with
  | .ok user => user.name
  | .error err => panic! s!"Failed to decode User: {err}"

#eval getUserName (json% { "name": "Charlie", 
  "age": 25, "isAdmin": false })
```

# Modifying JSON Objects

%%%
tag := "modifying-json"
number := false
%%%

{index}[Modifying JSON objects]

Since {lean}`Json` is an immutable inductive type, "modifying" it involves creating a new {lean}`Json` value based on the old one.

## 1. Direct Object Manipulation

If you know a {lean}`Json` value is an object, you can pattern match on {lean}`Json.obj` to access the underlying `RBMap`. You can then use methods like `insert` or `erase` and wrap the result back in {lean}`Json.obj`.

```lean
/-- Update or add the 'isAdmin' field -/
def setAdminStatus (j : Json) (status : Bool) : Json :=
  match j with
  | Json.obj kv => Json.obj 
      (kv.insert "isAdmin" (toJson status))
  | _ => j

#eval setAdminStatus (json% { "name": "Bob", 
    "isAdmin": false }) true
#eval setAdminStatus (json% { "name": "Charlie"}) true

/-- Remove the 'age' field if it exists -/
def stripAge (j : Json) : Json :=
  match j with
  | Json.obj kv => Json.obj (kv.erase "age")
  | _ => j

#eval stripAge (json% { "name": "Bob", "age": 42 })
```

## 2. The Decode-Modify-Encode Pattern

For complex modifications, especially those involving nested data or collections, the most robust approach is to decode the JSON into a Lean structure, perform the update using Lean's powerful functional tools, and then re-encode it.

```lean
structure Endpoint where
  host : String
  port : Nat
deriving FromJson, ToJson

structure ServerConfig where
  name      : String
  endpoints : List Endpoint
  active    : Bool
  location  : Option String
deriving FromJson, ToJson

/-- Update the port for a specific host 
  and toggle the active status -/
def updateConfig (config : ServerConfig) 
    (targetHost : String) (newPort : Nat) : ServerConfig :=
  let updatedEndpoints := config.endpoints.map fun e =>
    if e.host == targetHost then 
      { e with port := newPort } else e
  { config with endpoints := updatedEndpoints, active 
    := !config.active }

def serverUpdate (j : Json) (target : String)
    (port : Nat) : Except String Json := do
  let config : ServerConfig ← fromJson? j
  return toJson (updateConfig config target port)

/- Example: Updating 'localhost' to port 8080 
  and toggling active to false -/
#eval serverUpdate (json% {
  "name": "DevServer",
  "active": true,
  "endpoints": [
    { "host": "localhost", "port": 3000 },
    { "host": "api.example.com", "port": 443 }
  ]
}) "localhost" 8080
```
