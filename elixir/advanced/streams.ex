# Streams are lazy, composable enumerables.

# 1. Processing a large range without loading it all into memory
1..1_000_000
|> Stream.map(&(&1 * 3))
|> Stream.filter(fn x -> rem(x, 2) == 0 end)
|> Stream.take(5)
|> Enum.to_list()
|> IO.inspect(label: "First 5 even multiples of 3")

# 2. Infinite stream
Stream.iterate(0, &(&1 + 1))
|> Stream.map(fn n -> "Step #{n}" end)
|> Stream.take(3)
|> Enum.to_list()
|> IO.inspect(label: "Infinite iteration (first 3)")

# 3. Reading a file line by line (lazily)
# File.stream!("path/to/file") |> ...
