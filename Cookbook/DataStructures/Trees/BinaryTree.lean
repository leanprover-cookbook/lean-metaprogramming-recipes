import VersoManual
import Cookbook.Lean
import Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command
open Std (HashMap)

set_option pp.rawOnError true
set_option linter.unusedVariables false

#doc (Manual) "Binary Tree" =>

%%%
tag := "binary-tree"
number := false
htmlSplit := .never
%%%

::: contributors
:::

Binary trees are a fundamental data structure commonly used in various applications. They consist of nodes, where each node has at most two children, referred to as the left and right child. Binary trees are often used to implement binary search trees, heaps, and expression trees an

# Defining Binary Tree

%%%
tag := "binary-tree-definition"
number := false
%%%

{index}[Defining Binary Tree]

Since a binary tree is an inductive data structure where the child itself is another binary tree, we define it using an inductive type. We use `Option` to represent the possibility of a child being absent (i.e., a leaf node). For various applications, the nodes may carry a value and a weight, so we include those in the definition as well.

```lean
inductive BinaryTree (α : Type) where
  | Leaf (val : α) (weight : Nat)
  | Node (val : α) (weight : Nat) 
          (left : Option (BinaryTree α)) 
          (right : Option (BinaryTree α))
deriving Inhabited, Repr
```

- For recursive data structures, we often need to define a custom {lean}`BEq` instance if we want to check for equality between two trees. Check out [Lean Reference Recursive Instance](https://lean-lang.org/doc/reference/latest/Type-Classes/Instance-Declarations/#recursive-instances) on how to define `instance BEq` for recursive data structures.

# Operations on Binary Tree

%%%
tag := "binary-tree-operations"
number := false
%%%

{index}[Operations on Binary Tree]

Typically, you need to define recursive functions to perform operations on binary trees, such as searching for a value, inserting a new value, calculating the depth of the tree, etc. Below, we will implement some of these operations.

## Search and Insertion

{index}[Binary Search Tree]

To convert a binary tree into a binary search tree (BST), we need to implement search and insertion operations that maintain the BST property. The search operation checks if a value exists in the tree, while the insertion operation adds a new value with its weight while ensuring the tree satisfies the BST property (left child < parent < right child). We use the {lean}`Ord` typeclass to compare values and maintain the ordering.

```lean
/-- Checks if a value exists in the tree. -/
def contains [Ord α] (v : α) : Option (BinaryTree α) → Bool
  | none => false
  | some (.Leaf val _) => compare v val == .eq
  | some (.Node val _ l r) =>
      match compare v val with
      | .lt => contains v l
      | .gt => contains v r
      | .eq => true

/-- Inserts a value with a weight into the BST. -/
def insert [Ord α] (v : α) (w : Nat) : 
    Option (BinaryTree α) → Option (BinaryTree α)
  | none => some (.Leaf v w)
  | some (.Leaf val weight) =>
      match compare v val with
      | .lt => some 
          (.Node val weight (some (.Leaf v w)) none)
      | .gt => some 
          (.Node val weight none (some (.Leaf v w)))
      | .eq => some (.Leaf v w)
  | some (.Node val weight l r) =>
      match compare v val with
      | .lt => some (.Node val weight (insert v w l) r)
      | .gt => some (.Node val weight l (insert v w r))
      | .eq => some (.Node v w l r)
```

To find the maximum depth of the tree or calculate the total weight of all nodes, we can define recursive functions that traverse the tree and compute the desired values.

```lean
/-- Computes the maximum depth of the tree. -/
def depth {α} : Option (BinaryTree α) → Nat
  | none => 0
  | some (.Leaf ..) => 1
  | some (.Node _ _ l r) => 1 + max (depth l) (depth r)

/-- Calculates the total weight of all nodes in the tree. -/
def totalWeight {α} : Option (BinaryTree α) → Nat
  | none => 0
  | some (.Leaf _ w) => w
  | some (.Node _ w l r) => 
      w + totalWeight l + totalWeight r
```

# List to Binary Tree

%%%
tag := "list-to-binary-tree"
number := false
%%%

{index}[List to Binary Tree]

Often, we get the tree data in the form of a {lean}`List`, and we need to convert it into a binary tree structure. We know that `i`-th element has left child at `2*i + 1` and right child at `2*i + 2`. We convert a sorted list into a balanced tree by selecting the median.

```lean
def listToBinaryTree {α} (xs : List (α × Nat)) : 
    Option (BinaryTree α) :=
  match p:xs with
  | [] => none
  | [(v, w)] => some (.Leaf v w)
  | v₁ :: v₂ :: rest =>
      let midIdx := xs.length / 2
      match h_head: (xs.drop midIdx).head? with
      | some (val, w) =>
          -- needed by Lean to show termination
          have hl: min (xs.length / 2) xs.length < 
            rest.length + 2 := by grind
          let left  := listToBinaryTree (xs.take midIdx)
          let right := 
            listToBinaryTree (xs.drop (midIdx + 1))
          some (.Node val w left right)
      | none => none
termination_by xs.length
```

# Example Usage

We will use the above functions to build a binary tree from a list of values and weights, in an example and perform operations as defined above.

```lean
/-- Pretty prints the binary tree for visualization. -/
def pprintBST {α} [Repr α] : Option (BinaryTree α) → String
  | none => "Empty"
  | some (.Leaf v w) => s!"(Leaf: {repr v} {w})"
  | some (.Node v w l r) => 
      let left := pprintBST l
      let right := pprintBST r
      s!"(Node: {repr v} {w} {left} {right})"

def egBinaryTree : Option (BinaryTree String) :=
  let data := [("A", 1), ("B", 2), ("C", 3), ("D", 4)]
  listToBinaryTree data

#eval pprintBST egBinaryTree
#eval contains "B" egBinaryTree

def updatedTree := insert "E" 5 egBinaryTree
#eval pprintBST updatedTree

#eval depth updatedTree
#eval totalWeight updatedTree
```
