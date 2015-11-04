require Logger

defmodule Client do
  defstruct name: nil, pid: nil

  @name :rpcserver

  def connect do
    Node.connect(:"rpcserver@tony-M14xR2")
  end

  def subscribe(name) do
    pid = spawn(__MODULE__, :notify, [])

    send :global.whereis_name(@name), {:subscribe, name, pid}

    %Client{name: name, pid: pid}
  end

  def unsubscribe(%Client{name: name, pid: pid}) do
    send server, {:unsubscribe, name}
    send pid, :stop
  end

  def fib(%Client{name: name}, item) do
    send server, {:fib, name, item}
  end

  def notify do
    receive do
      {:fib, items} ->
        Logger.info("Job received: '#{IO.inspect(items, char_lists: false)}'")
        notify
      :stop ->
        Logger.info("stopping")
      _any ->
        notify
    end
  end

  defp server do
    :global.whereis_name(@name)
  end
end
