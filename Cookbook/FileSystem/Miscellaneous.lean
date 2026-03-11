import VersoManual
import Cookbook.Lean

open Verso.Genre Manual
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command
open Cookbook

set_option pp.rawOnError true

#doc (Manual) "Miscellaneous FileSystem Usages" =>

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
