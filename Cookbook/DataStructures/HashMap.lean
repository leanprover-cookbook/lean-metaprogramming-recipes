import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command
open Std (HashMap)

set_option pp.rawOnError true

#doc (Manual) "HashMap" =>

%%%
tag := "hashmap"
number := false
htmlSplit := .never
%%%

::: contributors
:::

{lean}`HashMap` is a collection of key-value pairs that provides efficient lookup, insertion, and deletion. In Lean 4, the most commonly used implementation is {name}`Std.HashMap`.

# Basic Operations

{index}[HashMap Basic Operations]

To use {name}`HashMap`, you usually need to provide types for keys and values. The key type must have {name}`Hashable` and {name}`BEq` instances.

```lean
-- Creating an empty HashMap
def myMap : HashMap String Nat := {}

-- Inserting values
def updatedMap := myMap.insert "apple" 1
def updatedMap2 := updatedMap.insert "banana" 2

-- Accessing values (returns Option)
#eval updatedMap2.get? "apple" 
#eval updatedMap2.get? "cherry"

-- Checking for existence
#eval updatedMap2.contains "apple"

-- Removing values
def erasedMap := updatedMap2.erase "apple"
#eval erasedMap.contains "apple"

-- Updating values using 'alter'
/-- Increment the value for a key, or initialize it to 1 -/
def increment (map : HashMap String Nat) (key : String)
  : HashMap String Nat :=
  map.alter key fun
    | some n => some (n + 1)
    | none   => some 1

#eval (increment updatedMap2 "apple").get? "apple"
```

# Memoization with StateM

%%%
tag := "memoization-hashmap"
number := false
%%%

{index}[Memoization using HashMap]

Memoization is a technique used to speed up computer programs by storing the results of expensive function calls and returning the cached result when the same inputs occur again. A {name}`HashMap` combined with a {name}`StateM` monad is a powerful way to implement this in Lean. {name}`StateM` allows us to carry the state of our cache (here {name}`HashMap`) through our computations.

Below is an example of the Fibonacci sequence implemented with memoization.

```lean
/--
  Recursive Fibonacci with memoization.
  We use StateM Memo to carry the cache.
-/
abbrev FibState := HashMap Nat Nat
abbrev FibM := StateM FibState

def fib (n: Nat) : FibM Nat := do
  match n with
  | 0 => return 1
  | 1 => return 1
  | k + 2 => do
    let m ← get
    match m.get? n with -- check if we calculated it before
    | some v => return v
    | none => do
      let v1 ← fib k -- calculate at k and update the state
      let v2 ← fib (k + 1)
      let v := v1 + v2
      modify (fun m => m.insert n v)
      return v

/-
- `run` -> calculates given an initial state and 
  returns the result and the final state
- `run'` -> given an initial state returns the result
-/
#eval fib 350 |>.run' {}
#eval fib 50 |>.run {}
```

Using memoization allows us to compute `fib 350` almost instantly, whereas a naive recursive implementation would take a very long time.

# Application: Advanced Expression Analysis

%%%
tag := "frequency-hashmap-advanced"
number := false
%%%

{index}[Advanced HashMap Operations]

In metaprogramming, you might want to perform a multi-layered analysis of an expression. Below is an example that:
1.  Counts how many times each *constant* appears.
2.  Records the minimum *depth* at which each constant first appeared .
3.  Demonstrates *merging* two frequency maps.
4.  Shows how to *filter* a map to keep only specific entries.

```lean
structure ConstInfo where
  count : Nat
  firstDepth : Nat
deriving Repr, Inhabited

instance : ToString ConstInfo where
  toString info := s!"Count: {info.count}, 
    First Depth: {info.firstDepth}"

/-- 
  An analyzer that tracks both count 
  and the depth of the first occurrence.
  Using MetaM allows us to use 'logInfo' for debugging.
-/
def analyzeExpr (e : Expr) (depth : Nat := 0) 
    (emap : HashMap Name ConstInfo := {}) :
    MetaM (HashMap Name ConstInfo) := do
  match e with
  -- for constants
  | .const name _ =>
      -- Simple debug print to the Infoview
      logInfo m!"Found constant: {name} at depth {depth}"
      return emap.alter name fun
        | some info => 
            some { info with count := info.count + 1 }
        | none      => 
            some { count := 1, firstDepth := depth }
  -- for applications like `f a`
  | .app f a => 
      let emap' ← analyzeExpr f depth emap
      analyzeExpr a depth emap'
  -- for lambda and forall
  | .lam _ _ b _ | .forallE _ _ b _ => 
      analyzeExpr b (depth + 1) emap
  | _ => return emap

/-- 
  We merge two HashMaps.
  If a constant exists in both, we sum the counts 
  and take the minimum depth.
-/
def mergeAnalysis (m1 m2 : HashMap Name ConstInfo) 
    : HashMap Name ConstInfo :=
  m2.fold (init := m1) fun acc name info2 =>
    acc.alter name fun
    | some info1 => some { 
        count := info1.count + info2.count, 
        firstDepth := min info1.firstDepth info2.firstDepth 
      }
    | none => some info2

def egExprCounter : MetaM Unit := do
  -- Using 'toExpr' elaborates numbers
  -- into 'OfNat.ofNat' calls
  let e1 ← mkEq (toExpr 1) (toExpr 1)
  let e2 ← mkEq (toExpr 2) (toExpr 3)

  let analysis1 ← analyzeExpr e1
  logInfo s!"Analysis of e1: 
    {analysis1.toList.map (fun (k, v) => (k, s!"{v}"))}"
  let analysis2 ← analyzeExpr e2
  logInfo s!"Analysis of e2: 
    {analysis2.toList.map (fun (k, v) => (k, s!"{v}"))}"

  -- Merge the results of two different expressions
  let combined := mergeAnalysis analysis1 analysis2
  logInfo s!"Analysis of combined: 
    {combined.toList.map (fun (k, v) => (k, s!"{v}"))}"

  -- filter the map to only include constants that 
  -- appeared more than once
  let frequent := combined.toList.filter (·.2.count > 1) 
    |> HashMap.ofList

  -- Map the values to just the counts for final display
  let finalCounts := frequent.toList.map 
    fun (k, v) => (k, v.count)

  IO.println s!"Frequent constants: {finalCounts}"

#eval egExprCounter
```


