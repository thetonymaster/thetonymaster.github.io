defmodule Workers.WorkQueue do
  require Logger
  use GenServer
  alias Workers.Job

  defmodule State do
    defstruct queue: :queue.new,
              waiting: :queue.new,
              working: HashDict.new
  end

  def start_link (name) do
    Logger.info(["[WorkQueue] started"])
    GenServer.start_link(__MODULE__, %State{}, name: name)
  end

  def handle_cast({:add_task, task, payload}, state) do
    job = %Job{task: task, payload: payload}
    {:noreply, queue_job(job, state)}
  end

  def handle_call(:dispatch, {worker, _msg_ref} = from, state) do
    case :queue.out(state.queue) do
      {{:value, job}, queue} ->
        {:reply, job, %{state | queue: queue, working: Dict.put(state.working, worker, job)}}
      {:empty, _} ->
        {:noreply, queue_worker(from, state)}
    end
  end

  def handle_call(:register, {worker, _msg_ref}, state) do
    Process.monitor(worker)
    {:reply, :ok, state}
  end

  defp queue_job(job, state) do
    case next_alive_worker(state.waiting) do
      {nil, waiting} ->
        %{state | queue: :queue.in(job, state.queue), waiting: waiting}
      {from_worker, waiting} ->
        {worker, _msg_ref} = from_worker
        GenServer.reply(from_worker, job)
        %{state | waiting: waiting, working: Dict.put(state.working, worker, job)}
    end
  end

  defp queue_worker({worker, _msg_ref} = from, state) do
    %{state | waiting: :queue.in(from, state.waiting), working: Dict.delete(state.working, worker)}
  end

  defp next_alive_worker(waiting) do
    case :queue.out(waiting) do
      {{:value, from_worker}, waiting} ->
        {worker, _msg_ref} = from_worker
        if Process.alive? worker do
          {from_worker, waiting}
        else
          next_alive_worker(waiting)
        end
      {:empty, _} ->
        {nil, waiting}
    end
  end

end
