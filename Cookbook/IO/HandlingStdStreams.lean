import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Handling Stdin/Stdout/Stderr Streams" =>

%%%
tag := "handling-std-streams"
number := false
htmlSplit := .never
%%%

::: contributors
:::

# How to Read from Stdin

%%%
tag := "read-stdin"
number := false
%%%

{index}[Reading from Stdin]

To read from `stdin`, you can use the {lean}`IO.FS.Stream.getLine` function, which reads a line of input from the standard input stream and returns it as a {lean}`IO String`.

```lean
def readFromStdin : IO Unit := do
  IO.print "Please enter some input: "
  (← IO.getStdout).flush
  let input ← (← IO.getStdin).getLine
  IO.println s!"You entered: {input.trimAscii}"
```

For more complex input handling, you can use {lean}`IO.getStdin` directly to read characters or the entire content until EOF.

```lean
def readAllFromStdin : IO String := do
  let stdin ← IO.getStdin
  stdin.readToEnd
```

## Fun Example: Interactive Player Input

A common pattern in CLI tools is to request specific types of data (like numbers) and re-prompt the user if the input is invalid.

```lean

/-- Repeatedly prompts the user until a valid natural number
within range is provided. -/
partial def getBoundedNat (prompt : String)
    (low high : Nat) : IO Nat := do
  IO.print s!"{prompt} ({low}-{high}): "
  (← IO.getStdout).flush
  let input ← (← IO.getStdin).getLine
  match input.trimAscii.toNat? with
  | some n =>
    if n >= low && n <= high then return n
    else
      IO.println s!"Error: {n} is out of range."
      getBoundedNat prompt low high
  | none =>
    IO.println "Error: Please enter a valid number."
    getBoundedNat prompt low high

def playerInput : IO Unit := do
  IO.print "Enter character name: "
  (← IO.getStdout).flush
  let name ← (← IO.getStdin).getLine
  
  let age ← getBoundedNat "Enter age" 1 150
  let level ← getBoundedNat "Enter starting level" 1 99
  
  IO.println s!"\nWelcome, {name.trimAscii}!"
  IO.println s!"Stats: Age {age}, Level {level}"
```

In this example, we use `partial` for {lean}`getBoundedNat` because it is a recursive function that might theoretically run forever if the user never provides valid input.

# How to Print to Stdout and Stderr

{index}[Printing to Stdout and Stderr]

You can print to `stdout` and `stderr` using the {name}`IO.println` and {name}`IO.eprintln` functions, respectively. Just like any other language, the `ln` is used to add a newline at the end of the output.

```lean
def printToStdout : IO Unit := do
  IO.print "This is printed to stdout without a newline."
  IO.println "This is printed to stdout with a newline."

def printToStderr : IO Unit := do
  IO.eprint "This is printed to stderr without a newline."
  IO.eprintln "This is printed to stderr with a newline."
```

## Fun Example: Overwriting and Flushing

{index}[Progress Bars and Spinners]
{index}[Overwriting CLI lines]

By default, standard output is often "line-buffered," meaning Lean won't actually show the text in your terminal until it sees a newline (`\n`) or the buffer is full. If you want to show a prompt or a progress message *without* a newline, you should manually *flush* the buffer.

Using the carriage return (`\r`) along with `flush`, we can create effects like progress bars or spinners that update the same line.

```lean
def showProgressBar (n: Nat) : IO Unit := do
  for i in [1:n] do
    let progress := i * 10
    let filled := String.ofList (List.replicate i '#')
    let empty := String.ofList (List.replicate (10-i) '-')
    -- \r moves the cursor back to the
    -- start of the current line
    IO.print s!"\rProgress: [{filled}{empty}] {progress}%"
    (← IO.getStdout).flush
    IO.sleep 200 -- Sleep for 200ms
  IO.println "\nTask Complete!"

def showSpinner (n: Nat) : IO Unit := do
  let spinChars := ["|", "/", "-", "\\"]
  for i in [1:n] do
    let spinChar := spinChars[i % spinChars.length]!
    IO.print s!"\rProcessing... {spinChar}"
    (← IO.getStdout).flush
    IO.sleep 100 -- 100ms is a better speed for a spinner
  IO.print "\rDone!          "
  IO.println ""


-- run `main` to see the progress bar in action like 
-- `lean --run test.lean` in your terminal.
-- def main : IO Unit := do 
--   showProgressBar 10
--   showSpinner 20
```

## Fun Example: Using ANSI Colors and Helpers

{index}[ANSI Colors]

If you want to bold, italics, or add colors to the text, you can do so with ANSI escape codes. Instead of manually typing these codes every time, it's better to define a helper function.

```lean
/-- Wraps a string in ANSI escape codes for coloring. -/
def colorize (msg : String) (colorCode : String) : String :=
  s!"\x1b[{colorCode}m{msg}\x1b[0m"

def printStatus : IO Unit := do
  IO.println s!"Status: {colorize "SUCCESS" "32"}" -- Green
  IO.println s!"Status: {colorize "WARNING" "33"}" -- Yellow
  IO.println s!"Status: {colorize "FAILURE" "31"}" -- Red
  IO.println s!"Status: {colorize "BOLD" "1"}"    -- Bold
```

These are standard ANSI sequences; check [here](https://en.wikipedia.org/wiki/ANSI_escape_code#Colors) for a full reference.
