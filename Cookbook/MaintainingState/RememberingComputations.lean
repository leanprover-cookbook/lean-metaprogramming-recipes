import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean
open Std

set_option pp.rawOnError true

#doc (Manual) "State Monad: Remembering Computations" =>

%%%
tag := "state-monad"
number := false
htmlSplit := .never
%%%

::: contributors
:::

{index}[State Monad: Remembering Computations]

# State Monad

Since Lean is a functional programming language, it does not have mutable state. However, we often want to write code that manipulates state. For example, we may want to remember the result of a computation for a recursive function to avoid redundant computations.

The _State Monad_ is a powerful tool for doing this. It allows us to write code that looks like it is manipulating state, but under the hood it is actually passing the state around as an argument. Given a state type `S` and a value type `A`, the State Monad is defined as follows:
```lean
def State (S A : Type) : Type := S → (A × S)
```
This means that a value of type `State S A` is a function that takes a state of type `S` and returns a pair of a value of type `A` and a new state of type `S`.

Using the `do` notation, we can write code that is concise and readable while handling state. As an example, we use a state monad to implement a memoized function computing so called _Catalan numbers_, which are a sequence of natural numbers that occur in various counting problems in combinatorics.

The Catalan numbers satisfy the recurrence relation:
* `C(0) = 1`
* `C(n+1) = Σ (C(i) * C(n-i)) for i = 0 to n`

We can naively implement this recurrence relation in Lean, but it will be inefficient for large `n` due to repeated calculations. The following is a naive implementation of the Catalan numbers (which we do not prove terminates):

```lean
partial def catalanNaive : Nat → Nat
  | 0 => 1
  | n + 1 =>
    let terms :=
      List.range (n + 1) |>.map
        (fun i => catalanNaive i * catalanNaive (n - i))
    terms.sum
```


We show how to use memoization to optimize the computation of Catalan numbers using `State` Monad. We store the previously computed values of Catalan numbers in a {lean}`HashMap` and use it to avoid redundant computations. We define a type alias for our state monad as follows:

```lean
abbrev CatalanM := StateM (HashMap Nat Nat)
```

Thus, a term of type `CatalanM α` is a function that takes a state of type `HashMap Nat Nat` and returns a pair of a value of type `α` and a new state of type `HashMap Nat Nat`.

To compute the `n`-th Catalan number, we first check if it is already computed and stored in the state. If it is, we return it. If not, we compute it using the recurrence relation, store it in the state, and then return it. Here is the implementation:

```lean
partial def catalanMemo (n : Nat) : CatalanM Nat := do
  let cache ← get
  match cache.get? n with
  | some value => return value
  | none =>
    match n with
    | 0 =>
      modify (fun m => m.insert 0 1)
      return 1
    | n + 1 =>
      let mut sum := 0
      for i in [0:n + 1] do
        let ci ← catalanMemo i
        let cni ← catalanMemo (n - i)
        sum := sum + (ci * cni)
      modify (fun m => m.insert (n + 1) sum)
      return sum
```

When the statement `let ci ← catalanMemo i` is executed, the function `catalanMemo i` is called with the current state. This returns a pair of the computed value `ci` and a new state. The natural number is assigned to `ci`, and the new state is passed along to the next computation. This way, we can efficiently compute the Catalan numbers without redundant calculations.

With the memoized version, we can compute much larger Catalan numbers efficiently. For example, we can compute the 32nd Catalan number in a fraction of a second as follows:

```lean
#eval catalanMemo 32 |>.run' {}
```
