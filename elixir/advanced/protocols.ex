defprotocol Shape do
  @doc "Calculates the area of the shape"
  def area(shape)
end

defmodule Circle do
  defstruct radius: 0
end

defimpl Shape, for: Circle do
  def area(%Circle{radius: r}), do: :math.pi() * r * r
end

defmodule Square do
  defstruct side: 0
end

defimpl Shape, for: Square do
  def area(%Square{side: s}), do: s * s
end

defmodule ProtocolDemo do
  def run do
    shapes = [
      %Circle{radius: 5},
      %Square{side: 10}
    ]

    Enum.each(shapes, fn shape ->
      IO.puts "Area of #{inspect(shape)}: #{Shape.area(shape)}"
    end)
  end
end

ProtocolDemo.run()
