defmodule Fibonacci do
  # Public function to calculate the nth Fibonacci number
  def fib(n) when n >= 0 do
    fib(n, 0, 1)
  end

  # Tail-recursive helper function
  defp fib(0, a, _b), do: a

  defp fib(n, a, b) when n > 0 do
    fib(n - 1, b, a + b)
  end
end

IO.puts(Fibonacci.fib(10))