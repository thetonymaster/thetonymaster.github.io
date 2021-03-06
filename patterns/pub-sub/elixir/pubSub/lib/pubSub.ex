defmodule PubSub do
  use GenServer

  @type topic :: binary
  @type message :: binary

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, [{:name, __MODULE__}])
  end

  @spec subscribe(pid, topic) :: :ok
  def subscribe(pid, topic) do
    GenServer.cast(__MODULE__, {:subscribe, %{topic: topic, pid: pid}})
  end

  @spec unsubscribe(pid, topic) :: :ok
  def unsubscribe(pid, topic) do
    GenServer.cast(__MODULE__, {:unsubscribe, %{topic: topic, pid: pid}})
  end

  @spec publish(binary, message) :: :ok
  def publish(topic, message) do
    GenServer.cast(__MODULE__, {:publish, %{topic: topic, message: message}})
  end

  @spec subscribers(topic) :: [pid]
  def subscribers(topic) do
    GenServer.call(__MODULE__, {:subscribers, topic})
  end

  @spec topics() :: [topic]
  def topics() do
    GenServer.call(__MODULE__, {:topics})
  end


  def init(_args) do
    Process.flag(:trap_exit, true)
    {:ok, %{}}
  end

  def handle_cast({:subscribe, %{topic: topic, pid: pid}}, state) do
    Process.link(pid)
    new_state = Map.put(state, topic, [pid | get_subscribers(topic, state)])
    {:noreply, new_state}
  end

  def handle_cast({:unsubscribe, %{topic: topic, pid: pid}}, state) do
    Process.unlink(pid)
    new_list = get_subscribers(topic, state) |> List.delete(pid)
    new_state = Map.put(state, topic, new_list)
    {:noreply, new_state}
  end

  def handle_cast({:publish, %{topic: topic, message: message}}, state) do
    for subscriber <- get_subscribers(topic, state) do
      send(subscriber, message)
    end
    {:noreply, state}
  end

  def handle_call({:subscribers, topic}, _from, state) do
    {:reply, get_subscribers(topic, state), state}
  end

  def handle_call({:topics}, _from, state) do
    {:reply, get_topics(state), state}
  end

  def handle_info({:EXIT, pid, _reason}, state) do
    new_state = get_topics(state) |> delete_pid_from_list(pid, state)
    {:noreply, new_state}
  end

  defp delete_pid_from_list([], _pid, state), do: state
  defp delete_pid_from_list([topic | tail], pid, state) do
    new_list = get_subscribers(topic, state) |> List.delete(pid)
    new_state = Map.put(state, topic, new_list)
    delete_pid_from_list(tail, pid, new_state)
  end

  defp get_subscribers(topic, state) do
    Dict.get(state, topic, [])
  end

  defp get_topics(state) do
    Dict.keys(state)
  end

end
