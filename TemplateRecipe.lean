import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

set_option pp.rawOnError true

#doc (Manual) "title" =>

%%%
tag := "similar-to-title"
number := false
-- Optional: If you don't want the recipe to be split into multiple subpages, because of depth.
htmlSplit := .never 
%%%

::: contributors
:::

{index}[Similar to Tag/Title]

# Your recipe subheaders, etc

%%%
tag := "a-different-tag-if-needed"
number := false
%%%

{index}[Different Index if Needed]

Write here about your recipe...

```lean
def exampleRecipe (args : String) : IO Unit :=
  -- your recipe implementation here
  IO.println s!"This is a template recipe! {args}"
```

Some explanation about the recipe, how to use it, why the `Type` used is important, explain to a kid, but don't go into too much theory, just enough to understand the recipe. Refer other sources if needed.

Happy cooking Lean4 recipes!
