import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Tactic using macros" =>

%%%
tag := "tactic-using-macro"
number := false
htmlSplit := .never
%%%

::: contributors
:::


{index}[Tactic using macros]

# `repeat_apply` tactic

We start with an example of a routine proof we might do. To prove `2 ≤ 6`.
```lean
example : 2 ≤ 6 := by
  apply Nat.le_succ_of_le
  apply Nat.le_succ_of_le
  apply Nat.le_succ_of_le
  apply Nat.le_succ_of_le
  apply Nat.le_refl
```
 This approach is highly repetitive. We can simplify it by using the `repeat` and `first` tactic combinators.
 ```lean
 example : 2 ≤ 6 := by
  repeat (first| apply Nat.le_refl | apply Nat.le_succ_of_le)
 ```
To reduce this to a single, readable line, we can define a custom tactic using a `macro`.
 ```lean
 macro "nat_le" : tactic =>
  `(tactic| repeat(first| apply Nat.le_refl |
    apply Nat.le_succ_of_le))

 example: 2 ≤ 6 := by nat_le
 ```

While this works for our specific case, we can make it far more useful by abstracting the theorems. Let's construct a parameterized `macro` that accepts two theorems as arguments. It will repeatedly attempt to apply the second theorem (`t₂`) to close the goal, and whenever that fails, it makes progress by applying the first theorem (`t₁`).

Here is how we construct such a tactic:

```lean
macro "repeat_apply" t₁:term "then" t₂:term : tactic  =>
    `(tactic| repeat(first| apply $t₂| apply $t₁ ))

example : 10 ≤ 12 := by repeat_apply
        Nat.le_succ_of_le then Nat.le_refl
```
