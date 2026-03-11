import VersoManual
import Cookbook.Lean

open Verso.Genre Manual
open Verso.Genre.Manual.InlineLean

open Cookbook

set_option pp.rawOnError true

#doc (Manual) "Types of Expressions" =>

%%%
tag := "kinds-of-expressions"
number := false
%%%

{index}[Types of Expressions]

# The `Expr` type

Expressions in Lean are represented by the `Expr` type. This is a recursive data structure that can represent a wide variety of expressions, including variables, constants, applications, lambda abstractions, and more. The `Expr` type is defined in the Lean core library and is used extensively in metaprogramming.

We sketch the different kinds of expressions that can be represented by the `Expr` type, along with their constructors. First, we look at the different constructors of the `Expr` type.
```lean
#print Lean.Expr
```


Using `#print Lean.Expr` we can see that Lean has the following constructors for the `Expr` type:

- `Lean.Expr.bvar : Nat → Lean.Expr`
- `Lean.Expr.fvar : Lean.FVarId → Lean.Expr`
- `Lean.Expr.mvar : Lean.MVarId → Lean.Expr`
- `Lean.Expr.sort : Lean.Level → Lean.Expr`
- `Lean.Expr.const : Lean.Name → List Lean.Level → Lean.Expr`
- `Lean.Expr.app : Lean.Expr → Lean.Expr → Lean.Expr`
- `Lean.Expr.lam : Lean.Name → Lean.Expr → Lean.Expr → Lean.BinderInfo → Lean.Expr`
- `Lean.Expr.forallE : Lean.Name → Lean.Expr → Lean.Expr → Lean.BinderInfo → Lean.Expr`
- `Lean.Expr.letE : Lean.Name → Lean.Expr → Lean.Expr → Lean.Expr → Bool → Lean.Expr`
- `Lean.Expr.lit : Lean.Literal → Lean.Expr`
- `Lean.Expr.mdata : Lean.MData → Lean.Expr → Lean.Expr`
- `Lean.Expr.proj : Lean.Name → Nat → Lean.Expr → Lean.Expr`

The most important constructors for us are `const`, `app`, `lam`, and `forallE`, as these are the ones we will encounter most often when working with expressions in Lean. We first look at these constructors and then briefly mention the others.

## `const` expressions

These are given by the `const` constructor and represent constants in Lean. They consist of a name (which can be a qualified name) and a list of universe levels. For example, the expression `Nat` would be represented as ``Lean.Expr.const `Nat []``, while the expression `List Nat` would be represented as ``Lean.Expr.app (Lean.Expr.const `List []) (Lean.Expr.const `Nat [])``.

## `app` expressions

These are given by the `app` constructor and represent function applications. They consist of a function expression and an argument expression. For example, the expression `f x` would be represented as `Lean.Expr.app (Lean.Expr.const f []) (Lean.Expr.const x [])`.

## `lam` expressions

These are given by the `lam` constructor and represent lambda abstractions, i.e., function definitions of the form `fun x ↦ y`. They consist of a name (which is the name of the bound variable), a type expression, a body expression, and a binder info (which indicates whether the variable is implicit or explicit). For example, the expression `fun x : Nat ↦ x + 1` would be represented as `Lean.Expr.lam x (Lean.Expr.const Nat []) (Lean.Expr.app (Lean.Expr.app (Lean.Expr.const Add []) (Lean.Expr.fvar x)) (Lean.Expr.const 1 [])) Lean.Expr.BinderInfo.default`.

## `forallE` expressions

These are given by the `forallE` constructor and represent dependent function types, i.e., types of the form `(x : A) → B` or `∀ x : A, B`. They consist of a name (which is the name of the bound variable), a type expression, a body expression, and a binder info. For example, the expression `∀ x : Nat, List x` would be represented as `Lean.Expr.forallE x (Lean.Expr.const Nat []) (Lean.Expr.app (Lean.Expr.const List []) (Lean.Expr.fvar x)) Lean.Expr.BinderInfo.default`.

## `sort` expressions

These are given by the `sort` constructor and represent universe levels in Lean. They consist of a universe level expression. For example, the expression `Type` would be represented as `Lean.Expr.sort (Lean.Level.succ (Lean.Level.zero))`, while the expression `Prop` would be represented as `Lean.Expr.sort (Lean.Level.zero)`.

## `letE` expressions

These are given by the `letE` constructor and represent let expressions, i.e., expressions of the form `let x := a; b`. They consist of a name (which is the name of the bound variable), a type expression, a value expression, a body expression, and a boolean indicating whether the let binding is recursive.

## `lit` expressions

These are given by the `lit` constructor and represent natural number or string literals, which are used in Lean for efficiency in place of, for example, expressions in the inductive type `Nat`. They consist of a literal value. For example, the expression `123` would be represented as `Lean.Expr.lit (Lean.Literal.natVal 123)`.

## `fvar` and `mvar` expressions

These are given by the `fvar` and `mvar` constructors and represent free variables and metavariables, respectively. They consist of an identifier for the variable. Free variables are used to represent variables that are not bound by any quantifier or lambda abstraction, while metavariables are used as placeholders for expressions that have not yet been determined.

## `bvar` expressions

These are given by the `bvar` constructor and represent bound variables, i.e., variables that are bound by a quantifier or lambda abstraction. They consist of a de Bruijn index, which is a natural number that indicates how many binders away the variable is from its binding site.

## `proj` expressions

These are given by the `proj` constructor and represent projections from structures. They consist of a structure name, a field index, and a structure expression. For example, if we have a structure `Point` with fields `x` and `y`, then the expression `p.x` would be represented as `Lean.Expr.proj Point 0 (Lean.Expr.const p [])`, while the expression `p.y` would be represented as `Lean.Expr.proj Point 1 (Lean.Expr.const p [])`.

## `mdata` expressions

These are given by the `mdata` constructor and represent expressions with metadata. They consist of a metadata object and an expression. Metadata can be used to attach additional information to an expression, such as source location information or annotations.
