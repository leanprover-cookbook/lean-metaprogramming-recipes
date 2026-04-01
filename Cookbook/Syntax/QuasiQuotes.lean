import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean


set_option pp.rawOnError true

#doc (Manual) "Quasi-Quotes: Creating and Matching Syntax" =>

%%%
tag := "quasi-quotes"
number := false
htmlSplit := .never
%%%

::: contributors
:::

{index}[Quasi-Quotes: Creating and Matching Syntax]

# Quasi-Quotes

When working with syntax, we almost always use _quasi-quotes_, which are a convenient way to create and match syntax. Quasi-quotes are representations of syntax in the form `` `(<syntax>) `` or more generally `` `(<category>| <syntax>) ``. The `category` can be, for example, `command` or `tactic`. If the category is omitted, it defaults to `term`. We can use a parser in place of a category.

Constructions of expressions using quasi-quote can only be done in a monad with `Lean.MonadQuotation`, which includes the meta-programming monads. They can represent either syntax or _typed syntax_. Thus, the following expressions all define syntax for commands:

```lean
def egCommand : Lean.CoreM Lean.Syntax.Command := do
  `(command| example := "Hello World")

def egCommand' : Lean.CoreM Lean.Syntax:= do
  `(command| example := "Hello World")

def egCommand'' : Lean.CoreM (Lean.TSyntax `command) := do
  `(command| example := "Hello World")
```

## Quasi-quotes with interpolation

In the above examples, we exactly specified the syntax we wanted to create. However, we can also use _interpolation_ to create syntax that depends on variables. An expression beginning with `$` is an interpolation, and it can be used to insert the value of a variable into the syntax. For example, we can define a term that is the sum of two natural numbers as follows:

```lean
open Lean
def sumTerm (a b : Nat) : CoreM Syntax.Term := do
  let aLit := Syntax.mkNatLit a
  let bLit := Syntax.mkNatLit b
  `($aLit + $bLit)
```

Here we used the function `Syntax.mkNatLit` that makes a syntax representing a natural number literal from a natural number.

## Matching syntax with quasi-quotes

We can also use quasi-quotes to match syntax. For example, we can define a function that checks if a given syntax is of the form `a + b` for some `a` and `b` and flips the order of `a` and `b` if it is:

```lean
def flipSum : Lean.Syntax.Term → CoreM Lean.Syntax.Term
| `($a +  $b) => `($b + $a)
| stx => return stx

def checkFlipSum (a b : Nat) : CoreM Format := do
  let stx ← flipSum (← (sumTerm a b))
  PrettyPrinter.ppTerm stx

#eval checkFlipSum 1 3 -- 3 + 1
```
