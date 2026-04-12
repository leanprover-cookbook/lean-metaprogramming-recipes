import VersoManual
import Cookbook.Lean
import Std

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Read and Set File Permissions" =>

%%%
tag := "file-permissions"
number := false
%%%

::: contributors
:::

{index}[Read and Set File Permissions]

# Setting File Permissions

%%%
tag := "setting-file-permissions"
number := false
%%%

{index}[Setting File Permissions]

Writing permissions for files is quite confusing since the API is not quite intuitive. Here is an example of how to set file permissions for a file path using the {lean}`IO.AccessRight`, {lean}`IO.FileRight`, and {lean}`IO.setAccessRights` APIs provided [here](https://lean-lang.org/doc/reference/latest/IO/Files___-File-Handles___-and-Streams/#IO___AccessRight___mk) in the Lean4 reference manual.

```lean
def setFilePermissions (path : System.FilePath) : 
    IO Unit := do
  -- Define specific access rights
  let rw : IO.AccessRight := 
    { read := true, write := true, execution := false } 
  let rOnly : IO.AccessRight := 
    { read := true, write := false, execution := false }

  -- Construct the FileRight structure
  -- Setting User to RW, Group to R, and Other to R
  let myRights : IO.FileRight := {
    user  := rw,
    group := rOnly,
    other := rOnly
  }

  -- Apply the rights to the file
  IO.setAccessRights path myRights
  IO.println s!"Access rights for {path} have been updated."
```

# Reading File Permissions

To read the permissions of a file, Lean does not provide a built-in API for it(if you know one, please let us know!, I could not find one in the documentation). However, we can use the Linux `stat` command to get the permissions in octal format and then convert it to an {lean}`IO.FileRight` structure.

```lean
/-- Convert an octal digit to an IO.AccessRight structure. -/
def octalToAccessRight (c : Char) : IO.AccessRight :=
  let val := c.toString.toNat!
  { 
    read      := val / 4 % 2 == 1,
    write     := val / 2 % 2 == 1,
    execution := val % 2 == 1 
  }

/-- Reads the permissions of a file with `stat` command. -/
def getFilePermissions (path : System.FilePath) :
    IO IO.FileRight := do
  let out ← IO.Process.output {
    cmd  := "stat",
    args := #["-c", "%a", path.toString]
  }

  if out.exitCode != 0 
    then throw <| 
      IO.userError s!"Failed to run stat: {out.stderr}"

  -- The output is usually 3 digits
  let s := out.stdout.trimAscii.toString
  let chars := s.toList

  -- Handle cases with 3 digits (User, Group, Other)
  match chars with
  | [u, g, o] =>
      return {
        user  := octalToAccessRight u,
        group := octalToAccessRight g,
        other := octalToAccessRight o
      }
  | _ => throw <| 
      IO.userError s!"Unexpected permission format: {s}"

def demoPermissions (path : System.FilePath) : IO Unit := do
  -- Get current permissions
  let current ← getFilePermissions path
  IO.println s!"User can read: {current.user.read}"

  -- Modify permissions: Add execution for the user
  let updated := { current with 
    user := { current.user with execution := true },
    group := { current.group with write := true },
    other := { current.other with execution := true },
  }
  
  -- Apply updated permissions
  IO.setAccessRights path updated
  IO.println "Updated user to allow execution."
```

This works nicely on Unix systems, you can modify the commands accordingly. Note that when you are setting permissions, you will only change the permissions mentioned in the {lean}`IO.FileRight` structure, previously set permissions that are not mentioned will remain unchanged.
