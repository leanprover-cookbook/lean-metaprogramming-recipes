import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Pattern-Matching Expressions directly" =>

%%%
tag := "pattern-matching-expressions-directly"
number := false
%%%

::: contributors
:::


{index}[Pattern-matching expressions directly]

In Meta-programming, for instance for writing tactics, it is often necessary to see whether an expression matches a certain pattern. Lean provides several [Recognizers](https://leanprover-community.github.io/mathlib4_docs/Lean/Util/Recognizers.html) that can be used to check if an expression matches a certain pattern and to extract the relevant sub-expressions. For example, the function {lean}`Expr.isAppOf` checks if an expression is an application of a certain function and extracts the arguments of the application.

# Example : Splitting goals in `∧`

As an example, we may want to decompose goals iteratively of the form `P ∧ Q` into separate goals `P` and `Q`. To do this, we can check if the main target is of the form `P ∧ Q` using the {lean}`Expr.app2?` function, which checks if an expression is an application of a given constant with two arguments, and if so, returns the arguments of the application. Doing this recursively allows us to split goals of the form `P1 ∧ P2 ∧ P3` into three separate goals `P1`, `P2`, and `P3`. We do so in the following function.

```lean
partial def splitAnds (e: Expr) : List Expr :=
  match e.app2? ``And with
  | some (P, Q) => splitAnds P ++ splitAnds Q
  | none => [e]
```

To see this function in action we write an elaborator that fetches the main goal during the proof and passes it to `matchNatLe` (see {ref "viewing-closing-goals"}[Viewing and Closing Goals] for how to write tactics using elaborators and {ref "displaying-in-the-infoview"}[Displaying in the Infoview] for how to display information in the Infoview).

```lean
elab "splitAnds" : tactic => do
  withMainContext do
  let goal ← getMainTarget
  let subgoals := splitAnds goal
  if subgoals.length = 1 then
    logInfo m!"The goal is not a conjunction: {goal}"
  else
    logInfo m!"The goal is a conjunction"
    logInfo m!" Subgoals ({subgoals.length} subgoals) are:"
    for subgoal in subgoals do
      logInfo m!"Subgoal: {subgoal}"

example: 123 ≤ 234 := by
  splitAnds
  simp

example: (123 ≤ 234) ∧ (234 ≤ 345) ∧
    (345 ≤ 456 ∧ 2 ≤ 3) := by
  splitAnds
  simp
```

## Other Recognizers

As mentioned above, there are several other recognizers that can be used to check if an expression matches a certain pattern and to extract the relevant sub-expressions. There are also related Boolean functions that check if an expression matches a certain pattern without extracting sub-expressions.

For example, the function {lean}`Expr.isLambda` checks if an expression is a lambda abstraction and extracts the body of the lambda. The function {lean}`Expr.isForall` checks if an expression is a universal quantification and extracts the body of the quantification. The function {lean}`Expr.isAppOfArity` checks if an expression is an application of a certain function with a certain number of arguments and extracts the arguments of the application. We also have matchers {lean}`Expr.eq?`, {lean}`Expr.const?`, {lean}`Expr.prod?`, etc. that check if an expression is of a certain form and extract the relevant sub-expressions.

You can find the full list of recognizers in the [Lean 4 documentation](https://leanprover-community.github.io/mathlib4_docs/Lean/Util/Recognizers.html).
