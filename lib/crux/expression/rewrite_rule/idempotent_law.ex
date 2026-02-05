# SPDX-FileCopyrightText: 2025 crux contributors <https://github.com/ash-project/crux/graphs/contributors>
#
# SPDX-License-Identifier: MIT

# credo:disable-for-this-file Credo.Check.Warning.BoolOperationOnSameValues
defmodule Crux.Expression.RewriteRule.IdempotentLaw do
  @moduledoc """
  Rewrite rule that applies idempotent laws to simplify expressions.

  Optimized to gather limited depth instead of entire subtrees.
  """

  use Crux.Expression.RewriteRule

  @impl Crux.Expression.RewriteRule
  def needs_reapplication?, do: true

  @impl Crux.Expression.RewriteRule
  def walk({_op, left, right}) when left == right do
    left
  end

  def walk({op, left, right}) do
    # Gather up to depth 3 to catch common patterns without full O(n²) blow-up
    items = gather_limited(left, op, gather_limited(right, op, [], 3), 3)

    uniq = Enum.uniq(items)

    case uniq do
      [single] ->
        single

      multiple when length(multiple) < length(items) ->
        # Had duplicates - rebuild left-associated
        Enum.reduce(multiple, fn item, acc -> {op, acc, item} end)

      _multiple ->
        # No duplicates
        {op, left, right}
    end
  end

  def walk(other), do: other

  # Gather with limited depth to avoid O(n²) for huge expressions
  defp gather_limited({op, left, right}, op, cont, depth) when depth > 0 do
    gather_limited(left, op, gather_limited(right, op, cont, depth - 1), depth - 1)
  end

  defp gather_limited(term, _op, cont, _depth) do
    [term | cont]
  end
end
