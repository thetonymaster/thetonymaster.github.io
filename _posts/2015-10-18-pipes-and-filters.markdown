---
layout: post
title:  "Pipes and filters"
date:   2015-10-18 22:09:02
categories: patterns go elixir
---
# Pipes and filters

One of the integration challenges in a computer system is the processing of incoming messages, which may require two or more steps to produce any meaningful data, the most common approach for this is to write a module that performs every task sequentially, however it would be very inflexible and difficult to test. Decoupling every step in a different component allows its reuse in complete different processes  (Hohpe & Woolf, 2012, p. 70). This also allows the execution in different physical machines , or the use of different programming languages or technologies (MSDN, n.d.). Even if these components are separated, dependencies can still be introduced. To fix this a common interface must be exposed independent of the dependency introduced, so they can be interchangeable.

![Pipes and filters](http://thetonymaster.github.io/assets/PipesAndFilters.jpg)
<script src="/assets/js/processing.min.js"></script>
<canvas data-processing-sources="/assets/processing/pipes-and-filters.pde"></canvas>

If we use asynchronous messaging between each component we can take advantage and process each message asynchronously or concurrently, without having to wait for the results. Using this technique we could process multiple messages in parallel.

Each filter must expose an interface where the messages are received and one to send the result of its operations. Since every component uses the same interface they can be connected into different solutions using different pipes, creating and connecting new pipes and filters or omitting and rearranging existing ones. The implementation for this pipes is described by the pattern Message Channel (Hohpe & Woolf, 2012, p. 60), this allows to move each component to a different machine, also using queues for the messages can be more efficient.

However, the throughput is limited by the slowest filter in the chain. To solve this the processing of said component must be parallel, this can be accomplished by spawning more instances or using competing consumers. This will allow to speed up the processing and increase throughput.

# Disadvantages

A batch processing approach must be encouraged using  this pattern, this can lead to tamper the interactivity between applications. Another problem with this approach is that   the data must be represented  in the lowest common denominator. such as bytes and strings which could lead to loss of flexibility. Also if a filter must receive all the input before producing an output can lead to a deadlock (Bass, Clements, & Kazman, 2012, p. 90).

# Implementation

## The problem

The problem consists of four steps:

1. A JSON consisting of different cities with the current weather forecast is received each 30 seconds
2. The current forecast of each city must be separated
3. The weather for the next few days will be added
4. The result should be presented to an user

### Go implementation

Go already implements a way to communicate between components, channels. Channels can be bi or unidirectional.  For this implementation every filter exposes and receives a receive-only channel, the latter is where the messages will be received from a preceding filter, and the former is where the messages will be written and read from another component. This is achieved with the generator “pattern” (Pike, n.d.), which is a method where a receive-only channel is returned.

{% highlight go %}
func NewCityFilter(in <-chan []byte) <-chan []byte {
	out := make(chan []byte, 10)
	go filter(in, out)
	return out
}
{% endhighlight %}

As seen on the last figure, `out` is the channel where the result will be written; in this case this filter will read the json and send every single city to the next filter; `go` is used to start a goroutine which receives each of the channels. `filter` is where the processing happens, the channel is inside a `for` loop, which executes the body every time a new message is received.

{% highlight go %}
func filter(in <-chan []byte, out chan []byte) {
	for msg := range in {
{% endhighlight %}

When all the tasks are done the result is simply written on the out channel and returns to the initial state.

{% highlight go %}
res, err := json.Marshal(ct2)
if err != nil {
	panic(err)
}
out <- res
{% endhighlight %}

### Elixir implementation

The communication between processes in elixir is done via `send`, which is a native function which receives the PID of the process and the message to be sent. The function to start a new process is `spawn`, which receives the class and method and returns the PID of the new process.

{% highlight elixir %}
cities = spawn(Cities, :filter, [])
:global.register_name("nextcity", cities)
{% endhighlight %}

The method defined in the send method must implement receive which waits until a message is sent.

{% highlight elixir %}
def filter do
    receive do
      cities ->
        get_cities cities
    end
    filter
end
{% endhighlight %}

Due to the nature of being a functional language, Elixir does not implement loops, the function must implement recursion to be able to receive new messages, otherwise the process exits after receiving the first message. The way to connect every filter in this approach is either to pass the PID of the process or to register as a global variable, for this implementation the solution used was to register the PID and access it with a keyword

{% highlight elixir %}
cities = spawn(Cities, :filter, [])
:global.register_name("nextcity", cities)

forecast = spawn(Forecast, :get, [])
:global.register_name("nextforecast", forecast)

writer = spawn(Sink, :write, [])
:global.register_name("nextsink", writer)

defp get_cities [next | tail] do
      send :global.whereis_name("nextforecast"), next
      get_cities tail
end
{% endhighlight %}

# Observations

## Metrics

|   	   | LOC | # of functions  | Av. LOC per function  | Cyclomatic complexity | Performance |
|--------|-----|-----------------|-----------------------|-----------------------|-------------|
| Go     | 241 |        10       |          24.1         |           5           |             |
| Elixir | 135 |        16       |           8.4         |           1           |             |

The total lines of code for the Go implementation where 190 and for Elixir 153.

## Qualitative observations
The implementation for golang is clearer due to the nature of channels, which can define which direction (either send or receive) they have, also they can be passed to another goroutine without any complications. On the other side, elixir has to know every PID of to be able to send messages, besides, go channels have the advantage of being buffered and to be closed in case something happens.

On the topic of messages, elixir messages can be virtually anything due to having metaprogramming, while go had a lot of boilerplate code to deal with the messages being in plain bytecode, but while go just had a lot of boilerplate code, in Elixir you had a lot of functions just to extract the data, and to transform it, while it had a lot of code, it also has a lot more of complexity.

# Bibliography

Bass, L., Clements, P., & Kazman, R. (2012). Software Architecture in Practice. Addison-Wesley.

Hohpe, G., & Woolf, B. (2012). Enterprise Integration Patterns: Designing, Building, and Deploying Messaging Solutions. Addison-Wesley.

MSDN. (n.d.). Pipes and Filters Pattern. Retrieved October 8, 2015, from https://msdn.microsoft.com/en-us/library/dn568100.aspx

Pike, R. (n.d.). Go Concurrency Patterns. Retrieved October 8, 2015, from https://talks.golang.org/2012/concurrency.slide
