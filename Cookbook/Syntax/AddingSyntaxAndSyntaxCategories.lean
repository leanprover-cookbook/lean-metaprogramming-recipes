import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Adding syntax (categories)" =>

%%%
tag := "adding-syntax-and-syntax-categories"
number := false
htmlSplit := .never
%%%

::: contributors
:::


{index}[Adding syntax (categories)]

In Lean, we can create syntax categories that are like a bunch of custom grammatical rules bundled into a single object. Lean already includes built-in syntax categories like `term` (for expressions like 1+2), `tactic` (for tactics), and `command` (for commands). The syntax categories fit perfectly into Lean's extensibility framework. They are particularly helpful when implementing Domain Specific Languages (DSLs).

# Declaring a syntax category

%%%
tag := "declaring-a-syntax-category"
number := false

%%%

{index}[Declaring a syntax category]

We can declare a syntax category by using the built-in Lean command `declare_syntax_cat`. The new syntax category is declared as follows:
```lean
declare_syntax_cat mySyntax
```
The new custom rules for the category are added using `syntax <my-syntax-rule> : mySyntax`. When Lean’s parser sees `<my-syntax-rule>`, it parses it according to `mySyntax` rules. For example, you can define an HTML paragraph block in mySyntax like `<p> … </p>` (with a string inside), and it will parse as `mySyntax`.

```lean
syntax "<p>" str "</p>" : mySyntax
```

# DSL for HTML unordered lists

%%%
tag := "dsl-for-html-unordered-lists"
number := false
%%%

{index}[DSL for HTML unordered lists]

In this recipe, we will parse HTML syntax for unordered lists by creating a custom syntax category called `listItem`. We will also write a macro that converts this custom syntax into a standard Lean {name}`List`.

We start by declaring the syntax category `listItem`.

```lean
declare_syntax_cat listItem
```
Next, we will incorporate new parsing rules into the `listItem` syntax category. The standard format for adding a new rule is `syntax <new_rule> : <syntax_category>`.

```lean
syntax "<li>" term "</li>" : listItem
syntax "<ul>" listItem* "</ul>" : term
```
These two rules together form a recursive definition that allows our DSL to handle nested lists. The first rule defines an item inside an HTML list as an `<li> … </li>` block containing any Lean term inside. The second rule states that a `<ul> … </ul>` contains zero or more `listItem` blocks. The `(<syntax_block>)*` notation tells the parser that the `syntax_block` pattern can appear zero or more times.

At last, we want to convert this parsed HTML-style unordered list into a {name}`List` in Lean. For this purpose, we define a helper function `liTerm` to extract the inner term from the syntax of the `listItem` category.

```lean

def liTerm : TSyntax `listItem → MacroM Syntax.Term
| `(listItem| <li> $t </li>) => return t
| _ => Macro.throwUnsupported
```
Let's break down the type signature of `liTerm` function:
- {lean}`` TSyntax `listItem `` ensures that the input to this function strictly belongs to the `listItem` category we just defined.
- The output of `liTerm` is a syntax representing a Lean term ({name}`Syntax.Term`) wrapped inside the {name}`MacroM` monad. The macro expansion needs context that is provided by {name}`MacroM`.
- If the function receives syntax that does not match our expected `<li>` pattern, it safely fails by throwing a {name}`Macro.throwUnsupported` error.

```lean
macro_rules
| `(<ul> $ls:listItem* </ul>) => do
  let ts ←  ls.mapM liTerm
  `([$ts,*])

#eval <ul>
         <li> "Drongo" </li>
         <li> "Sparrow" </li>
      </ul> -- ["Drongo", "Sparrow"]

#eval <ul>
         <li>
            <ul>
                  <li> 42 </li>
            </ul>
         </li>
         <li>
            <ul>
                  <li> 13 </li>
                  <li> 57 </li>
            </ul>
         </li>
      </ul>  -- [[42], [13, 57]]

```

The `macro_rules` command is used to pattern-match on our custom syntax and define exactly how it should be translated (or "expanded") into standard Lean code. In the macro expansion block, `ts` is an array of {name}`Syntax.Term` and we want to output a Lean {name}`List` that contains these terms. This is accomplished by the notation `[$ts, *]`. The brackets `[]` are the Lean {name}`List` literal and `$ts,*` unpacks the `ts` {name}`Array` and puts them into a comma-separated sequence of terms.
