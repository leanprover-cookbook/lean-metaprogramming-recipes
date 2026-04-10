import VersoManual
import Cookbook.Lean
import Cookbook.MaintainingState.RememberingComputations
import Cookbook.MaintainingState.MutableVariables
import Cookbook.MaintainingState.MutableVarExamples
import Cookbook.MaintainingState.EnvironmentExtensionsAndAttributes
import Cookbook.MaintainingState.EnvironmentExtensionsAndAttributesExample

open Verso.Genre Manual Cookbook

#doc (Manual) "Maintaining State" =>

%%%
tag := "state"
number := false
%%%

::: contributors
:::


Since Lean is a pure functional programming language, it does not have mutable state in the traditional sense. However, we can maintain state in various ways at various levels. _State Monads_ maintain state during execution of a program, and the state can be passed during function calls. _Mutable variables_ allow us to maintain state across commands in the same session. Finally, state can be persisted across files and sessions by using _Environment extensions_. In this chapter we give recipes for maintaining state using these different techniques.

*Recipes:*

{include 1 Cookbook.MaintainingState.RememberingComputations}
{include 1 Cookbook.MaintainingState.MutableVariables}
{include 1 Cookbook.MaintainingState.MutableVarExamples}
{include 1 Cookbook.MaintainingState.EnvironmentExtensionsAndAttributes}
{include 1 Cookbook.MaintainingState.EnvironmentExtensionsAndAttributesExample}
