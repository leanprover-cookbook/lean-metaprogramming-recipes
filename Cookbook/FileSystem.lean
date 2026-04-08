import VersoManual
import Cookbook.Lean
import Cookbook.FileSystem.ReadingFromFile
import Cookbook.FileSystem.WritingToFile
import Cookbook.FileSystem.RunningAnExternalProgram
import Cookbook.FileSystem.CreatingDirectories
import Cookbook.FileSystem.ListDirectory
import Cookbook.FileSystem.DeletingFileOrDirectory
import Cookbook.FileSystem.ReadWriteJsonl
import Cookbook.FileSystem.Miscellaneous

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

#doc (Manual) "File System" =>

%%%
tag := "file-system"
number := false
%%%

::: contributors
:::

This chapter covers most FileSystem operations, such as reading and writing files, creating directories, listing directory contents, etc. We mainly use the {name}`System.FilePath` type and the `IO.FS` module from the Lean standard library.
This chapter adds recipes for other important file formats which are not Datastructures, such as JSONL, which are commonly used. 

It will be useful to check out {ref "data-structures"}[Data Structures] for File Formats which are Data Structures like JSON, TOML, etc. 
This chapter uses various {lean}`IO` recipes which you can checkout in {ref "io"}[I/O] chapter beforehand.

{include 1 Cookbook.FileSystem.ReadingFromFile}
{include 1 Cookbook.FileSystem.WritingToFile}
{include 1 Cookbook.FileSystem.CreatingDirectories}
{include 1 Cookbook.FileSystem.ListDirectory}
{include 1 Cookbook.FileSystem.DeletingFileOrDirectory}
{include 1 Cookbook.FileSystem.RunningAnExternalProgram}
{include 1 Cookbook.FileSystem.ReadWriteJsonl}
{include 1 Cookbook.FileSystem.Miscellaneous}
