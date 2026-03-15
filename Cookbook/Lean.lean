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

/-- Authors/Emails to always exclude (bots, etc) -/
def excludedAuthors : List String := [
  "github-actions",
  "github-actions[bot]",
  "noreply@github.com",
  "copilot",
  "github-copilot[bot]"
]

/--
Fetches unique authors (Name × Email) for a given file.
Uses `git blame` to ignore people who only added boilerplate or metadata.
-/
def getContributors (file? : Option String) : IO (List (String × String)) := do
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

  if out.exitCode != 0 then return []
  
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

  return pairs

block_extension contributorsBlock (authors : List (String × String)) where
  data := Lean.Json.arr (authors.toArray.map fun (n, e) => Lean.Json.arr #[Lean.Json.str n, Lean.Json.str e])
  traverse _ _ _ := pure none
  toTeX := none
  toHtml :=
    open Verso.Output.Html in
    some fun _ _ _ data _ => do
      let authors : List (String × String) := match data with
        | .arr ks => ks.toList.filterMap fun 
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
    let authors ← liftM <| getContributors (some file)
    let descr ← ``(contributorsBlock $(quote authors))
    ``(Verso.Doc.Block.other $(descr) #[])

@[directive]
def allContributors : DirectiveExpanderOf Unit
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

/--
Recursively appends a contributors block to every Part.
-/
partial def autoAddContributors (p : Part Manual) (file? : Option String := none) : IO (Part Manual) := do
  let currentFile := 
    p.content.findSome? fun 
      | .other descr _ => 
        if descr.name == ``savedLeanBlock then
          match descr.data with
          | .arr #[.str f, _] => some f
          | _ => none
        else none
      | _ => none
  let file := currentFile.getD (file?.getD "")
  
  -- Only add if we found a file and it's not already there
  let mut newContent := p.content
  if file != "" && p.subParts.isEmpty then 
     let authors ← getContributors (some file)
     if !authors.isEmpty then
       let descr : Genre.Block Manual := { 
         name := ``contributorsBlock, 
         data := Lean.Json.arr (authors.toArray.map fun (n, e) => Lean.Json.arr #[Lean.Json.str n, Lean.Json.str e]) 
       }
       newContent := newContent.push (Block.other descr #[])

  let newSubParts ← p.subParts.mapM (autoAddContributors · (some file))
  return { p with 
    content := newContent,
    subParts := newSubParts
  }
