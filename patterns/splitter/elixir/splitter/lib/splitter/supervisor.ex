defmodule Splitter.Supervisor do

  def start_link do
    import Supervisor.Spec

    children = [
      worker(Splitter.Inventory, [Splitter.inventory_name()],id: :inventory),
      worker(Splitter.PaymentProcessor, [Splitter.paymment_processor_name()],id: :paymentprocessor),
      worker(Splitter.OrderProcessor, [Splitter.order_processor_name()],id: :orderprocessor)
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

end
