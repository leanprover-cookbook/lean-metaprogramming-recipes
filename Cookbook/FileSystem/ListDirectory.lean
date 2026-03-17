import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Listing Directory" =>

::: contributors
:::

# Listing contents of a directory

%%%
tag := "list-directory"
number := false
%%%

{index}[Listing contents of a directory]

To list the contents of a directory, we use the {lean}`System.FilePath.readDir` method on a
{lean}`System.FilePath`. This returns an {lean}`Array IO.FS.DirEntry` containing
information about each file and subdirectory.

```lean
def listDirectory (path : System.FilePath) : IO Unit := do
  let entries ← path.readDir
  for entry in entries do
    IO.println entry.fileName
```

Each {lean}`IO.FS.DirEntry` contains the `fileName` (the name of the file or
directory itself) and its full `path`. 

# Recursive directory traversal

%%%
tag := "recursive-directory-traversal"
number := false
%%%

{index}[Recursive directory traversal]
{index}[Walking a directory tree]

If you want to list all files in a directory tree recursively, you can use the
{lean}`System.FilePath.walkDir` method.

*Note*: You can use {lean}`System.FilePath.isDir` method to check if an entry is a directory.

```lean
def listAllFiles (path : System.FilePath) : IO Unit := do
  let allFiles ← path.walkDir
  for file in allFiles do
    IO.println file
```

## Filtering during traversal

{lean}`System.FilePath.walkDir` takes an optional `enter` parameter—a function that
decides whether to recurse into a given subdirectory. This is useful for
skipping large or irrelevant folders like `.git` or `.lake`.

```lean
def listSourceFiles (path : System.FilePath) : IO Unit := do
  /- Only enter directories that aren't
    hidden or build artifacts -/
  let filter (p : System.FilePath) : IO Bool := do
    let name := p.fileName.getD ""
    return name != ".git" && name != ".lake"

  let files ← path.walkDir (enter := filter)
  for f in files do
    -- Only print files with the .lean extension
    if f.extension == some "lean" then
      IO.println f
```
