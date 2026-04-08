import VersoManual
import Cookbook.Lean
import Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean


open Lean Elab Meta Tactic Command Term Parser Category

set_option pp.rawOnError true

#doc (Manual) "Adding Syntax for terms" =>

%%%
tag := "adding-syntax-for-terms"
number := false
htmlSplit := .never
%%%

::: contributors
:::

{index}[Adding Syntax for terms]

# Syntax for Python `for` loop

We will improve upon the `macro` that we defined in the recipe {ref "macro-for-python-for-loop"}[A `macro` that parses Python-like `for` loop], for parsing Python `for` loop syntax. Here we use an elaborator (`elab`) instead of a `macro` to parse the same syntax. This version checks whether the collection being iterated over is a {name}`List` or an {name}`Array` and handles each case accordingly. This also gives a more informative error message when the collection is of an unexpected type.

## An elaborator that parses Python-like `for` loop

%%%
tag := "elaborator-for-python-for-loop"
number := false
%%%

Here is a more robust and complete implementation using an elaborator (`elab`). This version checks whether the collection being iterated over is a {name}`List` or an {name}`Array` and handles each case accordingly:

```lean
elab "[" t:term "py_for" x:ident "in" l:term  "]" :
    term => do
  let fnStx ← `(fun $x => $t)
  let lExpr ← elabTerm l none
  let fn ← elabTerm fnStx none
  let ltype ← inferType lExpr
  Term.synthesizeSyntheticMVarsNoPostponing
  if ltype.isAppOf ``List then
    mkAppM ``List.map #[fn, lExpr]
  else
    if ltype.isAppOf ``Array then
      mkAppM ``Array.map #[fn, lExpr]
    else
      throwError "Expected a List or Array in py_for
      comprehension, got {ltype}"

#eval [x * 2 py_for x in [1, 2, 3, 4]] --> [2, 4, 6, 8]
#eval [x * 2 py_for x in #[1, 2, 3, 4]] --> #[2, 4, 6, 8]

/--
error: Expected a List or Array in py_for
      comprehension, got String
-/
#guard_msgs in
#eval [x * 2 py_for x in "List"]
```
Let's break down the specific metaprogramming functions used in the elaborator above:

- {name}`Term.elabTerm` is used to elaborate the syntax of the collection `l` and the function `fnStx` into actual Lean expressions, while {name}`Meta.inferType` is used to determine the type of the collection.
- {name}`Term.synthesizeSyntheticMVarsNoPostponing` is called to ensure that any metavariables generated during elaboration are fully resolved before we attempt to check the type. If the term `l` is a {name}`List`, `ltype` will have the form `List ?m`, where `?m` is a metavariable representing the element type. Calling {name}`Term.synthesizeSyntheticMVarsNoPostponing` ensures that `?m` is resolved to a concrete type, allowing us to proceed with the application of `mkAppM` without running into issues caused by unresolved metavariables.
- {name}`Expr.isAppOf` is used to check whether the type of `l` is a {name}`List` or an {name}`Array`. Depending on the result, we use {name}`mkAppM` to construct the appropriate {name}`List.map` or {name}`Array.map` expression. If the type is neither, we throw a custom error.
