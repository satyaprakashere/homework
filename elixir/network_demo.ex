# network_demo.exs

# 1. Capture in-memory BEAM bytecode
{:module, _mod, receiver_bytecode, _} =
  defmodule NetworkReceiver do
    use GenServer

    def start(opts) do
      GenServer.start(__MODULE__, :ok, opts)
    end

    @impl true
    def init(:ok), do: {:ok, %{messages_received: 0}}

    @impl true
    def handle_call({:deliver_message, text}, _from, state) do
      count = state.messages_received + 1
      IO.puts("\n[RECEIVER @ #{Node.self()}] Received packet: \"#{text}\" (Total received: #{count})")
      {:reply, {:ok, "ACK from receiver node"}, %{state | messages_received: count}}
    end
  end

# 2. Main Orchestrator
defmodule NetworkDemo do
  def run(bytecode) do
    cookie = :secret_demo_cookie
    
    # Ensure Erlang Port Mapper Daemon (epmd) is running
    System.cmd("epmd", ["-daemon"])

    # Start sender node
    {:ok, _} = Node.start(:"sender@127.0.0.1", :longnames)
    Node.set_cookie(cookie)
    IO.puts("[MAIN] Started Sender Node: #{Node.self()}")

    # Spawn receiver node via :peer
    {:ok, peer_pid, receiver_node} =
      :peer.start(%{
        name: :receiver,
        host: ~c"127.0.0.1",
        args: [~c"-setcookie", Atom.to_charlist(cookie)]
      })

    IO.puts("[MAIN] Spawned Receiver Node: #{receiver_node}")

    # 1. Share Elixir stdlib code paths with remote node
    :erpc.call(receiver_node, :code, :add_paths, [:code.get_path()])

    # 2. Inject in-memory BEAM bytecode into remote node
    :erpc.call(receiver_node, :code, :load_binary, [
      NetworkReceiver,
      ~c"NetworkReceiver.beam",
      bytecode
    ])

    # 3. Start GenServer unlinked with local process name :my_receiver_service
    {:ok, _pid} =
      :erpc.call(
        receiver_node,
        NetworkReceiver,
        :start,
        [[name: :my_receiver_service]]
      )

    # 4. Transmit messages targeting {:my_receiver_service, receiver_node}
    send_network_message(receiver_node, "Hello world over the network!")
    send_network_message(receiver_node, "Elixir distribution in a single file!")

    # Cleanup
    :peer.stop(peer_pid)
    IO.puts("\n[MAIN] Remote node stopped. Exiting demo.")
  end

  defp send_network_message(target_node, payload) do
    IO.puts("\n[SENDER @ #{Node.self()}] Transmitting message to #{target_node}...")
    
    # Direct network call using {:registered_name, node} tuple
    response = GenServer.call({:my_receiver_service, target_node}, {:deliver_message, payload})

    IO.puts("[SENDER @ #{Node.self()}] Received response: #{inspect(response)}")
  end
end

NetworkDemo.run(receiver_bytecode)