---
layout: post
title:  "Pipes and filters"
date:   2015-10-18 22:09:02
categories: patterns go elixir
comments: true
---
# Pipes and filters

One of the integration challenges in a computer system is the processing of incoming messages, which may require two or more steps to produce any meaningful data, the most common approach for this is to write a module that performs every task sequentially, however it would be very inflexible and difficult to test. Decoupling every step in a different component allows its reuse in complete different processes  (Hohpe & Woolf, 2012, p. 70). This also allows the execution in different physical machines, or the use of different programming languages or technologies (MSDN, n.d.). Even if these components are separated, dependencies can still be introduced. To fix this a common interface must be exposed independently of the dependency, so they can be interchangeable.

![Pipes and filters](/assets/img/PipesAndFilters.jpg)
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

As seen on the last figure, `out` is the channel where the result will be written; in this case this filter will read the json and send every single city to the next filter; `go` is used to start a goroutine which receives each of the channels. The `filter` function is where the processing happens, the channel is inside a `for` loop, which executes the tasks for each of the filters.

{% highlight go %}
func filter(in <-chan []byte, out chan []byte) {
	for msg := range in {
{% endhighlight %}

When all the tasks are done the result is simply written in the out channel and returns to the initial state.

{% highlight go %}
res, err := json.Marshal(ct2)
if err != nil {
	panic(err)
}
out <- res
{% endhighlight %}

### Elixir implementation

The concurrency model for elixir is the same as erlang, the abstraction is called actors; an actor basically receives a message and perform any kind of computation based on it. Every actor is completely isolated from other actors and they never share memory, it can maintain a private state that can be never be changed by another actor. The abstraction for the actor messaging system is called mailbox, if an it receives more than one messages it will process them sequentially (Storti, 2015).

The communication between processes in elixir is done via `send`, which is a native function which receives the `PID` of the process and the message to be sent. The function to start a new process is `spawn`, which receives the class and method and returns the `PID` of the new process.

{% highlight elixir %}
cities = spawn(Cities, :filter, [])
:global.register_name("nextcity", cities)
{% endhighlight %}

Each of the filters must implement the `receive` block, it will wait until a message is received. When this happens it will do the tasks specified and then exit. Due to the nature of being a functional language, Elixir does not implement loops, the function must implement recursion to be able to receive new messages, otherwise the process exits after receiving the first message.

{% highlight elixir %}
def filter do
    receive do
      cities ->
        get_cities cities
    end
    filter
end
{% endhighlight %}

 Now that the filter is defined, every filter must be connected. The approach taken is either to pass the `PID` of the process or to register as a global variable, for this implementation the solution used was to register the `PID` and access it with a keyword

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

### Scala implementation

For the scala implementation, a library called Akka will be used. Akka is a toolkit for building highly concurrent, distributed and resilient message driven applications (“Akka,” n.d.). Akka implements the actor system (the same system erlang and elixir use), but the main difference is that while elixir is a pure functional language, scala is more like a hybrid language, fusing object-oriented and functional principles, some concepts can be implemented as mutable, while others are strictly immutable. Scala used to have a default actor library, but this has been deprecated in favor for Akka by the time this post was written. (Vernon, 2015)

To use actors in scala, each of the classes must follow two simple rules:

1. Must extend `Actor`
2. Must have a function called `receive`

Like elixir, each actor has an identifier, but instead of being a `PID`, it's called `ActorRef`, each one of them is a url-like address that indicates the name and where the actor is (wether local or remote).

{% highlight scala %}
class WeatherEndpoint(nextFilter: ActorRef) extends Actor {
  implicit val formats = DefaultFormats

  def receive = {
    case weather: String =>
		val value = json.extract[WeatherList]
		getCities(value.list)
{% endhighlight %}

Each of the filters receives the next filter `ActorRef`, and inside of the receive method, the appropriate operations for each of the messages received are done inside of a `case` clause, after finishing, the message is passed to the next operation with the `tell` function, that also can be accessed with the `!` operator (“Actors — Akka Documentation,” n.d.).

{% highlight scala %}
def getCities(list: List[CityJSON]): Unit = {
	@tailrec
	def inner(xs: List[CityJSON]): Unit = {
		xs match {
			case x :: tail =>
				nextFilter ! x
				inner(tail)
			case Nil =>
		}

	}
	inner(list)
}
{% endhighlight %}

For this filter after the JSON received from a request is parsed, each of the members of a list is sent to the next filter with tail recursion. All the filters receive the next `ActorRef`, except the `Sink`, which is the last element.

To create an actor first a group must be created, this is done with an Akka method called `ActorSystem`, every one of this has the same configuration, dispatchers, etc (“akka.actor.ActorSystem,” n.d.).

{% highlight scala %}
val system = ActorSystem("eaipatterns")
{% endhighlight %}

After instantiating the system, every filter is initialized, this is done with `system.actorOf` which receives a `Props` (a configuration object that also receives the arguments to initialize every actor class (“Akka Documentation,” n.d.)) and a name, which has to be unique on `ActorSystem`. The filters and the sink are initialized in reverse order to ensure that each of the preceding filter has the next filter's `ActorRef`.

{% highlight scala %}
val filter3 = system.actorOf(Props[Sink], "sink")
val filter2 = system.actorOf(Props(classOf[WeatherForecast], filter3), "weatherForecast")
val filter1 = system.actorOf(Props(classOf[WeatherEndpoint], filter2), "weatherEndpoint")
{% endhighlight %}


# Observations

## Metrics


|                       |   Go   |  Elixir |  Scala  |
|-----------------------|:------:|:-------:|:--------|
| LOC                   |  292   |  124    |   149   |
| # of Functions        |   10   |   16    |    16   |
| Av. LOC per Function  |   29.2 |    7.75 |   9.31  |
| Cyclomatic complexity |    5   |    1    |     3   |


## Qualitative observations
The implementation for `golang` is clearer due to the nature of channels, which can define which direction (either send or receive) they have, also they can be passed to another `goroutine` without any complications. On the other side, elixir has to know every `PID` of to be able to send messages, besides, go channels have the advantage of being buffered and to be closed in case something happens.

On the topic of messages, elixir messages can be virtually anything due to having metaprogramming, while go had a lot of boilerplate code to deal with the messages being in plain bytecode, but while go just had a lot of boilerplate code, in Elixir you had a lot of functions just to extract the data, and to transform it, while it had a lot of code, it also has a lot more of complexity.

Akka's actor system is pretty similar to elixir's (well, they should because they are both Actor systems after all), but they manage different concepts, which from a pragmatic point of view they are basically the same, like `ActorRef` and `PID`. the main difference between those two are the language capabilities; Elixir is purely functional and its functions reflect this because they support pattern matching out of the box, leading to more readable code but an maybe an increases number of functions, on the other hand, scala supports pattern matching via the `case` clause, and even provides `case classes` to ease it, but sometimes the code can be less readable because of this, for example the tail recursion, which is present in both of the implementations. In elixir two functions are defined, one that receives the head and tail, and another with an empty list, both have the same name and after reading them it can be easily inferred what they do and it cal be called with just one parameter. While in scala one function has one parameter and an inner function is the one that does the recursion, doing the pattern matching inside of it, the upper function just hides the inner one. It functions exactly the same, but it's kinda harder to grasp.

As final thoughts, scala's build tools are pretty harder to learn than the ones provided by elixir and go, `sbt` is pretty similar to `mix`, but it does not start a new project automatically (not a complaint). Also, the external libraries kinda suffer some of the `Java Syndrome`, since Java has a lot of time on the market, most of the documentation is written for people with some experience, and it can be quite hard for beginners to use them, several JSON libraries where tried and since some of them required to write boilerplate code, but the examples for this code were often for simple JSON documents, but these are just personal thoughts on the matter, if someone knows how to resolve this please leave a comment.

# Bibliography

Actors — Akka Documentation. (n.d.). Retrieved November 12, 2015, from http://doc.akka.io/docs/akka/snapshot/scala/actors.html

Akka. (n.d.). Retrieved November 12, 2015, from http://akka.io/

akka.actor.ActorSystem. (n.d.). Retrieved November 12, 2015, from http://doc.akka.io/api/akka/2.0/akka/actor/ActorSystem.html

Akka Documentation. (n.d.). Retrieved November 12, 2015, from http://doc.akka.io/api/akka/2.3.1/index.html#akka.actor.Props

Bass, L., Clements, P., & Kazman, R. (2012). Software Architecture in Practice. Addison-Wesley.

Hohpe, G., & Woolf, B. (2012). Enterprise Integration Patterns: Designing, Building, and Deploying Messaging Solutions. Addison-Wesley.

MSDN. (n.d.). Pipes and Filters Pattern. Retrieved October 8, 2015, from https://msdn.microsoft.com/en-us/library/dn568100.aspx

Pike, R. (n.d.). Go Concurrency Patterns. Retrieved October 8, 2015, from https://talks.golang.org/2012/concurrency.slide

Storti, B. (2015, July 9). The actor model in 10 minutes. Retrieved November 12, 2015, from http://www.brianstorti.com/the-actor-model/

Vernon, V. (2015). Reactive Enterprise with Actor Model: Application and Integration Patterns for Scala and Akka. Addison-Wesley Professional.
