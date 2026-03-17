/-
Copyright (c) 2024-2025 Lean FRO LLC. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: David Thrane Christiansen
-/

import Std.Data.HashMap
import VersoManual
import Cookbook

open Verso Doc
open Verso.Genre Manual

open Std (HashMap)

open Cookbook


-- Computes the path of this very `main`, to ensure that examples get names relative to it
open Lean Elab Term Command in
#eval show CommandElabM Unit from do
  let here := (← liftTermElabM (readThe Lean.Core.Context)).fileName
  elabCommand (← `(private def $(mkIdent `mainFileName) : System.FilePath := $(quote here)))

def customCodeCss : CssFile where
  filename := "custom-code.css"
  contents :=
    r##" :root {
  --verso-code-keyword-color: #cf222e; /* Muted Red-Purple */
  --verso-code-const-color: #0550ae;   /* Deep Blue */
  --verso-code-var-color: #24292f;     /* Near Black */
  --verso-code-color: #24292f;
  --verso-code-comment-color: #22863a;
}

.hl.lean.block {
  background-color: #f6f8fa;
  padding: 1rem 1rem 1rem 1rem;
  border-radius: 8px;
  border: 1px solid #d0d7de;
  position: relative;
  line-height: 1.45;
  font-size: 0.95em;
  margin: 1.5em 0;
  color: #22863a;
  font-style: italic;
}

.hl.lean.block .token {
  font-style: normal !important;
}

.hl.lean.block .keyword {
  color: #cf222e !important;
}

.hl.lean.block .const {
  color: #0550ae !important;
}

.hl.lean.block .var {
  color: #24292f !important;
}

.hl.lean.block .literal.string {
  color: #0a3069 !important;
}

.hl.lean.block .sort {
  color: #953800 !important;
  font-weight: 600 !important;
}

/* Style for the code block action container and buttons */
.code-block-actions {
  position: absolute;
  top: 8px;
  right: 8px;
  display: flex;
  flex-direction: row-reverse;
  gap: 8px;
  z-index: 10;
  opacity: 0;
  transition: opacity 0.2s ease;
}

.hl.lean.block:hover .code-block-actions {
  opacity: 1;
}

.try-it-button, .copy-button {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
  background-color: transparent !important;
  border: 1px solid #1f2328 !important;
  border-radius: 6px;
  padding: 3px 10px;
  font-size: 0.75rem;
  font-weight: 500;
  color: #24292f !important; /* Ensure buttons don't inherit comment green */
  font-style: normal !important; /* Ensure buttons don't inherit comment italics */
  text-decoration: none;
  font-family: var(--verso-structure-font-family);
  transition: all 0.2s cubic-bezier(0.3, 0, 0.5, 1);
  box-shadow: 0 1px 0 rgba(27, 31, 35, 0.04);
  cursor: pointer;
  white-space: nowrap;
}

/* Ensure SVG icons inside buttons also don't inherit colors or fills */
.try-it-button svg, .copy-button svg {
  fill: none !important;
  stroke: currentColor;
}

.copy-button {
  padding: 3px 6px;
}

.try-it-button:hover, .copy-button:hover {
  background-color: #f3f4f6;
  border-color: #0969da;
  color: #0969da !important;
  text-decoration: none;
}

/* Style for the 'View Source' link */
.view-source-link {
  display: flex;
  align-items: center;
  gap: 5px;
  color: #6e7781;
  text-decoration: none;
  font-size: 0.85rem;
  margin-left: 1rem;
  transition: color 0.2s;
}

.view-source-link:hover {
  color: #0969da;
}

.view-source-link svg {
  fill: currentColor;
}

.header-title-wrapper {
  display: flex;
  align-items: center;
}

.contributors {
  margin-top: 2rem;
  font-size: 1.05rem;
  color: #1f2328;
  font-family: var(--verso-structure-font-family);
  font-weight: 400;
}

.contributors strong {
  font-weight: 600;
  color: #1f2328;
  display: inline-block;
  margin-right: 4px;
}

.contributor-link {
  color: #1f2328;
  text-decoration: none;
  transition: text-decoration 0.2s;
}

.contributor-link:hover {
  text-decoration: underline;
  color: #0969da;
}

/* Hide specific pages from the landing page TOC section */
.section-toc li:has(a[href*="#building-recipe"]),
.section-toc li:has(a[href*="#cookbook-contributors"]),
/* Hide specific pages from the sidebar's global book chapter list */
.split-toc.book tr:has(a[href*="#building-recipe"]),
.split-toc.book tr:has(a[href*="#cookbook-contributors"]) {
  display: none !important;
}
"##

def customJs : JsFile where
  filename := "custom.js"
  contents :=
    r#"
window.addEventListener('load', () => {
  // 1. Add 'Try it!' and 'Copy' buttons to code blocks
  const blocks = document.querySelectorAll('code.hl.lean.block');
  blocks.forEach(block => {
    const code = block.innerText;
    
    // Create actions container
    const actions = document.createElement('div');
    actions.className = 'code-block-actions';
    
    // Copy button
    const copyButton = document.createElement('button');
    copyButton.className = 'copy-button';
    copyButton.title = 'Copy to clipboard';
    const copyIcon = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="pointer-events: none;"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path></svg>';
    const checkIcon = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"></polyline></svg>';
    copyButton.innerHTML = copyIcon;
    
    copyButton.addEventListener('click', () => {
      navigator.clipboard.writeText(code).then(() => {
        copyButton.innerHTML = checkIcon;
        setTimeout(() => {
          copyButton.innerHTML = copyIcon;
        }, 2000);
      });
    });
    
    // Try it button
    const header = "import Lean\nopen Lean Meta Elab Tactic Term Command\n-- If any imports are missing from the default header, please manually add them.\n\n";
    const url = 'https://live.lean-lang.org/#code=' + encodeURIComponent(header + code);
    const tryItButton = document.createElement('a');
    tryItButton.href = url;
    tryItButton.target = '_blank';
    tryItButton.className = 'try-it-button';
    tryItButton.title = 'Open in Lean 4 Web Editor';
    tryItButton.innerHTML = `
      <svg width="12" height="12" viewBox="0 0 24 24"><path d="M8 5v14l11-7z"></path></svg>
      <span>Try it!</span>
    `;
    
    actions.appendChild(copyButton);
    actions.appendChild(tryItButton);
    block.appendChild(actions);
  });
});
"#
  sourceMap? := none

/--
Extract the marked exercises and example code.
-/
partial def buildExercises (mode : Mode) (logError : String → IO Unit) (cfg : Config) (_state : TraverseState) (text : Part Manual) : IO Unit := do
  let .multi := mode
    | pure ()
  let code := (← part text |>.run {}).snd
  let dest := cfg.destination / "example-code"
  let some mainDir := mainFileName.parent
    | throw <| IO.userError "Can't find directory of `Main.lean`"

  IO.FS.createDirAll <| dest
  for ⟨fn, f⟩ in code do
    -- Make sure the path is relative to that of this one
    if let some fn' := fn.dropPrefix? mainDir.toString then
      let fn' := (fn'.dropWhile (· ∈ System.FilePath.pathSeparators)).copy
      let fn := dest / fn'
      fn.parent.forM IO.FS.createDirAll
      if (← fn.pathExists) then IO.FS.removeFile fn
      IO.FS.writeFile fn f
    else
      logError s!"Couldn't save example code. The path '{fn}' is not underneath '{mainDir}'."

where
  part : Part Manual → StateT (HashMap String String) IO Unit
    | .mk _ _ _ intro subParts => do
      for b in intro do block b
      for p in subParts do part p
  block : Block Manual → StateT (HashMap String String) IO Unit
    | .other which contents => do
      if which.name == ``savedLeanBlock then
        let .arr #[.str fn, .str code] := which.data
          | logError s!"Failed to deserialize saved Lean data {which.data}"
        modify fun saved =>
          saved.alter fn fun prior =>
            let prior := prior.getD ""
            some (prior ++ code ++ "\n")

      if which.name == ``savedImportBlock then
        let .arr #[.str fn, .str code] := which.data
          | logError s!"Failed to deserialize saved Lean import data {which.data}"
        modify fun saved =>
          saved.alter fn fun prior =>
          let prior := prior.getD ""
          some (code.trimAsciiEnd.copy ++ "\n" ++ prior)

      for b in contents do block b
    | .concat bs | .blockquote bs =>
      for b in bs do block b
    | .ol _ lis | .ul lis =>
      for li in lis do
        for b in li.contents do block b
    | .dl dis =>
      for di in dis do
        for b in di.desc do block b
    | .para .. | .code .. => pure ()


def config : RenderConfig where
  emitTeX := false
  emitHtmlSingle := .no
  emitHtmlMulti := .immediately
  htmlDepth := 2
  extraCssFiles := {customCodeCss}
  extraJsFiles := {customJs}
  logo := some "lean_logo.svg"
  extraHead := #[.tag "link" #[("rel", "icon"), ("href", "lean_logo.svg"), ("type", "image/svg+xml")] .empty]
  extraFilesHtml := [("assets/lean_logo.svg", "lean_logo.svg")]

def main (args : List String) : IO UInt32 := do
  manualMain (%doc Cookbook) (options := args) (config := config) (extraSteps := [buildExercises])
