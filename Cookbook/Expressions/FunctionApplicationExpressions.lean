import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

set_option pp.rawOnError true

#doc (Manual) "Expressions from Function Applications" =>

%%%
tag := "expressions-from-function-applications"
number := false
-- Optional: If you don't want the recipe to be split into multiple subpages, because of depth.
htmlSplit := .never
%%%

::: contributors
:::

{index}[Expressions from Function Applications]

# Constant Expressions

The simplest expressions are constants. These can be built using the `mkConst` function, which takes the name of a constant and returns an expression representing that constant. For example, ```mkConst ``Nat``` returns an expression representing the type of natural numbers.

# Direct Application

The simplest way to build an expression representing a function application is to use the `mkApp` function, which takes a function expression and an argument expression and returns an expression representing the application of the function to the argument. For example, we can build an expression for `1` as follows:

```lean
open Lean in
def oneExpr : Expr :=
  mkApp (mkConst ``Nat.succ) (mkConst ``Nat.zero)
```

In case of functions with multiple arguments, we can use `mkAppN`, which takes a function expression and a list of argument expressions. For example, we can build an expression for `2` as follows:

```lean
open Lean in
def twoExpr : Expr :=
  mkAppN (mkConst ``Nat.add) #[oneExpr, oneExpr]
```

# Function application with implicit arguments, typeclasses etc.

While simple expressions can be built using `mkApp` and `mkAppN`, these functions do not handle implicit arguments, typeclass instances, universe levels, unification or other features of Lean's elaboration process. To build expressions that correctly handle these features, we can use the `mkAppM` function, which takes the name of a function and a list of argument expressions, and returns an expression representing the application of the function to the arguments, while correctly handling implicit arguments and typeclass instances.

For instance, we can build an expression for `2` corresponding to `Add.add 1 1` using `mkAppM` as follows:

```lean
open Lean Meta in
def twoExprM : MetaM Expr := do
  mkAppM ``Add.add #[oneExpr, oneExpr]
```

There is a related function `mkAppM'` where the first argument is an expression instead of a name. If one needs finer control over which arguments should be inferred and which are given explicitly, there is a function `mkAppOptM` that takes an array of `Option Expr`, where `none` indicates that the argument should be inferred and `some e` indicates that the argument should be given explicitly as `e`.

## Example: Communtativity of addition

As an example of using `mkAppM`, we can build an expression for the commutativity of addition on natural numbers, which states that for all natural numbers `a` and `b`, `a + b = b + a`. We first build expressions for natural numbers, then for the proposition of commutativity of addition, and finally for a proof of this proposition using `Nat.add_comm`.

```lean
open Lean Meta in
def natExpr (n : Nat) : Expr :=
  match n with
  | 0 => mkConst ``Nat.zero
  | Nat.succ m => mkApp (mkConst ``Nat.succ) (natExpr m)
```

We next build an expression for the proposition of commutativity of addition:

```lean
open Lean Meta in
def addCommPropExpr (a b : Nat) : MetaM Expr := do
  let aExpr := natExpr a
  let bExpr := natExpr b
  let addAB ←  mkAppM ``Add.add #[aExpr, bExpr]
  let addBA ←  mkAppM ``Add.add #[bExpr, aExpr]
  mkAppM ``Eq #[addAB, addBA]
```

Finally, we can build an expression for a proof of this proposition using `Nat.add_comm`:

```lean
open Lean Meta in
def addCommProofExpr (a b : Nat) : MetaM Expr := do
  let aExpr := natExpr a
  let bExpr := natExpr b
  mkAppM ``Nat.add_comm #[aExpr, bExpr]
```

We can check that the type of this proof expression is indeed the proposition of commutativity of addition. For this, we use the `inferType` function to infer the type of the proof expression and check that it is definitionally equal to the proposition expression using `isDefEq`:

```lean
open Lean Meta in
def checkAddCommProof (a b : Nat) : MetaM Bool := do
  let proofExpr ← addCommProofExpr a b
  let proofType ← inferType proofExpr
  let propExpr ← addCommPropExpr a b
  isDefEq proofType propExpr

#eval checkAddCommProof 2 3 -- true
```
