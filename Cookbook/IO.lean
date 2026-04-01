import VersoManual
import Cookbook.Lean
import Cookbook.IO.HandlingStdStreams
import Cookbook.IO.CliArgs
import Cookbook.IO.EnvironmentVars
import Cookbook.IO.TimePerformanceMeasure
import Cookbook.IO.TasksAndConcurrency
import Cookbook.IO.Miscellaneous

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

#doc (Manual) "I/O and Processes" =>

%%%
tag := "io"
number := false
%%%

::: contributors
:::


{index}[I/O and Processes]

This chapter covers various topics related to I/O and processes, threads and concurrency in Lean. Lean has great support for running tasks concurrently and provides a powerful API for handling I/O operations. We use the {lean}`IO` monad to perform our operations.


{include 1 Cookbook.IO.HandlingStdStreams}
{include 1 Cookbook.IO.CliArgs}
{include 1 Cookbook.IO.EnvironmentVars}
{include 1 Cookbook.IO.TimePerformanceMeasure}
{include 1 Cookbook.IO.TasksAndConcurrency}
{include 1 Cookbook.IO.Miscellaneous}
