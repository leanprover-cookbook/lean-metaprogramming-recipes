import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "Time Measurement of Process" =>

%%%
htmlSplit := .never
%%%

::: contributors
:::

# Timing a Process for Performance Measurement

%%%
tag := "time-measurement"
number := false
%%%

{index}[Timing performance]

Lean 4 provides high-precision monotonic clocks for measuring performance and functions for pausing execution.

For benchmarking or performance monitoring, you should use the monotonic clock, which is guaranteed to never go backwards (unlike the system clock).

```lean
def timeTask : IO Unit := do
  let start ← IO.monoMsNow
  -- Simulate some work
  for _ in [1:1000000] do
    let _ := 1 + 1
  let stop ← IO.monoMsNow
  IO.println s!"The task took {stop - start}ms"
```

## High-Precision Timing (Nanoseconds)

If you need even higher precision, you can use {lean}`IO.monoNanosNow`.

```lean
def preciseTiming : IO Unit := do
  let start ← IO.monoNanosNow

  for _ in [1:1000000] do
    let _ := 1 + 1

  let stop ← IO.monoNanosNow
  IO.println s!"Operation took {stop - start} nanoseconds."
```

