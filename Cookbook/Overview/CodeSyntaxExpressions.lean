import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean


set_option pp.rawOnError true

#doc (Manual) "Code, Syntax, and Expressions" =>

%%%
htmlSplit := .never
%%%

::: contributors
:::

{index}[Code, Syntax, and Expressions]

# Internal Representations of Code

%%%
tag := "code-syntax-expressions"
number := false
%%%

Both `Syntax` and `Expr` are types defined in the Lean core library, and they are used extensively in meta programming. Lean provides a rich API for working with both `Syntax` and `Expr`.

## Syntax

Syntax in Lean is extensible and can represent a wide variety of syntactic constructs, including variables, constants, applications, lambda abstractions, and more. Translating strings to syntax is done by _Parsers_, which are functions that take strings as input and produce syntax as output.

Manipulating syntax is done by _Macros_, which are functions that take syntax as input and produce syntax as output. Macros are used to define new syntactic constructs and to perform transformations on existing syntax.

## Expressions

Syntax is further processed by the _Elaborator_, which takes syntax as input and produces expressions as output. The elaborator performs type inference, resolves names, and performs other transformations to produce well-typed expressions.

Expressions in Lean are represented by the `Expr` type, which is a recursive data structure that can represent a wide variety of expressions, including variables, constants, applications, lambda abstractions, and more. More sophisticated meta programming often involves manipulating expressions directly, and most of the recipes will be at this level.
