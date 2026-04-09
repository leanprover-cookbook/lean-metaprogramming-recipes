import VersoManual
import Cookbook.Lean
import Cookbook.MaintainingState.MutableVariables

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean
open Std

set_option pp.rawOnError true

#doc (Manual) "Mutable Variables: Example" =>

%%%
tag := "mutable-variables"
number := false
htmlSplit := .never
%%%

::: contributors
:::

{index}[Mutable Variables: Example]

# Mutable Variables: Example

Mutable variables defined by `IO.Ref` and `Std.Mutex` cannot be evaluated in the same file where they are defined. Here, we continue the example of computing Catalan numbers from the previous recipe {ref "mutable-variables"}[Mutable Variables across commands] and show how to use mutable variables to preserve the computed values across different commands.

When we initially lookup the cached value of `C(32)`, we get `none` since it has not been computed yet.
```lean
#eval getCatalanCache? 32
```

After we compute `C(32)` using the `catalanCached` function, the value is stored in the cache. When we lookup the cached value of `C(31)`, we get `some 14544636039226909`, which is the correct value of `C(31)`.

```lean
#eval catalanCached 32

#eval getCatalanCache? 31

#eval catalanCached 31
```
