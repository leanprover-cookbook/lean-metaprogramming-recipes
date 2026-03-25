import VersoManual
import Cookbook.Lean
import Lean

import Cookbook.DataStructures.Trees.BinaryTree
import Cookbook.DataStructures.Trees.RBTree


open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command
open Std (HashMap)

set_option pp.rawOnError true

#doc (Manual) "Trees" =>

%%%
tag := "trees-intro"
number := false
%%%

::: contributors
:::

Trees are very important data structures in programming. This chapter covers basic definition of trees to specialized tree structures like Red-Black Trees, Binary Search Tree, etc.


{include 1 Cookbook.DataStructures.Trees.BinaryTree}
{include 1 Cookbook.DataStructures.Trees.RBTree}
