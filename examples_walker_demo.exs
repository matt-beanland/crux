# SPDX-FileCopyrightText: 2025 crux contributors <https://github.com/ash-project/crux/graphs/contributors>
#
# SPDX-License-Identifier: MIT

# Walker Strategy Demonstration
# This script demonstrates the differences between prewalk, postwalk, and bottomup

import Crux.Expression
alias Crux.Expression

# Example expression: ((:a and :b) and (:c and :d))
expr = b((:a and :b) and (:c and :d))

IO.puts("\nOriginal Expression:")
IO.puts(inspect(expr))
IO.puts("\n" <> String.duplicate("=", 60))

# PREWALK - Top-down traversal
# Processes parent nodes before children
IO.puts("\n1. PREWALK (Top-Down)")
IO.puts("   Processes nodes from top to bottom, parent before children")
IO.puts(String.duplicate("-", 60))

result_prewalk =
  Expression.prewalk(expr, fn
    {:and, left, right} when is_atom(left) and is_atom(right) ->
      IO.puts("   → Transforming: {:and, #{inspect(left)}, #{inspect(right)}}")
      {:combined, left, right}

    other ->
      other
  end)

IO.puts("\nResult: #{inspect(result_prewalk)}")
IO.puts("Note: Only the leaf AND nodes are transformed")

# POSTWALK - Bottom-up traversal
# Processes children before parent nodes
IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("\n2. POSTWALK (Bottom-Up)")
IO.puts("   Processes nodes from bottom to top, children before parent")
IO.puts(String.duplicate("-", 60))

result_postwalk =
  Expression.postwalk(expr, fn
    {:and, left, right} when is_atom(left) and is_atom(right) ->
      IO.puts("   → Transforming: {:and, #{inspect(left)}, #{inspect(right)}}")
      {:combined, left, right}

    other ->
      other
  end)

IO.puts("\nResult: #{inspect(result_postwalk)}")
IO.puts("Note: Only the leaf AND nodes are transformed, parent sees transformed children")

# BOTTOMUP - Bottom-up with fixpoint iteration
# Like postwalk but reapplies transformation until no changes occur at each node
IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("\n3. BOTTOMUP (Bottom-Up with Fixpoint Iteration)")
IO.puts("   Like postwalk, but reapplies transformation at each node until fixpoint")
IO.puts(String.duplicate("-", 60))

result_bottomup =
  Expression.bottomup(expr, fn
    {:and, left, right} when is_atom(left) and is_atom(right) ->
      IO.puts("   → Transforming atomic AND: {:and, #{inspect(left)}, #{inspect(right)}}")
      {:combined, left, right}

    {:and, {:combined, _, _} = left, {:combined, _, _} = right} ->
      IO.puts("   → Transforming combined AND: {:and, #{inspect(left)}, #{inspect(right)}}")
      {:super_combined, left, right}

    other ->
      other
  end)

IO.puts("\nResult: #{inspect(result_bottomup)}")
IO.puts("Note: Transformation is reapplied, allowing multiple reduction steps")

# Summary
IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("\nSUMMARY:")
IO.puts("  • prewalk:  Good for top-down transformations")
IO.puts("  • postwalk: Good for bottom-up transformations")
IO.puts("  • bottomup: Best for simplifications requiring multiple reduction steps")
IO.puts("              at each node (like normalizing nested operations)")
IO.puts("\n" <> String.duplicate("=", 60))
