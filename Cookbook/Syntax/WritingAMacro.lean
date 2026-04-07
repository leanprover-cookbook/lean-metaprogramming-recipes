import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command Term Parser Category

set_option pp.rawOnError true

#doc (Manual) "Writing a Macro" =>

%%%
tag := "writing-a-macro"
number := false
htmlSplit := .never
%%%

::: contributors
:::


{index}[Writing a Macro]
Lean allows to define custom syntax for a {name}`term`. One convenient way to do this is to use `macro`, which let you specify both the syntax and its behavior in one place. We will use Python syntax as an example to illustrate how to define custom syntax for terms in Lean. We will start with a simple example of parsing Python exponentiation syntax and then move on to a more complex example of parsing Python `for` loop syntax.

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

The `macro_rules` command is used to pattern-match on our custom syntax and define exactly how it should be translated (or "expanded") into standard Lean code. In this case, we take the term `t`, the identifier `x`, and the list `l` from our custom syntax and construct a new expression that applies `List.map` to a lambda function `fn`(created from `t` and `x`) and the list `l`.

Macros only act as syntactic sugar and are only exapanded to a different "already-existing" syntax. In a later recipe, {ref "elaborator-for-python-for-loop"}[An elaborator that parses Python-like `for` loop], we will see how to write an elaborator that parses the same syntax and performs additional checks during elaboration.
