defmodule Workers.WorkerSupervisor do
  alias Workers.Worker

  def start_link(init_retry_secs, num_workers) do
    import Supervisor.Spec

    children = [
      worker(Worker, [], restart: :transient)
    ]

    opts = [strategy: :simple_one_for_one,
            name: Workers.worker_supervisor_name(),
            max_restarts: num_workers,
            max_seconds: init_retry_secs]

    {:ok, supervisor} = Supervisor.start_link(children, opts)

    Enum.each(1..num_workers, fn(id) ->
      Supervisor.start_child(supervisor, [id])
    end)

    {:ok, supervisor}
  end

end
