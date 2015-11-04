defmodule Workers do
  require Logger
  use GenServer

  def start_link(init_retry_secs, num_workers) do
    import Supervisor.Spec

    id = Module.concat([Workers, Supervisor])
    children = [supervisor(Workers.Supervisor,
                               [init_retry_secs, num_workers],
                               id: id)]
    Supervisor.start_link(children, strategy: :one_for_one)
    GenServer.start_link(__MODULE__, :ok, [{:name, __MODULE__}])
  end

  def collector(fun, payload) do
    GenServer.cast(__MODULE__, {:collector, fun, payload})
  end

  def handle_cast({:collector, fun, payload}, state) do
    work_queue_name()
    |> GenServer.cast({:add_task, fun, payload})
    {:noreply, []}
  end

  def work_queue_name do
    Module.concat([Workers, WorkQueue])
  end

  def worker_supervisor_name do
    Module.concat([Workers, WorkerSupervisor])
  end
end
