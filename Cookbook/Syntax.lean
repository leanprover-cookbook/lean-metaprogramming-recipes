import VersoManual
import Cookbook.Lean
import Cookbook.Syntax.QuasiQuotes
import Cookbook.Syntax.SyntaxForTerms
import Cookbook.Syntax.SyntaxForCommands
import Cookbook.Syntax.AddingSyntaxAndSyntaxCategories

open Verso.Genre Manual Cookbook

#doc (Manual) "Syntax and Macros" =>

%%%
tag := "syntax"
number := false
%%%

::: contributors
:::

In Lean, code is first _parsed_ into syntax, which is then _elaborated_ into expressions. The easiest way to create new tactics, commands and terms is to work at the syntax level, with new syntax mapped to existing syntax. Functions that transform syntax are called _macros_.

In this chapter we give recipes for matching, creating and transforming syntax.

{include 1 Cookbook.Syntax.QuasiQuotes}
{include 1 Cookbook.Syntax.SyntaxForTerms}
{include 1 Cookbook.Syntax.SyntaxForCommands}
{include 1 Cookbook.Syntax.AddingSyntaxAndSyntaxCategories}
