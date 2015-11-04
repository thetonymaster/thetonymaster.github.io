require Logger

defmodule Rpc do
  @name :rpcserver

  def start do
    pid = spawn __MODULE__, :loop, [HashDict.new]
    :global.register_name(@name, pid)
  end

  def loop(subs) do
    receive do
      {:subscribe, name, pid} ->
        Logger.info("#{name} subscribed")
        loop(HashDict.put(subs, name, pid))
      {:unsubscribe, name} ->
        Logger.info("#{name} unsubscribed")
        loop(HashDict.delete(subs, name))
      {:fib, name, items} ->
        Logger.info("#{name} sent a job")
        res = Enum.map(items, &fib &1)
        send(HashDict.get(subs, name), {:fib, res})
        loop(subs)
      _any ->
        loop(subs)
    end
  end


  def fib(0), do: 0
  def fib(1), do: 1
  def fib(2), do: 1

  def fib(n) do
    fib(n, 1, 1)
  end

  defp fib(3, previous, current) do
    current + previous
  end

  defp fib(n, previous, current) do
    fib(n - 1, current, previous + current)
  end


end
