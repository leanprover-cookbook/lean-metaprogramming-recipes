import VersoManual
import Cookbook.Lean
import Cookbook.Overview.CodeSyntaxExpressions
import Cookbook.Overview.MonadsInPractice

open Verso.Genre Manual Cookbook

#doc (Manual) "What is Metaprogramming?" =>
%%%
tag := "overview"
number := false
%%%

::: contributors
:::

Meta programming in Lean refers to the ability to write code that manipulates other code. As code is represented by strings, the simpleminded way to do meta programming is to manipulate strings. However, this is  very error-prone and not very powerful or efficient.

Instead, in meta-programming one manipulates the _internal representations_ of code. In Lean, there are two levels of internal representations of code: *Syntax* and *Expressions* (in most other languages one manipulates the *Abstract Syntax Tree*). The easier form of meta programming is to manipulate syntax (so called *Macro*s), and the more powerful form is to manipulate expressions. The recipes in this manual will cover both levels of meta programming, but most of the recipes will be at the level of expressions.

{include 1 Cookbook.Overview.CodeSyntaxExpressions}
{include 1 Cookbook.Overview.MonadsInPractice}
