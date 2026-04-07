import VersoManual
import Cookbook.Lean
import Cookbook.Elaboration.SyntaxForCommands
import Cookbook.Elaboration.SyntaxForTerms

open Verso.Genre Manual Cookbook

#doc (Manual) "Elaboration: Extending Syntax" =>

%%%
tag := "elaboration-extending-syntax"
number := false
%%%

::: contributors
:::

The easiest way to extend the syntax of Lean is to write macros that transform new syntax into existing syntax (see {ref "syntax"}[Syntax and Macros]). However, a more powerful way to extend the syntax of Lean is to write new *elaborators* that transform new syntax into expressions. In this chapter we give recipes for writing elaborators for new syntax for terms and commands.

{include 1 Cookbook.Elaboration.SyntaxForTerms}
{include 1 Cookbook.Elaboration.SyntaxForCommands}
