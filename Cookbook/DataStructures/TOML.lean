import VersoManual
import Cookbook.Lean
import Lake.Toml
import Cookbook.DataStructures.TOML.ParsingToml
import Cookbook.DataStructures.TOML.AccessingModifyingToml
import Cookbook.DataStructures.TOML.NestedToml
import Cookbook.DataStructures.TOML.JsonTomlConversion
import Cookbook.DataStructures.TOML.LakefileToml
import Cookbook.DataStructures.TOML.ReadWriteTomlFile

open Verso.Genre Manual Cookbook Lean
open Verso.Genre.Manual.InlineLean
open Lean Lake Toml

#doc (Manual) "TOML" =>

%%%
tag := "toml"
number := false
%%%

::: contributors
:::

`Lake.Toml` is commonly used for configuration files. Lean 4 provides a module for working with `Lake.Toml`. This chapter covers how to create, manipulate, and persist `Lake.Toml` data in Lean.

Working with TOML in Lean requires understanding two primary types:

*   *Table*: This is essentially a map (dictionary) of keys to values. When you parse a TOML string, you get a {name}`Table`.
*   *Value*: This is an inductive type that can be a string, integer, boolean, array, or another table.
    *   *Why Value is important*: A {lean}`Table` maps keys to values, but those values could be of any type (a string, then a number, then a nested table). In Lean, a map must have a single type for its values. {name}`Value` acts as a "wrapper" or "box" that lets us store different types of data in the same {lean}`Table`.
*   *Syntax* and *.missing*: Most TOML types in Lean carry a {name}`Lean.Syntax` object. This is used to track the exact location of the value in the source file for better error reporting.
    *   *Why .missing is important*: When we create TOML values programmatically (not from a file), there is no "source line" to point to. We use {name}`Lean.Syntax.missing` (or the shorthand *.missing*) to satisfy the type system without providing a fake source location.

Working with `Lake.Toml` is not as straightforward as working with {lean}`Json`, but the following sections provide the necessary tools to handle TOML data effectively.

{include 1 Cookbook.DataStructures.TOML.ParsingToml}
{include 1 Cookbook.DataStructures.TOML.AccessingModifyingToml}
{include 1 Cookbook.DataStructures.TOML.NestedToml}
{include 1 Cookbook.DataStructures.TOML.ReadWriteTomlFile}
{include 1 Cookbook.DataStructures.TOML.JsonTomlConversion}
{include 1 Cookbook.DataStructures.TOML.LakefileToml}
