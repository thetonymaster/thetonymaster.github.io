defmodule Splitter do
  use GenServer

  def start_link do
    import Supervisor.Spec

    id = Module.concat([Splitter, Supervisor])
    children = [supervisor(Splitter.Supervisor, [], id: id)]
    Supervisor.start_link(children, strategy: :one_for_one)
    GenServer.start_link(__MODULE__, :ok, [{:name, __MODULE__}])
  end

  def get_order(order) do
    GenServer.cast(__MODULE__, {:order, order})
  end

  def handle_cast({:order, order}, state) do
    send_order(order)
    send_payment(order)
    send_inventory(order)
    {:noreply, state}
  end



  def send_order(%{order: order}) do
    order_processor_name()
    |> GenServer.cast({:order, order})
  end
  def send_order(_) do
  end

  def send_payment(%{payment: payment}) do
    paymment_processor_name()
    |> GenServer.cast(:payment, payment)
  end
  def send_payment(_) do
  end

  def send_inventory(%{request: request}) do
    inventory_name()
    |> GenServer.cast(:request, request)
  end
  def send_inventory(_) do
  end

  def inventory_name do
    Module.concat([Splitter, Inventory])
  end

  def order_processor_name do
    Module.concat([Splitter, OrderProcessor])
  end

  def paymment_processor_name do
    Module.concat([Splitter, PaymentProcessor])
  end

end
