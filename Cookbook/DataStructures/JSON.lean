import VersoManual
import Cookbook.Lean
import Lean.Data.Json
import Cookbook.DataStructures.JSON.JsonObject
import Cookbook.DataStructures.JSON.ReadWriteJsonFile
import Cookbook.DataStructures.JSON.AccessingModifyingJson
import Cookbook.DataStructures.JSON.Miscellaneous

open Verso.Genre Manual Cookbook Lean
open Verso.Genre.Manual.InlineLean

#doc (Manual) "JSON" =>

%%%
tag := "json"
number := false
%%%

::: contributors
:::

{lean}`Json` is one of the most widely used data formats for representing structured data. Lean 4 provides a robust module for working with {lean}`Json`. You can find it under `import Lean.Data.Json`. This chapter covers how to create, manipulate, and persist {lean}`Json` data in Lean.

*Recipes:*

{include 1 Cookbook.DataStructures.JSON.JsonObject}
{include 1 Cookbook.DataStructures.JSON.AccessingModifyingJson}
{include 1 Cookbook.DataStructures.JSON.ReadWriteJsonFile}
{include 1 Cookbook.DataStructures.JSON.Miscellaneous}
