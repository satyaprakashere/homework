defmodule MyMacros do
  defmacro say_hello(name) do
    quote do
      IO.puts "Hello from a macro, #{unquote(name)}!"
    end
  end

  defmacro unless(condition, do: block) do
    quote do
      if !unquote(condition), do: unquote(block)
    end
  end
end

defmodule Demo do
  require MyMacros

  def run do
    MyMacros.say_hello("World")
    
    MyMacros.unless 2 + 2 == 5 do
      IO.puts "Math still works!"
    end
  end
end

Demo.run()
