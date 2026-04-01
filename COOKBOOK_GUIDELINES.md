# Lean 4 (Meta)programming Cookbook Guidelines

Welcome to the Lean 4 (Meta)programming Cookbook. We appreciate you taking out time and reading through this document, to help everyone code better with Lean4. This document outlines how you should contribute to the cookbook.

Since we contain both programming and metaprogramming recipes, we name the repository "metaprogramming-recipes" to avoid confusion. This is meant to be inclusive of both types of recipes. We use "recipe" to refer to individual entries that solve specific problems, and "chapter" to refer to a collection of related recipes.

## Structure

The cookbook is organized into a hierarchy of chapters and recipes:

- **Main Entry**: `Cookbook.lean` is the front page.
- **Chapter Parent Files**: Located in `Cookbook/` (e.g., `Syntax.lean`, `Expressions.lean`). These define the chapter title and include individual recipes.
- **Recipes**: Individual Lean files located in subdirectories (e.g., `Cookbook/FileSystem/ReadingFromFile.lean`).

## Writing a New Recipe

Writing a new recipe is straightforward. Follow these steps to ensure your contribution is consistent with the existing content:

1. **Consult**: Make sure what you are writing is not already covered and is worth covering or not since we not particularly trying to duplicate other resources unless required. Please consult in discussions before starting.

2. **Create a New File**: Add a `.lean` file in the appropriate subdirectory: `Cookbook/{CHAPTER_NAME}/{RecipeName}.lean`. You may add a new chapter if needed. Please read the Section on Naming Conventions below before naming your file.

3. **Use the Template**: Copy the [TemplateRecipe.lean](./TemplateRecipe.lean) and modify it according to your recipe.

**Note**:

- The `tag` should be your filename and it is Very important to add this for indexing and cross-referencing purposes. It should be in `kebab-case` and should match the file name (without the `.lean` extension) exactly. For example, `ReadingFromFile.lean` should have `tag := "reading-from-file"`.

- The `number := false` option is used to prevent automatic numbering of the recipe, which is generally preferred for individual recipes.

- The `htmlSplit := .never` option is used to keep the recipe in the same HTML file as the chapter without division in pages. This Cookbook uses `htmlDepth := 3`, which means till 3 levels of depth, any `#` header will divide the page into a sub pages. If you donot want to split the recipe into multiple pages and yet have to use `#` headers(since Verso doesn't allow directly using `##`), you can use `htmlSplit := .never` to prevent that.

4. **Writing Recipe Content**: Follow the best practices outlined in this file and see [BuildingRecipe](./Cookbook/BuildingRecipe.lean) for an example of how to write different sections of the recipe.

5. **Link to Chapter**: Add your file to the chapter's parent file to ensure it appears in the chapter and is indexed properly:
   - Open the chapter's parent file (e.g., `Cookbook/{ChapterName}.lean`).
   - Add `import Cookbook.{CHAPTER_NAME}.{RecipeName}` at the top.
   - Include it using `{include 1 Cookbook.{CHAPTER_NAME}.{RecipeName}}`. If you think the recipe should come before other recipes, add it before the existing ones properly, otherwise add it at the end.

Please go through the [BuildingRecipe.lean](./Cookbook/BuildingRecipe.lean) on more details for writing a recipe. See [TemplateRecipe.lean](./TemplateRecipe.lean) for a template to start with.

## Naming Conventions for Chapters, Files and Titles

1. **Chapters**: Use concise broad umbrella terms for chapter names (e.g., `Syntax`, `Widgets`, `Tactics`, etc.) that can encompass multiple related recipes. Avoid overly specific chapter names that only fit one recipe. You can have another submodule inside a chapter if you think it is necessary to group some recipes together but inside a chapter.

2. **Files**: Use concise and technical names for recipe files that reflect the specific problem being solved, but not too verbose. See existing recipes for examples.
   - Avoid using the same name as the chapter to prevent confusion.
   - Use PascalCase(or UpperCamelCase) for file names (e.g., `ReadingFromFile.lean` instead of `reading_from_file.lean` or `Reading-from-File.lean`).
   - Do not use symbols or numbers in file names. Use words to describe them (e.g., `And` instead of `&`, `Zero` instead of `0`, etc.).
   - The file name should be meaningful based on the recipe content. AVoid using generic names or adjectives, like `AnEasyMacro.lean`, `AUsefulTactic.lean`, etc. If you think the recipe is easy or useful, you can index it accordingly or you can mention about that in the description, which the Verso Search will pick up for finding your recipe.

> Certain Exceptions to the above rules exist like a basic `HelloWorldTactic.lean` and `Miscellaneous.lean` recipe can be named to get started. If you would like, please use this as a getting started recipe in a new chapter. You can subinclude multiple recipes in the same file to give basic codes for getting started with a topic.
> `Miscellaneous.lean` can be used for recipes that are trivial, small and not very important to have their own file, but you still want to include them in the chapter. You can have as many miscellaneous recipes as you want in this file.

3. **Titles**: Use descriptive and user-friendly titles for the recipe that can be easily understood by readers. The title should give a clear idea of what the recipe is about without being too technical.
   - Title's first letter of first word should be capitalized, rest is upto you.

## Best Practices

- **Atomic Examples**: Keep each recipe focused on one specific problem.

- **Indexing**: Add index entries for key concepts: `{index}[Recipe Title]`. The title of recipe and index naming should be the similar.

- **Explain the "Why"**: Don't just show code; explain the approach and mention any "Pro-tips", but avoid excessive conceptual explanations unless necessary, by this we mean that refer any other official documentation/books for conceptual explanations, but if no other resources exist, then you can add a brief conceptual explanation but it should be concise and to the point.

- **Cross-Reference**: Link to related recipes using `{ref "tag"}[text]` and text sources like TPIL, FPIL, other Official Lean docs, etc. for conceptual explanations if needed.

- **Run Locally**: Always build your changes locally:

```bash
lake build lean-cookbook
lake exe lean-cookbook
```

To see what the recipe and cookbook will look like, you can go to `lean-metaprogramming-recipes/_out/html-multi/index.html` (you should have it locally) after running the above command, and check the html file to see how it looks. The `html-multi` directory contains the output of the documentation build, and you can traverse it to see html of individual recipes and chapters as well.

- _No AI Slop_. Please write the content yourself. Since this is meant for you to write code easily, the more AI Slop there is (with complicated jargon and less precise explanations), the less useful it will be. If you need help, ask in discussions or reach out on Lean zulip.

## Building and Previewing

The output will be in `_out/html-multi`. You can serve it locally using any static file server (e.g., `python3 -m http.server -d _out/html-multi`).

## Troubleshooting "INTERNAL PANIC"

If `lake exe` panics with `executed 'sorry'`:

1. Check your `+error` blocks. Ensure the error message matches the Lean output **perfectly**.
2. Ensure every `+error` block has a `(name := ...)` argument.
3. If all else fails, remove the `+error` or `leanOutput` and use a standard code block until the mismatch

## Contributor Acknowledgment

We acknowledge and appreciate the contributions of all contributors to this cookbook. Thank you so much! We add at the top of the recipe the name of the contributor and a link to the commits pushed on the repository by the contributor, so that they can get credit for their work. However, we do not put the name of the contributor which only involve administrative work like import fix, better index name, an extra empty line, small typos. etc. We only put the name of the contributor who contributed to the content of the recipe, like writing code, writing explanations, adding references, etc.

**Why this is Done?** This is a similar idea that Mathlib has -

```
Regarding the list of authors: We don't have strict rules on what contributions qualify for inclusion there. The general idea is that the people listed there should be the ones we would reach out to if we had questions about the design or development of the Lean code.
```

We would like to follow the similar idea. That's all.

If you are worried about I am only fixing a small typo, but I donot want to get added to the list of contributors, we have set a limit of `15` characters, which if exceeded in 1 commit, you will get added. This threshold is arbitrary and good enough hopefully to not add people who fix typos. Again, this is only for above mentioned reason and for our convenience.

> This was added in [#15](https://github.com/leanprover-cookbook/lean-metaprogramming-recipes/pull/15) and hence the 15 character limit :-)

**Do I add my Name somewhere?**

No, this is automatically done using by picking up the contributor's name using `git` and since it uses the history of the file, it will not only pick up the name of the actual authors, but people who did administrative work as mentioned above won't be added. This makes it harder to find to tag the actual authors for any questions or clarifications for the recipe. But we do give credit to everyone whoever has even a single commit, in `Cookbook Contributors` section linked on the front page. Since we use `git` history to pick up the contributor's name, you donot add the name of the contributor manually in the recipe anywhere, and it's automatically picked up and added to the recipe.
is found.
