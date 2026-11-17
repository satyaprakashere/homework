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

# Spawn a process that waits for a message
pid = spawn(fn ->
  receive do
    {:hello, sender} ->
      send(sender, :world)
  end
end)

# Send a message to the process
send(pid, {:hello, self()})

# Wait for the reply
receive do
  :world -> IO.puts("Got reply: world")
end
