import VersoManual
import Cookbook.Syntax.QuasiQuotes
import Cookbook.Syntax.introducingTermsPythonsForComprehensionInLean
import Cookbook.Syntax.introducingCommandsCheckingThatSomethingCanBeProvedByGrind
import Cookbook.Syntax.addingSyntaxAndSyntaxCategories

open Verso.Genre Manual

#doc (Manual) "Syntax and Macros" =>

%%%
tag := "syntax"
number := false
%%%

In Lean, code is first _parsed_ into syntax, which is then _elaborated_ into expressions. The easiest way to extend create new tactics, commands and terms is to work at the syntax level, with new syntax mapped to existing syntax. Functions that transform syntax are called _macros_.

In this chapter we give recipes for matching, creating and transforming syntax.

{include 1 Cookbook.Syntax.QuasiQuotes}
{include 1 Cookbook.Syntax.introducingTermsPythonsForComprehensionInLean}
{include 1 Cookbook.Syntax.introducingCommandsCheckingThatSomethingCanBeProvedByGrind}
{include 1 Cookbook.Syntax.addingSyntaxAndSyntaxCategories}
