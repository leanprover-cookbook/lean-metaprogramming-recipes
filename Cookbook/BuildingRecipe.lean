import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "How to build a Recipe" =>

%%%
tag := "building-recipe"
number := false
%%%

::: contributors
:::

{index}[How to build a Recipe]

This chapter demonstrates the standard layout and features available for cookbook entries. Make sure to visit the website to see how the documentation is rendered and to get a better sense of how to structure your recipe.
You can use the template recipe  as a starting point.

This cookbook is built using Verso, hence understanding how to write in Verso is essential. Please go through this page to get familiar with writing styled documentation in Verso. You can also refer other recipes for the same or checkout the [Verso Manual](https://verso-user-manual.netlify.app/) for more detailed information.

A typical recipe should have the following structure:
1. A simple readable title that clearly indicates the problem being solved.
2. An introduction that gives a brief overview of the problem and the solution.
3. A code snippet that demonstrates the solution.
4. Any explanation required or referencing other resources for further reading.
5. Any more follow up usecases of this solution in a subsection, for example, for reading a file, you can also mention on how to read a JSON, CSV, etc. filetypes. No need for another recipe for each filetype. Please do add Tags and Index to each of the subheader for easy referencing.
6. Please do mention any other debugging tips, expected errors, further usage of the solution, etc.

You can find this template in the repository [here](https://github.com/leanprover-cookbook/lean-metaprogramming-recipes/blob/main/TemplateRecipe.lean).

# Adding Sections

Use the `#` symbol for top-level section like below. Each chapter should start with a clear problem statement and a summary of the solution. Just like `Introduction` here.

You can use `##` for subheaders to organize your content into sections. You can use `*` for a bolding - *Like this*.

## Metadata and Tagging

Inside each header/subheader you can define metadata like this-

```
%%%
tag := "my-tag"
number := false
htmlSplit := .never
%%%
```

This way, you can refer to this section later using the tag.

*How to get the link to the tag?* - You can find the tag in the URL when you navigate to that section on the website after clicking on the header.

- *Note 1*: The `htmlSplit := .never` is Optional and use only if you want to prevent the section from being split across multiple pages. Since this cookbook is built using Verso with `htmlDepth := 3`, till 3rd level of depth isn't reached, a `#` header will split the page into a subpage instead of keeping it in the same page. Thus to be sure you don't want any such breaking of page, add this line in your metadata.

- *Note 2*: We use `number := false` to enforce that no numbering shuold happen since this cookbook is not particularly meant to be read in a linear order. It is meant to be read as a reference guide and readers can go where they want independent of previous chapters.


# Formatting Text

A detailed information on formatting on Verso is explained at [Verso Markup](https://verso-user-manual.netlify.app/Verso-Markup/?terms=--verso#verso-markup) page. Read below for a consise summary of some of the most commonly used formatting options.

## Adding inline Lean Code

You can include Lean code that is elaborated directly within the document. This is useful for small snippets. Please note that your lean code should follow the Lean syntax conventions of naming, casing variables, etc.

```lean
def helloCookbook := "Welcome!"

#eval helloCookbook
```

## Interactive Symbols

To provide interactive features like hovers and type information for Lean symbols in your text, use the `{name}` and `{lean}` roles instead of plain backticks.

*   *`{lean}`* `` `term` ``: Elaborates a full Lean expression (like `` {lean}`1 + 2` ``). It provides interactive info for every token in the expression.

*   *`{name}`* `` `ConstName` ``: Resolves a global constant (like `` {name}`Nat` ``). It shows the docstring and type signature on hover.

*Syntax:*

The type `` {name}`Nat` `` is used for numbers. 
An example term is `` {lean}`[1, 2].map (· + 1)` ``.

*Effect:*

When rendered, hovering over {name}`Nat` will show its definition and docstring. Hovering over parts of {lean}`[1, 2].map (· + 1)` will show types for the list, the map function, and the lambda abstraction.

## Errors and Warnings

Expected errors must be explicitly marked with `+error`. If the error message does not match exactly, the documentation build may fail.


## Cross-References

You can link to other sections using their tags like: `{ref "tag-name"}[link text]`. This would give effect as: {ref "building-recipe"}[Back to top].

## Marginal Notes

You can add marginal notes that appear in the side margin like: `{margin}[Marginal text]`. This would give effect as: {margin}[Marginal notes are great for extra context.]

## Indexing

To add a term to the index, use the `{index}` role. This will not render anything in the text but will add the entry to the generated index, like: `{index}[Term to index]`


# Contributor Section

Every page at the top contains the contributors section, just below the `#doc (Manual) "Title" =>` line. These are automatically picked up from `git` and you don't have to do anything. Details on who is acknowledged as a contributor for that page is mentioned in [COOKBOOK\_GUIDELINES](../COOKBOOK_GUIDELINES.md) file. 

Note that only once at the top of the page, you need to add the line below to show the contributors section.

```
::: contributors
:::
```

Verso follows a strict rule of where you can place the `:::` block. You cannot place this block above `%%%` block, it has to be below it. Hence it is advised to keep this contributor block at the top of the page, as mentioned above. If you have `%%%` block below `#doc` line, then contributor block should be below the `%%%` block. See other recipes for examples.
