import Bitwise

defmodule Constants do
  @int_max (288230376151711744 - 1) # 2^58 -1
  def int_max do
    @int_max
  end
end

defmodule Fibonacci do
  # Public function to calculate the nth Fibonacci number
  def fib(n) when n >= 0 do
    fib(n, 0, 1)
  end

  # Tail-recursive helper function
  defp fib(0, a, _b), do: a

  defp fib(n, a, b) when n > 0 do
    fib(n - 1, b, (a + b) &&& Constants.int_max)
  end
  
  def run() do
    res = Fibonacci.fib(98765432)
    IO.puts res
  end
end

Fibonacci.run()