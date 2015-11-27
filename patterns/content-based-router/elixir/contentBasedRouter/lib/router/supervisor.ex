defmodule ContentBasedRouter.Supervisor do
  def start_link do
    import Supervisor.Spec
      invA = ContentBasedRouter.inventory_name("inventoryA")
      invB = ContentBasedRouter.inventory_name("inventoryB")
      children = [
        worker(ContentBasedRouter.Inventory, ["Inventory A", invA], id: :inventoryA),
        worker(ContentBasedRouter.Inventory, ["Inventory B", invB], id: :inventoryB)
      ]

      Supervisor.start_link(children, strategy: :one_for_one)
  end
end
