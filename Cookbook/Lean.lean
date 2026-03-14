/-
Copyright (c) 2025 Lean FRO LLC. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: David Thrane Christiansen
-/

import VersoManual

open Verso.Genre Manual
open Verso.Doc Elab
open Verso.ArgParse
open Lean

namespace Cookbook

/--
Fetches unique authors for a given file (or the whole repo if none) from Git.
Returns a list of names.
-/
def getContributors (file? : Option String) : IO (List String) := do
  let mut args := #["log", "--format=%aN"]
  if let some file := file? then
    args := args ++ #["--follow", "--", file]
  
  let out ← IO.Process.output { cmd := "git", args := args }
  if out.exitCode != 0 then return []
  
  let names := out.stdout.splitOn "\n" 
    |>.map (·.trimAscii.toString) 
    |>.filter (· != "")
  
  -- Deduplicate names while preserving order of first appearance
  return names.foldl (init := []) fun acc name => 
    if acc.contains name then acc else acc ++ [name]

block_extension contributorsBlock (authors : List String) where
  data := Lean.Json.arr (authors.toArray.map (Lean.Json.str ·))
  traverse _ _ _ := pure none
  toTeX := none
  toHtml :=
    open Verso.Output.Html in
    some fun _ _ _ data _ =>
      let authors : List String := match data with
        | .arr ks => ks.toList.filterMap fun | .str s => some s | _ => none
        | _ => []
      if authors.isEmpty then pure .empty
      else
        let list := String.intercalate ", " authors
        pure {{ <div class="contributors"><strong>"Contributors: "</strong> {{text true list}} </div> }}

@[directive]
def contributors : DirectiveExpanderOf Unit
  | (), _ => do
    let file ← getFileName
    let authors ← liftM <| getContributors (some file)
    let descr ← ``(contributorsBlock $(quote authors))
    ``(Verso.Doc.Block.other $(descr) #[])

@[directive]
def hallOfFame : DirectiveExpanderOf Unit
  | (), _ => do
    let authors ← liftM <| getContributors none
    let descr ← ``(contributorsBlock $(quote authors))
    ``(Verso.Doc.Block.other $(descr) #[])

block_extension savedLeanBlock (file : String) (source : String) where
  data := Lean.Json.arr #[Lean.Json.str file, Lean.Json.str source]

  traverse _ _ _ := pure none
  toTeX := none
  toHtml := some fun _ goB _ _ contents =>
    contents.mapM goB

block_extension savedImportBlock (file : String) (source : String) where
  data := Lean.Json.arr #[Lean.Json.str file, Lean.Json.str source]

  traverse _ _ _ := pure none
  toTeX := none
  toHtml := some fun _ _ _ _ _ =>
    pure .empty

/--
Lean code that is saved to the examples file.
-/
@[code_block savedLean]
def savedLean : CodeBlockExpanderOf InlineLean.LeanBlockConfig
  | args, code => do
    let underlying ← InlineLean.lean args code
    let descr ← ``(savedLeanBlock $(quote (← getFileName)) $(quote (code.getString)))
    ``(Verso.Doc.Block.other $(descr) #[$underlying])

/--
An import of some other module, to be located in the saved code. Not rendered.
-/
@[code_block savedImport]
def savedImport : CodeBlockExpanderOf Unit
  | (), code => do
    let descr ← ``(savedImportBlock $(quote (← getFileName)) $(quote (code.getString)))
    ``(Verso.Doc.Block.other $(descr) #[])

/--
Comments to be added as module docstrings to the examples file.
-/
@[code_block savedLean]
def savedComment : CodeBlockExpanderOf Unit
  | (), code => do
    let str := code.getString.trimAsciiEnd.copy
    let comment := s!"/-!\n{str}\n-/"
    let descr ← ``(savedLeanBlock $(quote (← getFileName)) $(quote comment))
    ``(Verso.Doc.Block.other $(descr) #[])
