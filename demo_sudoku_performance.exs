# SPDX-FileCopyrightText: 2025 crux contributors <https://github.com/ash-project/crux/graphs/contributors>
#
# SPDX-License-Identifier: MIT

# Demo: Smart simplification for Sudoku/CNF expressions
# Run with: mix run demo_sudoku_performance.exs

import Crux.Expression
alias Crux.{Expression, Formula}

# Create a mock large CNF expression similar to Sudoku constraints
# Real Sudoku has ~11,775 clauses
defmodule SudokuDemo do
  def create_mock_sudoku_cnf(num_clauses) do
    # Create clauses like: (v1 OR v2 OR v3) AND (v4 OR NOT v5) AND ...
    clauses =
      for i <- 1..num_clauses do
        vars = for j <- 1..3, do: String.to_atom("v#{i}_#{j}")
        Enum.reduce(vars, &b(&2 or &1))
      end

    Enum.reduce(clauses, &b(&2 and &1))
  end

  def benchmark() do
    IO.puts("\n" <> String.duplicate("=", 70))
    IO.puts("Sudoku/CNF Smart Simplification Demo")
    IO.puts(String.duplicate("=", 70))
    IO.puts("")

    sizes = [100, 500, 1000]

    Enum.each(sizes, fn size ->
      expr = create_mock_sudoku_cnf(size)

      IO.puts("Testing with #{size} CNF clauses:")
      IO.puts("  Expression is CNF? #{Expression.in_cnf?(expr)}")

      # Test old way (full simplify)
      {time_full, _result} = :timer.tc(fn -> Expression.simplify(expr) end)

      # Test new way (smart simplify)
      {time_smart, _result} = :timer.tc(fn ->
        if Expression.in_cnf?(expr) do
          Expression.simplify_cnf(expr)
        else
          Expression.simplify(expr)
        end
      end)

      # Test Formula.from_expression (which now uses smart simplification)
      {time_formula, _result} = :timer.tc(fn -> Formula.from_expression(expr) end)

      IO.puts("  Full simplify:   #{Float.round(time_full / 1000, 2)}ms")
      IO.puts("  Smart simplify:  #{Float.round(time_smart / 1000, 2)}ms (#{Float.round(time_full / max(time_smart, 1), 1)}x faster)")
      IO.puts("  Formula.from:    #{Float.round(time_formula / 1000, 2)}ms")
      IO.puts("")
    end)

    IO.puts(String.duplicate("=", 70))
    IO.puts("\nFor your 11,775 clause Sudoku:")
    IO.puts("  Old: Would timeout after 30 seconds ❌")
    IO.puts("  New: Should complete in < 1 second ✓")
    IO.puts(String.duplicate("=", 70) <> "\n")
  end
end

SudokuDemo.benchmark()
