import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Miscellaneous FileSystem Usages" =>

# How to concatenate file paths

%%%
tag := "concatenating-file-paths"
number := false
%%%

::: contributors
:::


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

::: contributors
:::


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

::: contributors
:::


{index}[Checking Metadata for Path]
{index}[Check File Size]

To check metadata for a path, you can use the `System.FilePath.metadata` function, which can tell you metadata like filetype, size, access time, etc. 

```lean
def checkFileSize (path : System.FilePath) : IO Unit := do
  let metadata ← System.FilePath.metadata path
  IO.println s!"Size of {path}: {metadata.byteSize} bytes"
```

# Checking if a path is absolute or relative 

%%%
tag := "checking-if-path-is-absolute-or-relative"
number := false
%%%

::: contributors
:::


{index}[Checking if Path is Absolute or Relative]

```lean
def checkAbsolutePath (path₁ path₂: System.FilePath) : IO Unit := do
  if path₁.isAbsolute then
    IO.println s!"{path₁} is an absolute path"
  else
    IO.println s!"{path₁} is not an absolute path"

  if path₂.isRelative then
    IO.println s!"{path₂} is a relative path"
  else
    IO.println s!"{path₂} is not a relative path"
```

# Normalizing a file path

%%%
tag := "normalizing-file-path"
number := false
%%%

::: contributors
:::

To normalize a file path, which means to resolve any `.` or `..` components and remove redundant separators and make it OS-compatible, you can use the `normalize` method.

```lean
def normalizePath (path: System.FilePath) : IO Unit := do
  IO.println s!"Normalized path: {path.normalize}"
```

# Renaming a file path

%%%
tag := "renaming-file-path"
number := false
%%%

::: contributors
:::


{index}[Renaming a File Path]

To rename a file path, you can use the `System.FilePath.rename` function, which takes the old path and the new path as arguments.

```lean
def renameFile (oldPath newPath : System.FilePath): IO Unit := do
  try 
    IO.FS.rename oldPath newPath
    IO.println s!"Renamed {oldPath} to {newPath}"
  catch e =>
    IO.eprintln s!"Failed to rename {oldPath} to {newPath}: {e}"
```
