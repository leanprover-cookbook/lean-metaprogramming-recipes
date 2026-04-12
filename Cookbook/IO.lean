import VersoManual
import Cookbook.Lean
import Cookbook.IO.HandlingStdStreams
import Cookbook.IO.CliArgs
import Cookbook.IO.TimePerformanceMeasure
import Cookbook.IO.SleepingProcess
import Cookbook.IO.ProcessInterrupt
import Cookbook.IO.Miscellaneous
import Cookbook.IO.SpawningChildProcess
import Cookbook.IO.RunningTasksInParallel
import Cookbook.IO.SpawningTasks

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

In Lean, it is important to understand the difference in Process, Threads and Tasks. When you spawn a child process, Lean gives you a handle to the OS process. When you spawn an internal computation, Lean gives you a {lean}`Task`. Hence {lean}`Task` is not a schedulable entity at the OS level.

*Recipes:*

{include 1 Cookbook.IO.HandlingStdStreams}
{include 1 Cookbook.IO.CliArgs}
{include 1 Cookbook.IO.SpawningChildProcess}
{include 1 Cookbook.IO.SpawningTasks}
{include 1 Cookbook.IO.RunningTasksInParallel}
{include 1 Cookbook.IO.SleepingProcess}
{include 1 Cookbook.IO.ProcessInterrupt}
{include 1 Cookbook.IO.TimePerformanceMeasure}
{include 1 Cookbook.IO.Miscellaneous}
