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

{lean}`RBTree` is a set implemented as a red-black tree. In metaprogramming, Lean provides several "aliases" (pre-defined versions) of {lean}`RBTree` so you don't have to provide the comparison function manually, like {lean}`NameSet` is an alias for {lean}`RBTree Name Name.quickCmp`.

```lean
def s1 : NameSet := {}

def s2 := s1.insert `x
def s3 := s2.insert `y

#eval s3.contains `x
#eval s3.toList
```

# Application: Scheduling Processes with RBMap

%%%
tag := "rbmap-scheduling"
number := false
%%%

{index}[Scheduling Processes with RBMap]

In CFS (Completely Fair Scheduler), Linux uses a red-black tree to manage processes based on their virtual runtime. Each process is represented as a node in the tree, and the scheduler can efficiently find the process with the smallest virtual runtime. 

```lean
structure Proc where
  pid : Nat
  vruntime : Nat := 0
  workLeft : Nat
  weight : Nat := 1 -- priority weight
deriving Repr, Inhabited

/-- 
  Order processes primarily by virtual runtime.
  Use PID as a tie-breaker.
-/
instance : Ord Proc where
  compare p1 p2 := 
    match compare p1.vruntime p2.vruntime with
    | .eq => compare p1.pid p2.pid
    | ord => ord

/- A scheduler state: a set of processes
  ordered by vruntime -/
abbrev Scheduler := RBMap Proc Unit compare

namespace Scheduler

def empty : Scheduler := RBMap.empty

/-- Create a new process with a unique PID based
on current scheduler state -/
def createProc (s : Scheduler) (workLeft : Nat)
  (weight : Nat := 1) : Proc :=
  if s.isEmpty then
    { pid := 1, vruntime := 0, workLeft, weight }
  else
    let maxPid := (s.toList.map (λ (p, _) =>
      p.pid)).foldl max 0
    { pid := maxPid + 1, vruntime := 0, workLeft, weight }

/-- Add a process to the scheduler -/
def add (s : Scheduler) (p : Proc) : Scheduler :=
  s.insert p ()

/-- Measure for termination: total remaining
work across all processes -/
def totalWork (s : Scheduler) : Nat :=
  s.toList.foldl (init := 0) 
    (fun acc (p, _) => acc + p.workLeft)

/-- Simulate the actual work of a process -/
def doWork (pid : Nat) : IO Unit := do
  IO.println s!"  [executing PID {pid} ...]"
  IO.sleep 10 -- Simulate a brief period of execution

/-- Run the next process for a time quantum (pure logic) -/
def step (s : Scheduler) (quantum : Nat := 10) 
    : Option (Proc × Scheduler) := do
  -- Pick the process with the smallest vruntime
  let (p, _) ← s.min
  let s' : Scheduler := s.erase p

  let runTime := min p.workLeft quantum
  let vruntimeDelta := (runTime * 10) / p.weight
  let newProc := { p with 
    workLeft := p.workLeft - runTime,
    vruntime := p.vruntime + vruntimeDelta
  }

  -- If it still has work, put it back in the tree
  if newProc.workLeft > 0 then
    some (p, Scheduler.add s' newProc)
  else
    some (p, s')

-- Dynamic simulation loop
partial def simulate (s : Scheduler) : IO Unit := do
  if s.isEmpty then 
    IO.println "\nAll processes finished."
  else
    match _h_step : s.step 10 with
    | some (p, s') => 
        doWork p.pid
        let log := s!"Finished quantum for PID {p.pid} " ++
                   s!"(vruntime: {p.vruntime}, " ++
                   s!"remaining: {p.workLeft})"
        IO.println log
        s'.simulate
    | none => return ()
-- termination_by totalWork s
-- decreasing_by sorry 

end Scheduler

def egRunSchedule : IO Unit := do
  let mut s := Scheduler.empty
  let p1 := s.createProc 30 1
  s := s.add p1
  let p2 := s.createProc 40 2
  s := s.add p2
  let p3 := s.createProc 20 1
  s := s.add p3

  IO.println "Starting CFS Simulation..."
  s.simulate

#eval egRunSchedule
```

# Application: Tracking Scopes in a Compiler

%%%
tag := "rbmap-scope-tracking"
number := false
%%%

{index}[Scope Tracking with RBMap]

When building a compiler or an interpreter, you need to track which variables are in scope at any given point. {lean}`RBMap` is an ideal structure for this because it allows for fast lookups and is persistent.

In a functional compiler, we can represent an environment as a stack of maps (each map being one scope).

```lean
-- A type to represent our variables and their "types"
inductive MyExpr where
  | natType
  | stringType
deriving Repr, Inhabited

/-- An environment is a stack of scopes.
  Each scope is an RBMap from Name to MyExpr. -/
structure Env where
  scopes : List (RBMap Name MyExpr Name.quickCmp) := [{}]
deriving Inhabited

namespace Env

/-- Enter a new nested scope -/
def enterScope (e : Env) : Env :=
  { e with scopes := RBMap.empty :: e.scopes }

/-- Exit the current scope -/
def exitScope (e : Env) : Env :=
  match e.scopes with
  | [] => e -- Should not happen in well-formed code
  | _ :: rest => { e with scopes := rest }

/-- Define a variable in the current (topmost) scope -/
def define (e : Env) (name : Name) (type : MyExpr) : Env :=
  match e.scopes with
  | [] => { e with scopes := [RBMap.empty.insert name type] }
  | top :: rest => { e with scopes := top.insert name type :: rest }

/-- Look up a variable, searching from the innermost scope outwards -/
def lookup (e : Env) (name : Name) : Option MyExpr :=
  e.scopes.findSome? (·.find? name)

end Env

def runScopeExample : IO Unit := do
  let mut env : Env := {}
  
  -- Define a global variable
  env := env.define `global_count .natType
  
  -- Enter a nested function scope
  env := env.enterScope
  env := env.define `local_name .stringType
  
  IO.println s!"Looking up 'local_name': {repr (env.lookup `local_name)}"
  IO.println s!"Looking up 'global_count': {repr (env.lookup `global_count)}"
  
  -- Exit the scope
  env := env.exitScope
  let check1 := env.lookup `local_name |>.isSome
  let check2 := env.lookup `global_count |>.isSome
  IO.println s!"After exiting scope, 'local_name' exists: {check1}"
  IO.println s!"After exiting scope, 'global_count' exists: {check2}"

#eval runScopeExample
```

By using `RBMap` for each scope, we ensure that variable lookup remains $O(\log n)$, even in files with thousands of definitions.

