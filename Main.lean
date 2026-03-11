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
      if which.name == ``Block.savedLean then
        let .arr #[.str fn, .str code] := which.data
          | logError s!"Failed to deserialize saved Lean data {which.data}"
        modify fun saved =>
          saved.alter fn fun prior =>
            let prior := prior.getD ""
            some (prior ++ code ++ "\n")

      if which.name == ``Block.savedImport then
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

def customCodeCss : CssFile where
  filename := "custom-code.css"
  contents :=
    r#" :root {
  --verso-code-keyword-color: #cf222e; /* Muted Red-Purple */
  --verso-code-const-color: #0550ae;   /* Deep Blue */
  --verso-code-var-color: #24292f;     /* Near Black */
  --verso-code-color: #24292f;
}

.hl.lean.block {
  background-color: #f6f8fa;
  padding: 1.5rem 1rem 1rem 1rem;
  border-radius: 8px;
  border: 1px solid #d0d7de;
  position: relative;
  line-height: 1.45;
  font-size: 0.95em;
  margin: 1.5em 0;
}

.hl.lean .literal.string {
  color: #0a3069;
}

.hl.lean .doc-comment, .hl.lean .comment {
  color: #6e7781;
  font-style: italic;
}

.hl.lean .sort {
  color: #953800;
  font-weight: 600;
}

/* Style for the 'Try it!' button */
.try-it-button {
  position: absolute;
  top: 0.5rem;
  right: 0.5rem;
  display: flex;
  align-items: center;
  gap: 4px;
  background-color: #ffffff;
  border: 1px solid #d0d7de;
  border-radius: 6px;
  padding: 3px 10px;
  font-size: 0.75rem;
  font-weight: 500;
  color: #24292f;
  text-decoration: none;
  font-family: var(--verso-structure-font-family);
  transition: all 0.2s cubic-bezier(0.3, 0, 0.5, 1);
  z-index: 10;
  box-shadow: 0 1px 0 rgba(27, 31, 35, 0.04);
}

.try-it-button:hover {
  background-color: #f3f4f6;
  border-color: #0969da;
  color: #0969da;
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
"#

def customJs : JsFile where
  filename := "custom.js"
  contents :=
    r#"
window.addEventListener('load', () => {
  // 1. Add 'Try it!' buttons to code blocks
  const blocks = document.querySelectorAll('code.hl.lean.block');
  blocks.forEach(block => {
    const code = block.innerText;
    const header = "import Lean\nopen Lean Meta Elab Tactic Term Command\n-- If any imports are missing from the default header, please manually add them.\n\n";
    const url = 'https://live.lean-lang.org/#code=' + encodeURIComponent(header + code);
    
    const button = document.createElement('a');
    button.href = url;
    button.target = '_blank';
    button.className = 'try-it-button';
    button.title = 'Open in Lean 4 Web Editor';
    button.innerHTML = `
      <svg width="12" height="12" viewBox="0 0 24 24"><path d="M8 5v14l11-7z"></path></svg>
      <span>Try it!</span>
    `;
    
    block.appendChild(button);
  });
});
"#
  sourceMap? := none

def config : RenderConfig where
  emitTeX := false
  emitHtmlSingle := .no
  emitHtmlMulti := .immediately
  htmlDepth := 2
  extraCssFiles := {customCodeCss}
  extraJsFiles := {customJs}

def main := manualMain (%doc Cookbook) (extraSteps := [buildExercises]) (config := config)
