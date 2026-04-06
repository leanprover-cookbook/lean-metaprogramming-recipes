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

Lean allows to define custom syntax for a {name}`term`. One convenient way to do this is to use `macro` or `elab`, which let you specify both the syntax and its behavior in one place. We will use Python syntax as an example to illustrate how to define custom syntax for terms in Lean. We will start with a simple example of parsing Python exponentiation syntax and then move on to a more complex example of parsing Python `for` loop syntax.

# Syntax for Python exponentiation
%%%
tag := "syntax-for-python-exponentiation"
number := false
%%%
{index}[Python exponentiation DSL]

We will start with a simple example for parsing Python exponentiation syntax in Lean. The following `macro` declaration tells Lean how to parse something of the form `2**4` and expands it into Lean's exponentiation syntax.

```lean
macro n:num "**" m:num : term => `($n^$m)

#eval 2**3 --8
```

Here, `num` is a parser that accepts strictly numeric literals and rejects everything else.

# Syntax for Python `for` loop
%%%
tag := "syntax-for-python-for-loop"
number := false
%%%
{index}[Python `for` loop DSL]

In Python, list comprehensions provide a concise way to create lists. For example, the expression `[x^2 for x in [1,2,3,4,5]]` generates a list of the squares of the first five natural numbers. We will define similar syntax in Lean and then implement the logic to evaluate it.

In Lean, this can be accomplished by using the {name}`List.map` function.

```lean
#eval List.map (fun x => x * x) [1, 2, 3, 4]
```

## A `macro` that parses Python-like `for` loop
%%%
tag := "macro-for-python-for-loop"
number := false
%%%

Next, we define a `macro` that lets us write syntax similar to Python syntax in Lean. It parses expressions of the form `[<term> pyfor <ident> in <term>]` and transforms them into a standard Lean expression using {name}`List.map`. The {name}`ident` is a placeholder for the variable name used in the comprehension, and the two {name}`term` placeholders represent the expression being generated and the collection being iterated over.

```lean
macro "[" t:term "pyfor" x:ident "in" l:term "]": term => do
  let fn ← `(fun $x => $t)
  `(List.map $fn $l)

#eval [x * 2 pyfor x in [1, 2, 3, 4]] --> [2, 4, 6, 8]
```
If you prefer to separate the syntax declaration from the macro expansion, Lean also lets you define the syntax first with `syntax` and then add macro rules separately.

```lean
syntax "[" term "pyfor'" ident "in" term "]" : term

macro_rules
| `([ $t:term pyfor' $x:ident in $l:term ]) => do
    let fn ← `(fun $x => $t)
    `(List.map $fn $l)
```

## An elaborator that parses Python-like `for` loop

%%%
tag := "elaborator-for-python-for-loop"
number := false
%%%

Here is a more robust and complete implementation using an elaborator (`elab`). This version checks whether the collection being iterated over is a {name}`List` or an {name}`Array` and handles each case accordingly:

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

- {name}`Term.elabTerm` is used to elaborate the syntax of the collection `l` and the function `fnStx` into actual Lean expressions, while {name}`Meta.inferType` is used to determine the type of the collection.
- {name}`Term.synthesizeSyntheticMVarsNoPostponing` is called to ensure that any metavariables generated during elaboration are fully resolved before we attempt to check the type. If the term `l` is a {name}`List`, `ltype` will have the form `List ?m`, where `?m` is a metavariable representing the element type. Calling {name}`Term.synthesizeSyntheticMVarsNoPostponing` ensures that `?m` is resolved to a concrete type, allowing us to proceed with the application of `mkAppM` without running into issues caused by unresolved metavariables.
- {name}`Expr.isAppOf` is used to check whether the type of `l` is a {name}`List` or an {name}`Array`. Depending on the result, we use {name}`mkAppM` to construct the appropriate {name}`List.map` or {name}`Array.map` expression. If the type is neither, we throw a custom error.
