import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean
open Std Lean Meta Elab Tactic

set_option pp.rawOnError true

#doc (Manual) "Environment Extensions and Attributes" =>

%%%
tag := "environment-extensions-and-attributes"
number := false
htmlSplit := .never
%%%

::: contributors
:::

{index}[Environment Extensions and Attributes]

# Environment Extensions and Attributes

Lean allows persistence across files and sessions, and even in imported compiled code, by using _Environment extensions_. A common application of environment extensions is for implementing attributes like `@[simp]` and `@[grind]`. In this chapter we give recipes for defining environment extensions and attributes, with the attribute serving as an example.

Specifically, we implement a tactic `distribute` that tries to apply all lemmas tagged with the `@[distribute]` attribute. We first make an environment extension to store the lemmas tagged with `@[distribute]`, and then we define the `@[distribute]` attribute to add lemmas to this environment extension. Finally, we implement the `distribute` tactic that retrieves the lemmas from the environment extension and applies them.

## Environment Extension

There are a few different types of environment extensions, of which we will use the {lean}`SimpleScopedEnvExtension`. The `SimpleScopedEnvExtension` takes two type parameters: the type of entries to be stored in the environment extension, and the type of state that is maintained by the environment extension. "Scoped" means that we can scope to a namespace or to the local scope of a section.

In our case, we want to store lemmas tagged with `@[distribute]`, so the type of entries is `Name` (the name of the lemma), and we want to maintain an array of these lemmas as state, so the type of state is `Array Name`.

```lean
initialize distributeExt :
    SimpleScopedEnvExtension Name (Array Name) ←
  registerSimpleScopedEnvExtension {
    addEntry := fun m n =>
        m.push n
    initial := #[]
  }
```

Once we have defined the environment extension, we can use the `add` function to add entries to the environment extension, and the `getState` function to retrieve the state of the environment extension given an environment.

```lean
#check distributeExt.add
#check distributeExt.getState

def distributeLemmas : MetaM (Array Name) := do
  let env ← getEnv
  return distributeExt.getState env
```


## Attribute

As with environment extensions, there are a few different types of attributes. We will use `registerBuiltinAttribute` to define the `@[distribute]` attribute. The following code defines the `@[distribute]` attribute and specifies that when a lemma is tagged with `@[distribute]`, it should be added to the `distributeExt` environment extension.

```lean
namespace Distribute
initialize registerBuiltinAttribute {
  name := `distribute
  descr := "Lemmas to be used in the distribute tactic"
  add := fun decl _stx kind =>
    distributeExt.add decl kind
}
end Distribute
open Distribute
```

## Tactic

Finally, we implement the `distribute` tactic that retrieves the lemmas from the environment extension and applies them. We use the `apply` tactic to apply each lemma to the goal.

```lean
elab "distribute" : tactic => do
  let lemmas ← distributeLemmas
  for lemma in lemmas do
    let lemmaIdent := mkIdent lemma
    try
      let tac ← `(tactic|rw [$lemmaIdent:ident])
      evalTactic tac
      return
    catch _ =>
      continue
```

We cannot tag or use attributes in the same file where they are initialized, so we have to split the code into two files. In the next recipe {ref "environment-extensions-and-attributes-example"}[Environment Extensions and Attributes: Example], we show how to use the `@[distribute]` attribute and the `distribute` tactic.
