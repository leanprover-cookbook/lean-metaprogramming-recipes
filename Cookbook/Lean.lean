/-
Copyright (c) 2025 Lean FRO LLC. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: David Thrane Christiansen
-/

import VersoManual
import Std.Data.HashMap

open Verso.Genre Manual
open Verso.Doc Elab
open Verso.ArgParse
open Lean
open Std (HashMap)

set_option quotPrecheck false

namespace Cookbook

/-- Authors/Emails to always exclude (bots, etc) -/
def excludedAuthors : List String := [
  "github-actions",
  "github-actions[bot]",
  "noreply@github.com",
  "copilot",
  "github-copilot[bot]"
]

initialize contributorCache : IO.Ref (HashMap (Option String) (List (String × String))) ← IO.mkRef {}

/--
Fetches unique authors (Name × Email) for a given file.
Uses `git blame` to ignore people who only added boilerplate or metadata.
-/
def getContributors (file? : Option String) : IO (List (String × String)) := do
  if let some cached := (← contributorCache.get).get? file? then
    return cached

  let out ← match file? with
    | some file => 
      IO.Process.output { 
        cmd := "git", 
        args := #["blame", "--line-porcelain", "--", file] 
      }
    | none => 
      -- For the whole repo, we use log but filter bots
      IO.Process.output { 
        cmd := "git", 
        args := #["log", "--format=%aN|%aE"] 
      }

  if out.exitCode != (0 : UInt32) then return []
  
  let mut pairs : List (String × String) := []
  let lines := out.stdout.splitOn "\n"

  if file?.isSome then
    -- Blame parsing mode: state machine to find meaningful content
    let mut currentName := ""
    let mut currentMail := ""
    let mut foundHeader := false
    let mut inMetadata := false
    
    for line in lines do
      if line.startsWith "author " then
        currentName := (line.drop 7).trimAscii.toString
      else if line.startsWith "author-mail <" then
        currentMail := (line.drop 13).dropEnd 1 |>.trimAscii.toString
      else if line.startsWith "\t" then
        let rawContent := line.drop 1
        let content := rawContent.trimAscii
        
        -- State: Metadata blocks
        if content.startsWith "%%%" then
          inMetadata := !inMetadata
          continue
        
        -- State: Header trigger
        if content.startsWith "#doc" then
          foundHeader := true
          continue
          
        -- Criteria for "meaningful content"
        let isMeaningful := 
          foundHeader && 
          !inMetadata && 
          !content.isEmpty && 
          !content.startsWith "import " &&
          !content.startsWith "open " &&
          !content.startsWith "set_option " &&
          !content.startsWith ":::" && -- Ignore all directive tags (::: contributors, etc)
          !content.startsWith "{index}" &&
          !content.startsWith "{include"
          
        if isMeaningful then
          if currentName != "" && !excludedAuthors.contains currentName && !excludedAuthors.contains currentMail then
            if !pairs.any (·.1 == currentName) then
              pairs := pairs ++ [(currentName, currentMail)]
  else
    -- Log parsing mode (for global index)
    for line in lines do
      match line.splitOn "|" with
      | [name, email] => 
        if !excludedAuthors.contains name && !excludedAuthors.contains email then
          if !pairs.any (·.1 == name) then
            pairs := pairs ++ [(name, email)]
      | _ => continue

  contributorCache.modify (·.insert file? pairs)
  return pairs

block_extension contributorsBlock (authors : List (String × String)) (file : Option String := none) (fetched : Bool := false) where
  data := 
    let authorsJson := authors.toArray.map fun (n, e) => Lean.Json.arr #[Lean.Json.str n, Lean.Json.str e]
    let fileJson := match file with | some f => Lean.Json.str f | none => Lean.Json.null
    Lean.Json.arr #[fileJson, Lean.Json.arr authorsJson, Lean.Json.bool fetched]
  traverse _ data contents := do
    match data with
    | Lean.Json.arr #[fileJson, Lean.Json.arr _, .bool false] =>
        let file := match fileJson with | Lean.Json.str f => some f | _ => none
        let authors ← getContributors file
        let authorsJson' := authors.toArray.map fun (n, e) => Lean.Json.arr #[Lean.Json.str n, Lean.Json.str e]
        let data' := Lean.Json.arr #[fileJson, Lean.Json.arr authorsJson', .bool true]
        return some (Block.other { name := ``contributorsBlock, data := data' } contents)
    | _ => return none
  toTeX := none
  toHtml :=
    open Verso.Output.Html in
    some fun _ _ _ data _ => do
      let authors : List (String × String) := match data with
        | .arr #[_, .arr ks, .bool _] => ks.toList.filterMap fun 
            | .arr #[.str n, .str e] => some (n, e)
            | _ => none
        | _ => []
      if authors.isEmpty then pure .empty
      else
        let repo := "https://github.com/leanprover-cookbook/lean-metaprogramming-recipes"
        let links := authors.map fun (name, email) =>
          let url := s!"{repo}/commits?author={email}"
          .tag "a" #[("href", url), ("class", "contributor-link")] (.text true name)
        
        let mut content := #[.tag "strong" #[] (.text true "Contributors: ")]
        for i in [0:links.length] do
          content := content.push links[i]!
          if i < links.length - 1 then
            content := content.push (.text true ", ")

        pure <| .tag "div" #[("class", "contributors")] <| .seq content

@[directive]
def contributors : DirectiveExpanderOf Unit
  | (), _ => do
    let file ← getFileName
    let authors : List (String × String) := []
    let descr ← ``(contributorsBlock $(quote authors) (some $(quote file)) false)
    ``(Verso.Doc.Block.other $(descr) #[])

@[directive]
def allContributors : DirectiveExpanderOf Unit
  | (), _ => do
    let authors : List (String × String) := []
    let descr ← ``(contributorsBlock $(quote authors) none false)
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
  toHtml := some fun _ goB _ _ contents =>
    contents.mapM goB

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
