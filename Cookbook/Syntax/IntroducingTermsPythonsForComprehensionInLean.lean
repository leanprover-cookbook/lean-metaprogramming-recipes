import VersoManual
import Cookbook.Lean
import Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean


open Lean Elab Meta Tactic Command Term

set_option pp.rawOnError true

#doc (Manual) "Adding Syntax for terms" =>

%%%
tag := "introducing-terms-pythons-for-comprehension-in-lean"
number := false
%%%

::: contributors
:::

{index}[Adding Syntax for terms]

In this recipe, we introduce syntax for Python-style list comprehensions in Lean. In Python, list comprehensions provide a concise way to create lists. For example, the expression `[x^2 for x in [1,2,3,4,5]]` generates a list of squares of the first five natural numbers. We will define similar syntax in Lean and then implement the logic to evaluate it.

In Lean, this can be accomplished by using the {lean}`List.map` function.

```lean
#eval List.map (fun x => x * x) [1, 2, 3, 4]

```
We want to create custom syntax that allows us to write something like Python syntax in Lean. To achieve this, we define a new syntax rule:

```lean
syntax "[" term "pyfor" ident "in" term "]" : term
```

The rule above tells Lean that we want to parse expressions of the form `[<term> pyfor <ident> in <term>]` as a term. The `ident` is a placeholder for the variable name used in the comprehension, and the two `term` placeholders represent the expression being generated and the collection being iterated over.

Next, we need to implement the logic to evaluate this new syntax. We can do this by defining a `macro` that transforms our custom syntax into a standard Lean expression using {lean}`List.map`.

```lean
macro_rules
| `([ $t:term pyfor $x:ident in $l:term ]) => do
    let fn ← `(fun $x => $t)
    `(List.map $fn $l)

#eval [x * 2 pyfor x in [1, 2, 3, 4]] --> [2, 4, 6, 8]
```
Alternatively, we can combine the syntax declaration and the macro expansion into a single concise definition using the `macro` command:
```lean
macro "[" t:term "pyfor" x:ident "in" l:term "]": term => do
    let fn ← `(fun $x => $t)
    `(List.map $fn $l)
```

Below is a more robust and complete implementation using an elaborator (`elab`). This version checks whether the collection being iterated over is a {lean}`List` or an {lean}`Array` and handles them accordingly:

```lean+error (name:= pyfor)
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
#eval [x * 2 py_for x in "List"] --> Expected a List
    -- or Array in py_for comprehension, got String
```
Let's break down the specific metaprogramming functions used in the elaborator above:

- {lean}`Term.elabTerm` is used to elaborate the syntax of the collection `l` and the function `fnStx` into actual Lean expressions, while {lean}`Meta.inferType` is used to determine the type of the collection.
- {lean}`Term.synthesizeSyntheticMVarsNoPostponing` is called to ensure that any metavariables generated during elaboration are fully resolved before we attempt to check the type. If the term `l` is a {lean}`List`, `ltype` will have the form `List ?m`, where `?m` is a metavariable representing the element type. Calling {lean}`Term.synthesizeSyntheticMVarsNoPostponing` ensures that `?m` is resolved to a concrete type, allowing us to proceed with the application of `mkAppM` without running into issues with unresolved metavariables.
- {lean}`Expr.isAppOf` is used to check whether the type of `l` is a {lean}`List` or an {lean}`Array`. Depending on the result, we use {lean}`mkAppM` to construct the appropriate {lean}`List.map` or {lean}`Array.map` expression. If the type is neither, we throw a custom error.
