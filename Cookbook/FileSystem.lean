import VersoManual
import Cookbook.FileSystem.ReadingFromFile
import Cookbook.FileSystem.WritingToFile
import Cookbook.FileSystem.RunningAnExternalProgram
import Cookbook.FileSystem.CreatingDirectories
import Cookbook.FileSystem.ListDirectory
import Cookbook.FileSystem.DeletingFileOrDirectory
import Cookbook.FileSystem.ReadWriteJson
import Cookbook.FileSystem.ReadWriteJsonl
import Cookbook.FileSystem.Miscellaneous

open Verso.Genre Manual

#doc (Manual) "File System" =>

%%%
tag := "file-system"
number := false
%%%

This chapter covers most FileSystem operations, such as reading and writing files, creating directories, listing directory contents, etc. We mainly use the `System.FilePath`, `IO.FS` modules from the Lean standard library.

This chapter also adds recipes for other important file formats, such as JSON and JSONL, which are commonly used.

{include 1 Cookbook.FileSystem.ReadingFromFile}
{include 1 Cookbook.FileSystem.WritingToFile}
{include 1 Cookbook.FileSystem.CreatingDirectories}
{include 1 Cookbook.FileSystem.ListDirectory}
{include 1 Cookbook.FileSystem.DeletingFileOrDirectory}
{include 1 Cookbook.FileSystem.RunningAnExternalProgram}
{include 1 Cookbook.FileSystem.ReadWriteJson}
{include 1 Cookbook.FileSystem.ReadWriteJsonl}
{include 1 Cookbook.FileSystem.Miscellaneous}
