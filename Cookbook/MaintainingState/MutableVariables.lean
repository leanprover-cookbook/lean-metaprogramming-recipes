import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean
open Std

set_option pp.rawOnError true

#doc (Manual) "Mutable Variables across commands" =>

%%%
tag := "mutable-variables"
number := false
htmlSplit := .never
%%%

::: contributors
:::

{index}[Mutable Variables across commands]

# Mutable Variables across commands

In the recipe {ref "state-monad"}[State Monad] we saw how to preserve state in a function. However, sometimes we want to preserve state across different commands. If we evaluate `catalanMemo 32` in the Infoview, in the process we have also computed all the Catalan numbers from `C(0)` to `C(32)`. However, if we next evaluate `catalanMemo 31`, we will have to recompute all the Catalan numbers from `C(0)` to `C(31)`, which is inefficient. In this section, we show how to preserve state across different commands using mutable variables.

We can use either {lean}`IO.Ref` or {lean}`Std.Mutex` to create mutable variables in Lean. The `IO.Ref` is a mutable reference that can be used in the `IO` monad, while `Std.Mutex` is a mutex that can be used to protect access to a mutable variable in a concurrent setting. In this recipe, we use `Std.Mutex` to create a mutable variable that stores the computed Catalan numbers. We use a mutex to ensure that the mutable variable is accessed in a thread-safe manner.

We initialize a mutable variable `catalanCache` of type `Mutex (HashMap Nat Nat)` to store the computed Catalan numbers. The `HashMap` is used to store the computed values of Catalan numbers, where the key is the natural number `n` and the value is the corresponding Catalan number `C(n)`. We then implement helper functions to get from and save to the cache.

```lean
initialize catalanCache : Mutex (HashMap Nat Nat) ←
  Mutex.new (HashMap.emptyWithCapacity)

def getCatalanCache? (n : Nat) : IO (Option Nat) :=
  catalanCache.atomically do
    let m ← get
    return m.get? n

def setCatalanCache (n : Nat) (value : Nat) : IO Unit :=
  catalanCache.atomically do
    modify (fun m => m.insert n value)
```


```lean
partial def catalanCached (n : Nat) : IO Nat := do
  let cache ← getCatalanCache? n
  match cache with
  | some value => return value
  | none =>
    match n with
    | 0 =>
      setCatalanCache 0 1
      return 1
    | n + 1 =>
      let mut sum := 0
      for i in [0:n + 1] do
        let ci ← catalanCached i
        let cni ← catalanCached (n - i)
        sum := sum + (ci * cni)
      setCatalanCache (n + 1) sum
      return sum
```
