defmodule Splitter.PaymentProcessor do
  use GenServer

  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, [{:name, name}])
  end

  def handle_cast({:payment, payment}, state) do
    Splitter.Timer.sleep()
    IO.puts "#{inspect payment}"
    {:noreply, state}
  end

end
