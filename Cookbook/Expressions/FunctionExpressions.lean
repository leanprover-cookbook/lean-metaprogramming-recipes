import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

set_option pp.rawOnError true

#doc (Manual) "Expressions for (dependent) Functions and Function-types" =>

%%%
tag := "expressions-for-functions"
number := false
-- Optional: If you don't want the recipe to be split into multiple subpages, because of depth.
htmlSplit := .never
%%%

::: contributors
:::

{index}[Expressions for (dependent) Functions and Function-types]

# Defining functions using λ-expressions

Suppose we want to define an expression for the function that takes a natural number `n` and returns `n + n`. It is not advisable to directly build an expression using the constructor `Expr.lam` for lambda expressions, as Lean's hygeine modifies the expression. However, Lean provides convenient ways to introduce local variables and build lambda expressions using `withLocalDeclD` (or `withLocalDecl`) and `mkLambdaFVars`. Here is how we can define the expression for the doubling function:

```lean
open Lean Meta Elab

def doubleExpr : MetaM Expr :=
  withLocalDeclD `n (mkConst ``Nat) fun n => do
    let double ← mkAppM ``Add.add #[n, n]
    mkLambdaFVars #[n] double
```

The function `withLocalDeclD` has three arguments: the name of the local variable, its type (in this case `Nat`), and a continuation function that takes the newly created local variable as an argument. Inside the continuation, we can build the body of the lambda expression using `mkAppM` to apply the addition function to `n` and `n`. Finally, we use `mkLambdaFVars` to create a lambda expression that abstracts over the local variable `n`.

To illustrate how to use this expression, we can write an elaborator (see {ref "elaboration-extending-syntax"}[Elaboration]) that allows us to use it in term position:

```lean
elab "double%" : term =>
  doubleExpr

#eval double% 7 -- 14
```

# Defining dependent functions using Π-types

We can use similar techniques to define expressions for dependent functions and `∀` quantified propositions, which are represented by Π-types in Lean. For example, we can define an expression for the proposition `forall n : Nat, n = n` as follows:

```lean
def rflNatExpr : MetaM Expr :=
  withLocalDeclD `n (mkConst ``Nat) fun n => do
    let eqn ← mkEq n n
    mkForallFVars #[n] eqn

elab "rflnat%" : term => do
  rflNatExpr

example : rflnat% := by -- goal `∀ (n : Nat), n = n`
  simp
```

# Example : Proving the result `∀ (n : Nat), n = n`

Let us put the above two constuctions together to prove the result `∀ (n : Nat), n = n`. We will construct an expression that gives a proof of this result, and then we check that the type of the expression is indeed `∀ (n : Nat), n = n`. This will use the functions `inferType` for inferring the type of an expression and `isDefEq` for checking whether two expressions are definitionally equal.

We define a function `rflNatProof` that constructs an expression for a proof of the result `∀ (n : Nat), n = n` and checks that its type is correct:

```lean
def rflNatExprProof : MetaM Bool := do
  let pf ← withLocalDeclD `n (mkConst ``Nat) fun n => do
    let pfN ← mkAppM ``Eq.refl #[n]
    mkLambdaFVars #[n] pfN
  let pfType ← inferType pf
  isDefEq pfType (← rflNatExpr)

#eval rflNatExprProof -- true
```


# Defining function types using `mkArrow`

In case of non-dependent function types, we can use the `mkArrow` function to build expressions for function types. For example, we can define an expression for the type of functions from `Nat` to `Nat` as follows:

```lean
def natToNatExpr : MetaM Expr :=
  mkArrow (mkConst ``Nat) (mkConst ``Nat)
```
