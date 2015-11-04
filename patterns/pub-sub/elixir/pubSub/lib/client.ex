defmodule Client do

  def start(client_name) do
    spawn(fn -> loop(client_name) end)
  end

  def loop(name) do
    receive do
      message ->
        IO.inspect "#{name} received `#{message}`"
        loop(name)
    end
  end
end
