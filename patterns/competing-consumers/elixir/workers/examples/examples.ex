require Logger
:random.seed(:erlang.now)
task = fn([time, id, queue]) ->
  :timer.sleep(time)
  Logger.info("[Worker] job finished #{inspect id}")
end
Workers.start_link(1,5)

Enum.each(1..10, fn(_) ->
  time = :random.uniform(3000)
  Workers.collector(task, time)
end)
