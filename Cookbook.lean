import VersoManual
import Cookbook.Lean

import Cookbook.Overview
import Cookbook.Expressions
import Cookbook.Syntax
import Cookbook.FileSystem
import Cookbook.DataStructures
import Cookbook.IO
import Cookbook.Tactics
import Cookbook.Index
import Cookbook.BuildingRecipe
import Cookbook.Elaboration
import Cookbook.Infoview
import Cookbook.CookbookContributors

open Verso.Genre Manual
open Verso.Genre.Manual.InlineLean


open Cookbook

set_option pp.rawOnError true

#doc (Manual) "Lean 4 (Meta)programming Cookbook" =>

%%%
tag := "lean-metaprogramming-cookbook"
number := false
%%%

Welcome to the *Lean 4 (Meta)programming Cookbook*, a collection of recipes and examples for
programming and metaprogramming in Lean4. This cookbook provides a wide range of recipes, from basic to advanced which you can easily understand and integrate in your code.

If want to write metaprogramming code in Lean 4, this is the right
place to find the recipes you need. We have organized the recipes into
different chapters, each focusing on a specific aspect of
metaprogramming in Lean 4.

If you are new to Lean 4, we recommend you to start with the basics
of Lean4 and use this resource to help you get started. You can find
the official documentation and tutorials on the Lean 4 website.

*Important Note*

The recipes in this cookbook are NOT meant to replace other resources like Theorem Proving in Lean, Mathematics in Lean, and other Lean4 references, unless needed for specific topics. This cookbook is meant to cover up the holes which other places doesn't have and are more programming oriented. We may link to other resources whenever necessary to avoid duplication of content or to provide additional conceptual context. We recommend you to go through the basics of Lean 4 from those resources and use this cookbook as a reference for specific recipes and examples.

We hope that this resource will be helpful for both beginners
and experienced programmers looking to deepen their understanding of
Lean 4.

*More Information*

Check out [How to build a Recipe](How-to-build-a-Recipe/) to contribute to the cookbook if you want to share your own recipes or examples.

Thanks to all the [contributors(view full list)](Cookbook-Contributors/) who have helped make this cookbook possible.

*Other References*
- [Lean 4 Language Reference](https://lean-lang.org/doc/reference/latest/)
- [Theorem Proving in Lean](https://leanprover.github.io/theorem_proving_in_lean4/)
- [Mathematics in Lean](https://leanprover-community.github.io/mathematics_in_lean/)
- [Mathlib](https://leanprover-community.github.io/mathlib4_docs/)



{include 1 Cookbook.Overview}

{include 1 Cookbook.Infoview}

{include 1 Cookbook.Syntax}

{include 1 Cookbook.Expressions}

{include 1 Cookbook.Elaboration}

{include 1 Cookbook.Tactics}

{include 1 Cookbook.IO}

{include 1 Cookbook.FileSystem}

{include 1 Cookbook.DataStructures}

{include 0 Cookbook.Index}

{include 0 Cookbook.BuildingRecipe}

{include 0 Cookbook.CookbookContributors}
