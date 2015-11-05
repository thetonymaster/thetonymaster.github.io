---
layout: post
title:  "Competing Consumers"
date:   2015-11-02 22:09:02
categories: patterns go elixir
comments: true
---
# Competing Consumers

Messages arrive through a message channel, so the natural inclination of the consumer is to process them sequentially. However this can lead to bottlenecks, each message piles up over previous unprocessed messages. This can happen because of multiple messages are sent at once or because or because each message takes a lot time to process.

<script src="/assets/js/processing.min.js"></script>
<canvas data-processing-sources="/assets/processing/workers.pde"></canvas>

One solution can be one application with multiple channels but one channel might become a bottleneck while others sit empty, multiple channels would have the advantage, however, having one consumer enabled processing them concurrently the number of channels would still limit the throughput.

Competing consumers are created to are created to receive messages from a single channel. The messaging system decides to which consumer receives the message, but the consumers compete with each other to be the the one who receives the message.

Each of the consumers processes the message concurrently, so the bottleneck becomes how quickly the the channel can feed the messages. A limited number of consumers can become the bottleneck but increasing the number can help to alleviate this constraint. To run concurrently each consumer must run with its own thread.

A sophisticated messaging system must ensure that each message its only sent one to one consumer, this helps to avoid conflicts if a message is sent to various consumers. If this happens the first message that completes the transaction wins.

This pattern not only can be applied to spread the load in a single application, this can also be used in multiple processes. If one application cannot consume messages fast enough, perhaps multiple applications with  multiple consumers can attack the problem. (Hohpe & Woolf, 2012, p. 502)

## Advantages

- The workload of an application is divided asynchronously/concurrently
- Tasks can be run in parallel
- Can be a scalable solution for high volumes of work
- Is highly available and resilient

## Disadvantages

- It's not easy to separate workload into discrete tasks, or there could be a high degree of dependence between tasks
- If tasks must be performed synchronously, a bottleneck can be created
- It is very hard to perform sequential tasks
(“Competing Consumers Pattern,” n.d.)

# Implementation

## The Problem

1. Create a pool of consumers
2. Generate a random number
3. Simulate work with the random number

### Go Implementation

The first part is to determine how request will be made to the consumers (or workers), this will help to decouple the work request from the work queue to implement different types of requests. For this an interface payload will be used and the method in charge of executing operating over it, so it can be any type like a `struct` or a primitive.

{% highlight go %}
type Request struct {
	Name    string
	Payload interface{}
}

func New(name string, payload interface{}) Request {
	r := Request{
		Name:    name,
		Payload: payload,
	}
	return r
}

func (wr Request) Do() error {
	tm, _ := time.ParseDuration(fmt.Sprintf("%vs", wr.Payload))
	time.Sleep(tm)
	return nil
}

{% endhighlight %}

Next comes the collector, the collector consists of a channel which receives all the work requests, and a method that receives the payload coming from an outside channel and add it to the queue.

{% highlight go %}
func Collector(name string, payload interface{}) {

	work := work.New(name, payload)

	WorkQueue <- work
	fmt.Println("Work request queued")

}
{% endhighlight %}

Now a worker is needed to process all the incoming work requests. A worker has three channels:

{% highlight go %}
type Worker struct {
	ID          int
	Work        chan WorkRequest
	WorkerQueue chan chan WorkRequest
	QuitChan    chan bool
}
{% endhighlight %}

`Work` is where all the work requests are received, `WorkerQueue` is channel of channels, this is how workers "compete" to get the work requests, when a request is received, the `dispatcher` pop the first worker on the queue, then writes on the channel `Channel`. `Quitchan` is used to kill the goroutine. When the processing is done, the worker subscribes again to the `WorkerQueue`. This ensures the message does not processes one or more time.

{% highlight go %}
func (w Worker) Start() {
	go func() {
		for {
			w.WorkerQueue <- w.Work

			select {
			case work := <-w.Work:
				fmt.Printf("Worker %d received work\n", w.ID)
				err := work.Do()
				if err != nil {
					fmt.Println(err.Error())
				}
			case <-w.QuitChan:
				fmt.Printf("worker%d stopping\n", w.ID)
				return
			}
		}
	}()
}
{% endhighlight %}

The dispatcher wraps up the coded written before, it starts a `goroutine` for each of the workers and and initializes the `WorkerQueue` as mentioned before,every time the collector writes on the `WorkQueue`, the first worker is popped out of the stack and the work payload is sent to the worker in a `goroutine`.

{% highlight go %}
func StartDispatcher(nworkers int) {
	WorkerQueue := make(chan chan worker.WorkRequest, nworkers)

	for i := 0; i < nworkers; i++ {
		worker := worker.NewWorker(i+1, WorkerQueue)
		worker.Start()
	}

	go func() {
		for {
			select {
			case work := <-collector.WorkQueue:
				fmt.Println("Received work request")
				go func() {
					worker := <-WorkerQueue

					fmt.Println("Dispatching work request")
					worker <- work
				}()
			}
		}
	}()
}
{% endhighlight %}

To use the workers pool, first the `dispatcher` function is called with the number of workers the application might need, after this, the `collector` function is called to send works to the pool.


{% highlight go %}
func main() {

	sigs := make(chan os.Signal, 1)
	done := make(chan bool, 1)
	signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM)

	s1 := rand.NewSource(time.Now().UnixNano())
	r1 := rand.New(s1)

	go func() {
		sig := <-sigs
		fmt.Println()
		fmt.Println(sig)
		done <- true
	}()

	dispatcher.StartDispatcher(3)
	for i := 0; i < 10; i++ {
		collector.Collector("", r1.Intn(10))
	}
	fmt.Println("awaiting signal")
	<-done
	fmt.Println("exiting")
}
{% endhighlight %}

### Elixir Implementation

This implementation requires of two behaviors native to Elixir, `GenServer` and `Supervisor`, `GenServer` was already used on `PubSub`. `Supervisor`  (“Task.Supervisor – Elixir v1.1.1,” n.d.) is a process that supervises other processes called child processes, they are used to build a hierarchical process structure called supervisor tree; this is very useful to build fault-tolerant applications,

The first step of the application is to define how jobs will be sent to the workers, since the approach must be similar to go, the Job must have a function that must be run within the worker, and store the payload. To achieve this a module is defined with a structure with the fields that are necessary:

{% highlight elixir %}
defmodule Workers.Job do
  defstruct task: nil, from: nil, id: nil, payload: nil
end
{% endhighlight %}

The next part is what receives the structure defined earlier, the `Worker`, `GenServer` behavior is needed to achieve asynchronous calls to the dispatcher, meaning that after receiving a job, it should execute it and wait again for a new job. To initialize a Worker only is needed a numeric `id` which is only used for `Logger` operations, after the Worker is spawned a request to the queue module is sent to monitor the worker; finally a cast call is done to start receiving jobs.

{% highlight elixir %}
def init([id]) do
	queue = Workers.work_queue_name()
	GenServer.call(queue, :register)
	GenServer.cast(self, :job)
	Logger.info("[Worker] Started worker with ID #{inspect id}")
	{:ok, {queue , id}}
end
{% endhighlight %}

To implement `GenServer` and the `Supervisor` the methods `start_link` and `start` are defined:

{% highlight elixir %}
def start_link(id) do
	GenServer.start_link(__MODULE__, [id])
end

def start(id) do
	GenServer.start(__MODULE__, [id])
end
{% endhighlight %}

To finish the module now the cast must be handled, a synchronous call to the queue is made via `GenServer.call`, this will linger until a job is dispatched to the worker, when one is sent, the worker will execute the function and wait for another job.  

{% highlight elixir %}
def handle_cast(:job, {queue, id} = state ) do
	job = GenServer.call(queue, :dispatch, :infinity)
	res = case job.task do
						 f when is_function(f) -> f.([job.payload, id, queue])
					 end
	GenServer.cast(self, :job)
	{:noreply, state}
end
{% endhighlight %}

The `WorkerQueue` is in charge to dispatch the jobs and to keep track of each of the workers; since `GenServer` is needed to keep state, a struct is defined to track what the workers are doing, and a backlog messages that are not yet processed:

{% highlight elixir %}
defmodule State do
	defstruct queue: :queue.new,
						waiting: :queue.new,
						working: HashDict.new
end
{% endhighlight %}

`queue` is used to store the jobs not yet sent, `waiting` are the workers that are waiting for a job, when a worker finishes its task it its queued again ,so they are served on a first in, first out basis, finally `working`, which is not a queue, but it can help to monitor which workers are doing what. To start the queue `start_link` is called with `name`, how to define this name will be explained later in this post.

{% highlight elixir %}
def start_link (name) do
	Logger.info(["[WorkQueue] started"])
	GenServer.start_link(__MODULE__, %State{}, name: name)
end
{% endhighlight %}

This server has three main functions: `:add_task`, `:dispatch` and `:register`; `:add_task` queues every incoming job, `:dispatch` sends jobs to the workers, if there are no jobs in queue the worker will be queued and served when any job is available, finally `:register` starts to monitor each of the workers pid.

{% highlight elixir %}
{% raw %}
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
{% endraw %}
{% endhighlight %}

After finishing the `Worker` and the `WorkerQueue` implementation, its needed to wrap up those parts and ensure they are working, even after a work failed, to achieve this `Supervisor` instances are used, the configuration is pretty straightforward, one is needed for the workers, and another one supervises the Worker supervisor and the queue. for qhe worker supervisor, the arguments needed are are how many workers will be spawned and the time, which along which a given time frame, will define how many restarts of a process is allowed in how much time.

{% highlight elixir %}
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
{% endhighlight %}

To start the `WorkerSupervisor` and the `WorkQueue` another supervisor is spawned, with the first defined as a `supervisor` and the latter as a `worker`, both of them have default configuration.

{% highlight elixir %}
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
{% endhighlight %}

The main module is where job requests are sent and where everything fires up, talso, to handle asynchronous calls to the other services a `GenServer` is used, so as the last two modules a supervisor is used to initialize everything,

{% highlight elixir %}
def start_link(init_retry_secs, num_workers) do
	import Supervisor.Spec

	id = Module.concat([Workers, Supervisor])
	children = [supervisor(Workers.Supervisor,
														 [init_retry_secs, num_workers],
														 id: id)]
	Supervisor.start_link(children, strategy: :one_for_one)
	GenServer.start_link(__MODULE__, :ok, [{:name, __MODULE__}])
end
{% endhighlight %}

To send work requests, a function is used that receives an anonymous function and the payload, then a cast is sent to the inner `GenServer` so it does not block future requests.

{% highlight elixir %}
def collector(fun, payload) do
	GenServer.cast(__MODULE__, {:collector, fun, payload})
end

def handle_cast({:collector, fun, payload}, state) do
	work_queue_name()
	|> GenServer.cast({:add_task, fun, payload})
	{:noreply, []}
end
{% endhighlight %}

Finally, two functions are defined to name the queues and the supervisor using `Module.concat`, this functions take a list of arguments and returns a name, so in case an extension of the pool of workers is required it can be modified so it take more arguments, like the name of the pool or another module for metaprogramming.

def work_queue_name do
	Module.concat([Workers, WorkQueue])
end

{% highlight elixir %}
def worker_supervisor_name do
	Module.concat([Workers, WorkerSupervisor])
end
{% endhighlight %}

# Observations

## Metrics

|                       |   Go   |  Elixir |
|-----------------------|:------:|:-------:|
| LOC                   |   99   |  115    |
| # of Functions        |   7    |   17    |
| Av. LOC per Function  |  14.14 |   6.67  |
| Cyclomatic complexity |    2   |    1    |


## Qualitative observations

This pattern is where go channels really shine, since their approach is to share memory through communicating, it can easily simplify the way multiple processes communicate, since the channel that queues the workers is also the channel that hosts the channel where a job is sent, a lot of complexity is avoided by this, also the `select` statement really helps to decide what is going to be done depending on which channel receives data, the only bad part is that go lacks a way to manage the goroutines, while elixir has the supervisors which really help in turning on a lot of stuff.

# Bibliography

Competing Consumers Pattern. (n.d.). Retrieved November 5, 2015, from https://msdn.microsoft.com/en-us/library/dn568101.aspx

Hohpe, G., & Woolf, B. (2012). Enterprise Integration Patterns: Designing, Building, and Deploying Messaging Solutions. Addison-Wesley.

Task.Supervisor – Elixir v1.1.1. (n.d.). Retrieved November 5, 2015, from http://elixir-lang.org/docs/v1.1/elixir/Task.Supervisor.html
