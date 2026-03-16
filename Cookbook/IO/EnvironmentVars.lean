import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Environment Variables" =>

::: contributors
:::

# Reading Environment Variables

%%%
tag := "reading-environment-variables"
number := false
%%%


{index}[Reading Environment Variables]

You can use {lean}`IO.getEnv` to retrieve the value of an environment variable. Since a variable might not be set, it returns an {lean}`Option String`.

```lean
def checkUser : IO Unit := do
  let user? ← IO.getEnv "USER"
  match user? with
  | some name => IO.println s!"Hello, {name}!"
  | none      => IO.println "Could not find USER variable."
```

# Setting Environment Variables for Child Process

%%%
tag := "setting-environment-variables-child-process"
number := false
%%%

{index}[Setting Environment Variables for Child Process]

Setting environment variables for the *current* process is less common in pure Lean code. Usually, you set environment variables when spawning a new child process to configure its environment.

When using {lean}`IO.Process.spawn`, you can pass an `env` array to specify variables for the new process:

```lean
def runWithCustomEnv : IO Unit := do
  let child ← IO.Process.spawn {
    cmd := "printenv",
    args := #["MY_VAR"],
    env := #[("MY_VAR", "1234")]
  }
  let exitCode ← child.wait
  IO.println s!"Process exited with code: {exitCode}"
```

This ensures that `MY_VAR` is available to the child process without affecting the parent process's environment.
