defmodule Advanced.Worker do
  use GenServer

  # Client API
  def start_link(initial_state) do
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  def increment() do
    GenServer.cast(__MODULE__, :increment)
  end

  def get_state() do
    GenServer.call(__MODULE__, :get_state)
  end

  # Server Callbacks
  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast(:increment, state) do
    {:noreply, state + 1}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end
end

defmodule Demo do
  def run_demo do
    IO.puts("\n--- 1. Elixir GenServer Demo ---")
    {:ok, _pid} = Advanced.Worker.start_link(0)
    Advanced.Worker.increment()
    Advanced.Worker.increment()
    IO.puts("Current count: #{Advanced.Worker.get_state()}")
  end
end
