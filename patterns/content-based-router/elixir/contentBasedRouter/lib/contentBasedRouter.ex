defmodule ContentBasedRouter do
  use GenServer

  def start_link do
    invA = inventory_name("inventoryA")
    invB = inventory_name("inventoryB")
    ContentBasedRouter.Supervisor.start_link
    GenServer.start_link(__MODULE__, %{:inventoryA => invA, :inventoryB => invB}, [{:name, __MODULE__}])
  end

  def send_order(order) do
    GenServer.cast(__MODULE__, {:order, order})
  end

  def handle_cast({:order, order}, state) do
    handle_order(order, state)
    {:noreply, state}
  end

  defp handle_order(%{orderType: :inventoryA} = all, state) do
    GenServer.cast(state[:inventoryA], {:request, all})
  end
  defp handle_order(%{orderType: :inventoryB} = all, state) do
    GenServer.cast(state[:inventoryB], {:request, all})
  end
  defp handle_order(_, _) do
    IO.puts "Unknown inventory system"
  end

  def inventory_name(name) do
    Module.concat([ContentBasedRouter, Supervisor, name])
  end
end
