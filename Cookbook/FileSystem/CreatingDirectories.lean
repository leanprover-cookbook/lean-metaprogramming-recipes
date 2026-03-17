import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Creating directories" =>

%%%
tag := "creating-directories"
number := false
%%%

::: contributors
:::

{index}[Creating directories]

To create directories, we use functions from the {name}`IO.FS.createDir`
module. This will create a single directory at the specified path. If the
parent directories do not exist, it will throw an error.

```lean
def createDirectory (path : System.FilePath) : IO Unit := do
  try
    IO.FS.createDir path
    IO.println s!"Directory '{path}' created successfully."
  catch e =>
    IO.println s!"Failed to create directory '{path}': {e}"

/-- Another way is to check for existance
  before creating the directory. -/
def safeCreateDir (path : System.FilePath) : IO Unit := do
  if ← path.pathExists then
    if ! (← path.isDir) then
      throw <| IO.userError s!"Path '{path}' 
      already exists and is not a directory."
    else
      IO.println s!"Directory '{path}' already exists."
  else
    IO.FS.createDirAll path
    IO.println s!"Directory '{path}' created successfully."

```

If you want to create a directory along with any necessary parent directories,
you can use {name}`IO.FS.createDirAll`. This will create the entire directory
structure specified in the path if it does not already exist.

```lean
def createSubDirAll (path : System.FilePath) : IO Unit := do
  try
    IO.FS.createDirAll path
    IO.println s!"Directory '{path}' created successfully."
catch e =>
    IO.println s!"Failed to create directory '{path}': {e}"

-- Useful Tip: String value also works here
#eval createSubDirAll "testDir/subDir"
```

Notice that {lean}`String` (like `"testdir/subdir"`) works even though the
functions expect a {name}`System.FilePath`. This is because Lean has a
*coercion* (an instance of {lean}`Coe String System.FilePath`) that
automatically converts string literals into file path objects when needed.
 
