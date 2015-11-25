defmodule Splitter.Inventory do
  use GenServer

  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, [{:name, name}])
  end

  def handle_cast({:request, request}, state) do
    Splitter.Timer.sleep()
    IO.puts "#{inspect request}"
    {:noreply, state}
  end

end
