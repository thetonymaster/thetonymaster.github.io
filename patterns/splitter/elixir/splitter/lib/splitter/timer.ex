defmodule Splitter.Timer do
  :random.seed(:erlang.now)

  def sleep do
    time = :random.uniform(3000)
    :timer.sleep(time)
  end
end
