defmodule ContentBasedRouter.Inventory do
  use GenServer

  def start_link(key, name) do
    GenServer.start_link(__MODULE__, %{key: key, name: name}, name: name)
  end

  def handle_cast({:request, order}, state) do
    IO.puts "#{state[:key]}: #{inspect order} "
    {:noreply, state}
  end

end
