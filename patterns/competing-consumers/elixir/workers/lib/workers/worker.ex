defmodule Workers.Worker do
  use GenServer
  require Logger

  def start_link(id) do
    GenServer.start_link(__MODULE__, [id])
  end

  def start(id) do
    GenServer.start(__MODULE__, [id])
  end

  def init([id]) do
    queue = Workers.work_queue_name()
    GenServer.call(queue, :register)
    GenServer.cast(self, :job)
    Logger.info("[Worker] Started worker with ID #{inspect id}")
    {:ok, {queue , id}}
  end

  def handle_cast(:job, {queue, id} = state ) do
    job = GenServer.call(queue, :dispatch, :infinity)
    res = case job.task do
               f when is_function(f) -> f.([job.payload, id, queue])
             end
    GenServer.cast(self, :job)
    {:noreply, state}
  end

end
