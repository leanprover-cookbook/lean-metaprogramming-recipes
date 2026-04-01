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
  "github-copilot[bot]",
  "Not Committed Yet"
]

initialize contributorCache : IO.Ref (HashMap (Option String) (List (String × String))) ← IO.mkRef {}

/--
Adds or updates an author's contribution tally.
Uses a heuristic to prefer full names (with spaces) or longer names for the same email.
-/
def updateTallies (tallies : HashMap String (String × Nat)) (name email : String) (weight : Nat) : HashMap String (String × Nat) :=
  tallies.alter email fun
    | some (n, w) =>
      let isBetter := (name.contains ' ' && !n.contains ' ') || 
                      (name.length > n.length && !(n.contains ' ' && !name.contains ' '))
      some (if isBetter then name else n, w + weight)
    | none => some (name, weight)

/--
Filters out authors who haven't contributed enough "meaningful" characters.
Set threshold to 0 or comment out the call to this function to disable.
-/
def filterMinorContributions (tallies : HashMap String (String × Nat)) (isFile : Bool) : HashMap String (String × Nat) :=
  let threshold := if isFile then 15 else 1
  tallies.toList.foldl (init := {}) fun acc (email, (name, weight)) =>
    if weight >= threshold then acc.insert email (name, weight) else acc

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
  
  let lines := out.stdout.splitOn "\n"
  let mut tallies : HashMap String (String × Nat) := {}

  if file?.isSome then
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
        
        if content.startsWith "%%%" then
          inMetadata := !inMetadata
          continue
        if content.startsWith "#doc" then
          foundHeader := true
          continue
          
        let isMeaningful := 
          foundHeader && 
          !inMetadata && 
          !content.isEmpty && 
          !content.startsWith "import " &&
          !content.startsWith "open " &&
          !content.startsWith "set_option " &&
          !content.startsWith ":::" &&
          !content.startsWith "{index}" &&
          !content.startsWith "{include"
          
        if isMeaningful then
          if currentName != "" && !excludedAuthors.contains currentName && !excludedAuthors.contains currentMail then
            -- Note: Using rawContent.toString.length to get character count of the meaningful line
            tallies := updateTallies tallies currentName currentMail rawContent.toString.length
  else
    for line in lines do
      match line.splitOn "|" with
      | [name, email] => 
        if !excludedAuthors.contains name && !excludedAuthors.contains email then
          tallies := updateTallies tallies name email 1
      | _ => continue

  -- OPTIONAL: Filter out minor contributions (e.g. < 15 meaningful characters)
  -- To disable this restriction, simply comment out the line below.
  tallies := filterMinorContributions tallies file?.isSome

  let mut finalPairs : List (String × String) := []
  let sortedContributors := tallies.toList.toArray.qsort (fun a b => a.2.1.toLower < b.2.1.toLower)
  for (email, (name, _)) in sortedContributors do
    if !finalPairs.any (·.1 == name) then
      finalPairs := finalPairs ++ [(name, email)]

  contributorCache.modify (·.insert file? finalPairs)
  return finalPairs

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
