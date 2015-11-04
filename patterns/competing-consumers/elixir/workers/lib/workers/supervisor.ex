defmodule Workers.Supervisor do
  require Logger
  def start_link(init_retry_secs, num_workers) do
    import Supervisor.Spec

    work_queue = Workers.work_queue_name()

    children = [
      worker(Workers.WorkQueue, [work_queue], id: :work_queue),
      supervisor(Workers.WorkerSupervisor, [init_retry_secs,
                                            num_workers],
                                            id: :worker_supervisor)
    ]
    Logger.info("Start supervisor")
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
