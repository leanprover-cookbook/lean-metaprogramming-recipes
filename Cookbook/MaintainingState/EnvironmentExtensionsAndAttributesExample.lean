import VersoManual
import Cookbook.Lean
import Cookbook.MaintainingState.EnvironmentExtensionsAndAttributes

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean
open Std Lean Meta Elab Tactic

set_option pp.rawOnError true

#doc (Manual) "Environment Extensions and Attributes: Example" =>

%%%
tag := "environment-extensions-and-attributes-example"
number := false
htmlSplit := .never
%%%

::: contributors
:::

{index}[Environment Extensions and Attributes: Example]

In the recipe {ref "environment-extensions-and-attributes"}[Environment Extensions and Attributes], we defined an environment extension to store lemmas tagged with the `@[distribute]` attribute, and we defined the `@[distribute]` attribute to add lemmas to this environment extension, and implemented the `distribute` tactic that retrieves the lemmas from the environment extension and applies them.

In this recipe, we show how to use the `@[distribute]` attribute and the `distribute` tactic. We cannot tag or use attributes in the same file where they are initialized, so we had to split the code into two files. In this file, we tag some lemmas with the `@[distribute]` attribute, and then we use the `distribute` tactic to apply these lemmas.

```lean
open Distribute

@[distribute]
theorem distributeAnd (a b c : Prop) :
    (a ∧ (b ∨ c)) ↔ (a ∧ b) ∨ (a ∧ c) := by
  grind

example : (1 = 1) ∧ (2 = 3 ∨ 3 = 3) := by
  distribute
  grind
```

We can also tag definitions or theorems from imported modules with the `@[distribute]` attribute, and they will be added to the environment extension and used by the `distribute` tactic.

```lean
attribute [distribute] Nat.mul_add

example (a b c : Nat) : a * (b + c) = a * b + a * c := by
  distribute
```
