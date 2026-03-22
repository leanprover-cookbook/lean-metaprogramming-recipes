import VersoManual
import Cookbook.Lean
import Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command
open Std (HashMap)

set_option pp.rawOnError true

#doc (Manual) "RBMap and RBTree" =>

%%%
tag := "rbmap-rbtree"
number := false
%%%

::: contributors
:::

{lean}`RBMap` and {lean}`RBTree` are red-black trees used extensively throughout the Lean 4 compiler. Unlike {lean}`HashMap`, which requires a {lean}`Hashable` instance, these structures only require an ordering instance ({lean}`Ord`).

# RBMap (Red-Black Map)

{index}[RBMap Operations]

{lean}`RBMap` is a persistent, ordered map. It is often preferred in pure functional code because it doesn't rely on the {lean}`IO` or {lean}`ST` monads for performance.

```lean
-- Defining an RBMap with Name keys and Nat values
#print RBMap
def myRBMap : RBMap Name Nat Name.quickCmp := {}

-- Inserting values
def rb1 := myRBMap.insert `apple 1
def rb2 := rb1.insert `banana 2

-- Accessing values (returns Option)
#eval rb2.find? `apple
#eval rb2.find? `cherry 

-- Checking for existence
#eval rb2.contains "apple".toName
#eval rb2.contains `cherry

-- Converting to list
#eval rb2.toList
#eval rb2.toList.map (λ (k, v) => (k.toString, v * 10))
```

# RBTree (Red-Black Tree)

{index}[RBTree Basic Operations]

`RBTree` is a set implemented as a red-black tree. In metaprogramming, Lean provides several "aliases" (pre-defined versions) of `RBTree` so you don't have to provide the comparison function manually, like {lean}`NameSet` is an alias for {lean}`RBTree Name Name.quickCmp`.

```lean
def s1 : NameSet := {}

-- We can insert into either using the same methods
def s2 := s1.insert `x
def s3 := s2.insert `y

#eval s3.contains `x -- true
#eval s3.toList      -- [`x, `y]
```

# Application: Scheduling Processes with RBMap

%%%
tag := "rbmap-scheduling"
number := false
%%%

{index}[Scheduling Processes with RBMap]

In CFS (Completely Fair Scheduler), Linux uses a red-black tree to manage processes based on their virtual runtime. Each process is represented as a node in the tree, and the scheduler can efficiently find the process with the smallest virtual runtime. Here is a simplified example of how we might represent this in Lean using `RBMap`:

```lean
structure Proc where
  pid : Nat
  vruntime : Nat
  -- Add other fields as necessary
deriving Repr, Inhabited

/-- 
Order processes primarily by virtual runtime.
Use PID as a tie-breaker to ensure distinct processes
with same runtime can both exist in the tree.
-/
instance : Ord Proc where
  compare p1 p2 := 
    match compare p1.vruntime p2.vruntime with
    | .eq => compare p1.pid p2.pid
    | ord => ord

/-- A scheduler state: a set of processes ordered -/
def Scheduler := RBMap Proc Unit compare

def Scheduler.empty : Scheduler := RBMap.empty

/-- Add a process to the scheduler -/
def Scheduler.add (s : Scheduler) (p : Proc) : Scheduler :=
  s.insert p ()

/-- Get the next process to run (smallest vruntime) -/
def Scheduler.next? (s : Scheduler) : Option Proc :=
  s.min.map (·.1)

/-- Run the next process: returns updated scheduler -/
def Scheduler.step? (s : Scheduler) : 
  Option (Proc × Scheduler) := do
  let p ← s.next?
  return (p, s.erase p)

-- Example usage
def runExample : IO Unit := do
  let mut s := Scheduler.empty
  s := s.add { pid := 1, vruntime := 10 }
  s := s.add { pid := 2, vruntime := 5 }
  s := s.add { pid := 3, vruntime := 7 }

  IO.println s!"Current processes (sorted by vruntime):"
  for (p, _) in s.toList do
    IO.println s!"  PID: {p.pid}, vruntime: {p.vruntime}"

  if let some (next, s') := s.step? then
    IO.println s!"\nNext to run: PID {next.pid}"
    IO.println s!"Remaining count: {s'.toList.length}"

#eval runExample
```

By using {lean}`RBMap.min`, we can find the process with the 
smallest virtual runtime in $O(\log n)$ time, which is exactly 
why red-black trees are used in real-world schedulers.

