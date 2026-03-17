import VersoManual
import Cookbook.Lean
import Cookbook.DataStructures.JSON

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

#doc (Manual) "Data Structures" =>

%%%
tag := "data-structures"
number := false
%%%

::: contributors
:::

Lean 4 provides several built-in data structures and tools for managing them, like JSON. This chapter deals with handling data structures with some custom examples of data structures and how to use them. 

*Note:* We will avoid covering basic operations on data structures like `Array` and `List` since they are fairly straightforward and multiple resources are available online for them.

{include 1 Cookbook.DataStructures.JSON}
