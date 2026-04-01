import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Deleting a file or Directory" =>

%%%
htmlSplit := .never
%%%

::: contributors
:::

# How to delete a file

%%%
tag := "deleting-a-file"
number := false
%%%

{index}[Deleting a file]

You can delete a file using {lean}`IO.FS.removeFile` function. It returns
an {lean}`IO Unit` which means it performs the action of deleting the file but
does not return any value.

```lean
def deleteFile (path : String) : IO Unit := do
  try
    IO.FS.removeFile path
    IO.println s!"File {path} deleted successfully."
  catch e =>
    IO.println s!"Failed to delete file {path}: {e}"
```
# How to delete a directory

%%%
tag := "delete-a-directory"
number := false
%%%

{index}[Deleting a directory]

You can delete a directory using {lean}`IO.FS.removeDir` function to delete an
empty directory. If you want to delete all the contents inside the directory,
use {lean}`IO.FS.removeDirAll`

```lean
def deleteEmptyDir (path : String) : IO Unit := do
  IO.FS.removeDir path

def deleteDir (path: String) : IO Unit := do
  IO.FS.removeDirAll path
```

Refer to {ref "creating-directories"}[Creating directories] section bottom to
know more about why {lean}`String` works as a file path here.
