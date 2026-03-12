import VersoManual
import Cookbook.Lean

open Verso.Genre Manual
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command
open Cookbook

set_option pp.rawOnError true

#doc (Manual) "Adding syntax (categories)" =>

%%%
tag := "adding-syntax-and-syntax-categories"
number := false
%%%

{index}[Adding syntax (categories)]

In Lean, we can create Syntax categories which are like buckets into which you can add custom grammatical rules. Lean already includes built-in syntax categories like `str` (for strings), `num` (for numerals), `term` (for expressions like 1+2). The syntax categories fit in perfectly into Lean's extensibility framework. They are particularly helpful when implementing a Domain Specific Languages (DSLs).

In this recipe, we will try to parse html syntax for unordered lists by creating a custom syntax category called `htmlList` and write a macro that converts this custom syntax into a standard Lean `List`.

We start by declaring the syntax category `htmlList`. This is done using the built-in `declare_syntax_cat` command.

```lean
declare_syntax_cat htmlList
```
Next, we will populate this `htmlList` syntax category with parsing rules. The standard format for adding a new rule is `syntax <new_rule> : <syntax_category>`.

```lean
syntax term : htmlList
syntax "<ul>" ("<li>" htmlList "<\\li>")*
       "<\\ul>" : htmlList
```
The above two rules together form a recursive definition that allows our DSL to handle nested lists.

The first rule says that any standard Lean term is a valid `htmlList` syntax. The second rule states that a `<ul> <\ul>` contains zero or more `<li> <\li>` blocks and inside `<li> <\li>` blocks we again have an `htmlList`. The        `(<syntax_block>)*` notation tells the parser that the `syntax_block` pattern can appear zero or more times.


Atlast, we want to convert this parsed HTML-style unordered list into a `List` in lean. For this purpose, we define a syntax in the `term` category along with a corresponding macro to evaluate it.

```lean
syntax "htmlList%" htmlList : term

macro_rules
| `(htmlList% $t: term) => `($t)
| `(htmlList% <ul> $[<li> $h:htmlList <\li>]* <\ul>) => do
    let items : Array (TSyntax `term) ← h.mapM fun item =>
                     `(htmlList% $item)
    `([$items,*])

#eval htmlList% <ul>
                  <li> <ul> <li> "Apple" <\li> <\ul>  <\li>
                  <li> <ul>
                          <li> "Oranges" <\li>
                          <li> "Grapes" <\li>
                       <\ul> <\li>
                <\ul>  -- [["Apple"], ["Oranges", "Grapes"]]

```

The `macro_rules` command is used to pattern-match on our custom syntax and define exactly how it should be translated (or "expanded") into standard Lean code. `$[ … ]*` gives a way to parse repeating patterns of syntax, by grouping them into an Array. We use this array to recursively define our `macro`.

One can build much more sophisticated syntax in Lean that is sensitive to spacing and indentation.
