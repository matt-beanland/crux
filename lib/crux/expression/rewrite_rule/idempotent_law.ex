# SPDX-FileCopyrightText: 2025 crux contributors <https://github.com/ash-project/crux/graphs/contributors>
#
# SPDX-License-Identifier: MIT

# credo:disable-for-this-file Credo.Check.Warning.BoolOperationOnSameValues
defmodule Crux.Expression.RewriteRule.IdempotentLaw do
  @moduledoc """
  Rewrite rule that applies idempotent laws to simplify expressions.

  See: https://en.wikipedia.org/wiki/Idempotence

  Applies the transformations:
  - `A AND A = A`
  - `A OR A = A`

  The idempotent laws state that applying the same operation twice
  has the same effect as applying it once.
  """

  use Crux.Expression.RewriteRule

  @impl Crux.Expression.RewriteRule
  def walk({op, left, right}) do
    # Build list in order while avoiding O(n²) concatenation by using accumulators
    list = gather(left, op, gather(right, op, []))

    # Deduplicate in O(n) instead of O(n²) while preserving first-occurrence order
    {uniq, count} = dedup_with_count(list)

    case uniq do
      [single] ->
        single

      multiple ->
        if count == length(uniq) do
          {op, left, right}
        else
          Enum.reduce(multiple, &{op, &2, &1})
        end
    end
  end

  def walk(other), do: other

  # Gather elements using continuation-passing style to avoid list concatenation
  # Builds list from right-to-left, so we gather right first, then left
  defp gather({op, left, right}, op, cont) do
    gather(left, op, gather(right, op, cont))
  end

  defp gather(other, _op, cont) do
    [other | cont]
  end

  # Remove duplicates in O(n) while preserving order and counting originals
  defp dedup_with_count(list) do
    {uniq_reversed, _seen, count} =
      Enum.reduce(list, {[], MapSet.new(), 0}, fn item, {acc, seen, count} ->
        if MapSet.member?(seen, item) do
          # Duplicate found - don't add to result but increment count
          {acc, seen, count + 1}
        else
          # First occurrence - add to result and seen set
          {[item | acc], MapSet.put(seen, item), count + 1}
        end
      end)

    # Reverse to get first-occurrence order
    {Enum.reverse(uniq_reversed), count}
  end
end
