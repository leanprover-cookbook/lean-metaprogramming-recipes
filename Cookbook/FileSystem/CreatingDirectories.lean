import VersoManual
import Cookbook.Lean

open Verso.Genre Manual
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command
open Cookbook

set_option pp.rawOnError true

#doc (Manual) "Creating directories" =>

%%%
tag := "creating-directories"
number := false
%%%

{index}[Creating directories]

To create directories, we use functions from the `IO.FS.createDir` module. This will create a single directory at the specified path. If the parent directories do not exist, it will throw an error.

```lean
def createDirectory (path : System.FilePath) : IO Unit := do
  try
    IO.FS.createDir path
    IO.println s!"Directory '{path}' created successfully."
  catch e =>
    IO.println s!"Failed to create directory '{path}': {e}"

-- Another way is to check for existance before creating the directory.
def safeCreateDir (path : System.FilePath) : IO Unit := do
  if ← path.pathExists then
    if ! (← path.isDir) then
      throw <| IO.userError s!"Path '{path}' already exists and is not a directory."
    else
      IO.println s!"Directory '{path}' already exists."
  else
    IO.FS.createDirAll path
    IO.println s!"Directory '{path}' created successfully."

```

If you want to create a directory along with any necessary parent directories, you can use `IO.FS.createDirAll`. This will create the entire directory structure specified in the path if it does not already exist.

```lean
def createDirectoryAll (path : System.FilePath) : IO Unit := do
  try
    IO.FS.createDirAll path
    IO.println s!"Directory '{path}' created successfully."
catch e =>
    IO.println s!"Failed to create directory '{path}': {e}"

-- Useful Tip: String value also works here
#eval createDirectory "testDir/subDir"
```

Notice that `String` (like `"testdir/subdir"`) works even though the functions expect a `System.FilePath`. This is because Lean has a *coercion* (an instance of `Coe String System.FilePath`) that automatically converts string literals into file path objects when needed. 
