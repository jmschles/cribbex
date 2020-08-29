defmodule Cribbex.Logic.Math do
  def subsets(values) do
    2..length(values)
    |> Enum.flat_map(fn size ->
      combination(size, values)
    end)
  end

  def combination(0, _), do: [[]]
  def combination(_, []), do: []

  def combination(size, [x | rest]) do
    for(y <- combination(size - 1, rest), do: [x | y]) ++ combination(size, rest)
  end
end
