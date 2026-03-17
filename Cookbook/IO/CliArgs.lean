import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Parsing Command Line Arguments" =>

::: contributors
:::

{index}[Parsing Command Line Arguments]

# Parsing Command Line Arguments

%%%
tag := "parsing-cli-args"
number := false
%%%

In Lean 4, the most common and idiomatic way to access command-line arguments is to define your `main` function to accept a {lean}`List String`. When you run your executable, Lean automatically populates this list with the arguments provided.

```lean
def getCliArgs (args : List String) : IO Unit := do
  IO.println s!"Received {args.length} arguments."
  for arg in args do
    IO.println s!"- {arg}"
```

If you are running a script using `lean --run test.lean arg1 arg2`, then `args` will be `["arg1", "arg2"]`.

# Simple Argument Parsing

For many tools, you just need to check for specific flags or a single input file. Pattern matching on the list of strings is the most idiomatic way to do this.

```lean
def parseArgs (args : List String) : IO Unit := do
  match args with
  | [] | ["--help"] | ["-h"] =>
    IO.println "Usage: mytool [OPTIONS] [FILE]\n"
    IO.println "Options:"
    IO.println "  -h, --help     Show this help"
    IO.println "  -v, --version  Show version"

  | ["--version"] | ["-v"] =>
    IO.println "mytool version 1.0.0"
  | [filename] =>
    IO.println s!"Processing file: {filename}"
  | _ =>
    IO.eprintln "Error: Unknown or too many arguments.
      Use --help for usage."
    IO.Process.exit 1
```

# Recursive Parsing for Options

If your tool takes multiple options in any order, a recursive function that builds up a configuration structure is recommended.

```lean
structure CliConfig where
  verbose : Bool := false
  outputFile : Option String := none
  inputFiles : List String := []
deriving Repr

/-- Recursively parses arguments
  into a CliConfig structure. -/
partial def parseConfig (args : List String)
  (cfg : CliConfig := {}) : CliConfig :=
  match args with
  | [] => cfg
  | "-v" :: rest | "--verbose" :: rest =>
    parseConfig rest { cfg with verbose := true }
  | "-o" :: file :: rest | "--output" :: file :: rest =>
    parseConfig rest { cfg with outputFile := some file }
  | file :: rest =>
    parseConfig rest { cfg with inputFiles :=
      cfg.inputFiles ++ [file] }

def runParser (args : List String) : IO Unit := do
  let cfg := parseConfig args
  IO.println s!"Configuration: {repr cfg}"
```

For a better and more robust tool, refer [Lean4-cli](https://github.com/leanprover/lean4-cli) for a more comprehensive command-line parsing library.
