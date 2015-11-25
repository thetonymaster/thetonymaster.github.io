defmodule Splitter.OrderProcessor do
  use GenServer

  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, [{:name, name}])
  end

  def handle_cast({:order, order}, state) do
    Splitter.Timer.sleep()
    IO.puts "#{inspect order}"
    {:noreply, state}
  end

end
