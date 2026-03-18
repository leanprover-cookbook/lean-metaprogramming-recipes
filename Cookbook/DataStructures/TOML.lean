import VersoManual
import Cookbook.Lean
import Lake.Toml
import Cookbook.DataStructures.TOML.ParsingToml
import Cookbook.DataStructures.TOML.EncodingDecodingToml
import Cookbook.DataStructures.TOML.NestedToml
import Cookbook.DataStructures.TOML.ReadWriteTomlFile

open Verso.Genre Manual Cookbook Lean
open Verso.Genre.Manual.InlineLean

#doc (Manual) "TOML" =>

%%%
tag := "toml"
number := false
%%%

::: contributors
:::

`Lake.Toml` is commonly used for configuration files. Lean 4 provides a module for working with `Lake.Toml`. This chapter covers how to create, manipulate, and persist `Lake.Toml` data in Lean.

Working with `Lake.Toml` is not as straightforward as working with {lean}`Json`, but hopefully the following sections will provide you with the necessary tools to handle `Lake.Toml` data effectively in Lean.

{include 1 Cookbook.DataStructures.TOML.ParsingToml}
{include 1 Cookbook.DataStructures.TOML.EncodingDecodingToml}
{include 1 Cookbook.DataStructures.TOML.NestedToml}
{include 1 Cookbook.DataStructures.TOML.ReadWriteTomlFile}
