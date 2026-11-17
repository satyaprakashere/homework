# Agents provide a simple way to manage state.
{:ok, agent} = Agent.start_link(fn -> [] end)

Agent.update(agent, fn list -> ["item1" | list] end)
Agent.update(agent, fn list -> ["item2" | list] end)

items = Agent.get(agent, & &1)
IO.inspect(items, label: "Agent state")

Agent.stop(agent)

# Tasks are used for asynchronous execution.
task = Task.async(fn ->
  Process.sleep(100) # Simulate work
  "Result from background task"
end)

# Do other work...
IO.puts "Main process continues..."

result = Task.await(task)
IO.puts "Task finished: #{result}"
