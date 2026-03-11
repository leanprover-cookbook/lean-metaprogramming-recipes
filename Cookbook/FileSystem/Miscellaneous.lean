import VersoManual
import Cookbook.Lean

open Verso.Genre Manual
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command
open Cookbook

set_option pp.rawOnError true

#doc (Manual) "Miscellaneous FileSystem Usages" =>

# How to concatenate file paths

%%%
tag := "concatenating-file-paths"
number := false
%%%

{index}[Concatenating file paths]

To concatenate file paths, you can use the `System.FilePath` module. You can create a file path using `System.mkFilePath` and then concatenate it with another path using the `/` operator:

```lean
def concatPaths (base : System.FilePath) (sub : String) : System.FilePath :=
  base / System.mkFilePath [sub]

#eval concatPaths (System.mkFilePath ["home", "user"]) "documents"
#eval System.mkFilePath ["home", "user"] / System.mkFilePath ["documents"]
```

This object you can use like usual since the new path is still a `System.FilePath` object.

# How to get the current working directory

%%%
tag := "getting-current-working-directory"
number := false
%%%

{index}[Getting Current Working Directory]

In order to get the current working directory(cwd), we can use the `IO.currentDir` API.

```lean
def getCurrentWorkingDirectory : IO Unit := do
  let mut cwd ← IO.currentDir
  IO.println s!"Current working directory: {cwd}"
```

# Checking metadata for path

%%%
tag := "checking-metadata-for-path"
number := false
%%%

{index}[Checking Metadata for Path]
{index}[Check File Size]

To check metadata for a path, you can use the `System.FilePath.metadata` function, which can tell you metadata like filetype, size, access time, etc. 

```lean
def checkFileSize (path : System.FilePath) : IO Unit := do
  let metadata ← System.FilePath.metadata path
  IO.println s!"Size of {path}: {metadata.byteSize} bytes"
```
