defmodule MyActor do
  def start_link do
    spawn(__MODULE__, :loop, [])
  end

  def loop do
    receive do
      {:message, msg} ->
        IO.puts("Received message: #{msg}")
        loop()
    end
  end
end

# Start actor process
pid = MyActor.start_link()
# Send a message
send(pid, {:message, "Hello, actor!"})
send(pid, {:message, "Hello, There!"})
