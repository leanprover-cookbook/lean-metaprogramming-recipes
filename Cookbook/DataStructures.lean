import VersoManual
import Cookbook.Lean
import Cookbook.DataStructures.JSON
import Cookbook.DataStructures.TOML
import Cookbook.DataStructures.HashMap
import Cookbook.DataStructures.Trees

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

#doc (Manual) "Data Structures" =>

%%%
tag := "data-structures"
number := false
%%%

::: contributors
:::

Lean 4 provides several built-in data structures and tools for managing them. This chapter deals with handling data structures with some custom examples of data structures and how to use them. This also covers some common filetypes used for storing and managing data, such as JSON, TOML, etc. and how you can use them in Lean 4.

*Note:* We will avoid covering basic operations on data structures like `Array` and `List` since they are fairly straightforward and multiple resources are available online for them.

{include 1 Cookbook.DataStructures.JSON}

{include 1 Cookbook.DataStructures.TOML}

{include 1 Cookbook.DataStructures.HashMap}

{include 1 Cookbook.DataStructures.Trees}
