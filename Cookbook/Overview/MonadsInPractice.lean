import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean


set_option pp.rawOnError true

#doc (Manual) "Monads in Practice" =>

%%%
tag := "monads-in-practice"
number := false
htmlSplit := .never
%%%

{index}[Monads in Practise]

::: contributors
:::

# Monads in Practice: `MacroM`, `CoreM`, `MetaM`, `TermElabM`, and `TacticM`

For meta-programming in Lean, we generally have to work with so called _Monads_. We will not attempt to explain these here, but instead give a simplified cartoonish version of the relevant Monads: `MacroM`, `CoreM`, `MetaM`, `TermElabM`, and `TacticM`.

## State Monads

At their core, these are instances of _state_ monads. If `MyMonadM` is a state monad with state `MyMonad.State`, then roughly speaking, a value of type `MyMonadM α` is a function that takes an input of type `MyMonad.State` and produces an output of type `α` along with a new state of type `MyMonad.State`. In other words, we can think of a value of type `MyMonadM α` as a function of the form `MyMonad.State → (α × MyMonad.State)`. So in practice working with these monads means that we can access the state (for example the tactic state) and also modify it. Usually we do not deal with the state directly, but instead use the various API functions provided by Lean to access and modify the state.

## Monad Hierarchy

At the next level of refinement, note that the monads form a hierarchy, with the _higher_ monad built from the lower one with *additional* state. Thus `MetaM α` has the state `Meta.State` in addition to `Core.State`, and `TermElabM α` has the state `TermElab.State` in addition to `Meta.State` and `Core.State`. On top of these is `TacticM α`, which has the state `Tactic.State` in addition to `TermElab.State`, `Meta.State`, and `Core.State`. So when we are working with `TacticM α`, we have access to the tactic state, the term elaboration state, the meta state, and the core state. When we are working with `MetaM α`, we have access to the meta state and the core state, but not the term elaboration state or the tactic state. When working with a higher monad we can use all the functions of lower monads.

When working purely with Syntax we use the monad `MacroM α`, which has the state `Macro.State`. This is not part of the above hierarchy.

Below the `CoreM` monad is the monad `IO α`, which is the monad of input/output operations. This cannot be used for meta-programming but rather handles side-effects like reading and writing files, printing to the console, etc.

## Error handling, logging and other features

In addition to states the metaprogramming monads support various operations for error handling, logging, and other features.

## Reader monads

A part of the state of monads is read-only. Technically this is obtained by using a reader monad extending the state monad.
