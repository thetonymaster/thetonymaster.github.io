---
layout: post
title:  "Content based router"
date:   2015-11-02 22:09:02
categories: patterns go elixir
comments: true
---

# Content Based Router

The  `content based router` examines every message content and routes the message onto a different channel based on the date contained in the message. The routing can be based on a number of criteria such as existence of fields, specific values etc. Special caution should be taken to make the router easy to maintain, as the router can become a point of frequent maintenance. It can be extended to take a form of configurable rules engine that decided which destination channel the message is sent based on a set of rules.

<script src="/assets/js/processing.min.js"></script>
<canvas data-processing-sources="/assets/processing/content-based-router.pde"></canvas>

`Content based routers` are used as a more generic form of message routers using predictive routing, incorporating knowledge  of the capabilities of another systems; making this efficient routing because each of the messages is sent to the correct system. The downside is that he has to have knowledge of all the possible recipients and their capabilities. As they are removed and added, the router has to be changed every time possibly becoming a maintenance nightmare.

To avoid the dependency on the individual recipients if they assume more control over the routing process. These options can be summarized as `reactive filtering` because they allow each participant to filter relevant messages as they come by.  The distribution of routing control eliminates the need of a `Content based router` but is less efficient.

## Advantages

- Can be very efficient because it sends the message is sent only to the right system
- If done right, can be easily configurable
- Can reduce network traffic

## Disadvantages

- Can become a maintenance nightmare
- Can become tightly coupled to the dependent systems

# Implementation  

## The problem

1. There are several inventory systems
2. Send the correct message to every of the system

### Go implementation

Each of the inventory systems expose a channel where the incoming messages are written. This is done with the  `channel generator` channel; also starts a goroutine that listens for incoming messages. The inventory systems in this implementations are the same instances of `Inventory` for simplicity sake, real implementation may wildly differ from this:

{% highlight go %}
func New(name string, capacity int) chan Order {
	orders := make(chan Order, capacity)
	inv := Inventory{
		name:   name,
		orders: orders,
	}

	go inv.start()
	return orders
}

func (inv Inventory) start() {
	for order := range inv.orders {
		fmt.Printf("%s: %#v\n", inv.name, order)
	}
}
{% endhighlight %}

For the router, every channel is stored inside a struct, and also as the inventory systems a channel to write messages:

{% highlight go %}
type ContentBasedRouter struct {
	orders     chan inventory.Order
	inventoryA chan inventory.Order
	inventoryB chan inventory.Order
}

func New(capacity int) chan inventory.Order {
	orders := make(chan inventory.Order, capacity)
	inventoryA := inventory.New("Inventory A", capacity)
	inventoryB := inventory.New("Inventory B", capacity)

	cbr := ContentBasedRouter{
		orders:     orders,
		inventoryA: inventoryA,
		inventoryB: inventoryB,
	}

	go cbr.start()
	return orders
}
{% endhighlight %}

When a message is received, it checks for the `OrderType` field of the `Order` type and then decides to which system the message will be sent with a `switch` directive:

{% highlight go %}
func (cbr ContentBasedRouter) start() {
	for order := range cbr.orders {
		switch order.OrderType {
		case "A":
			cbr.inventoryA <- order
		case "B":
			cbr.inventoryB <- order
		default:
			fmt.Println("Inventory type not found")

		}
	}
}
{% endhighlight %}

### Elixir implementation

As with past implementations, `GenServer` will be used, since this library is a wrapper around actors, providing synchronous and asynchronous calls, the Inventory instance will just wait for a message to be sent, vanilla actors can also be used since state it's not really been kept.

{% highlight elixir %}
defmodule ContentBasedRouter.Inventory do
  use GenServer

  def start_link(key, name) do
    GenServer.start_link(__MODULE__, %{key: key, name: name}, name: name)
  end

  def handle_cast({:request, order}, state) do
    IO.puts "#{state[:key]}: #{inspect order} "
    {:noreply, state}
  end

end
{% endhighlight %}

The router is also a `GenServer` that initializes the `Inventory` systems, when an `Order` arrives, pattern matching is used to decide to which system the message will be sent forward:

{% highlight elixir %}
def handle_cast({:order, order}, state) do
  handle_order(order, state)
  {:noreply, state}
end

defp handle_order(%{orderType: :inventoryA} = all, state) do
  GenServer.cast(state[:inventoryA], {:request, all})
end
defp handle_order(%{orderType: :inventoryB} = all, state) do
  GenServer.cast(state[:inventoryB], {:request, all})
end
defp handle_order(_, _) do
  IO.puts "Unknown inventory system"
end
{% endhighlight %}

### Scala implementation

The implementations uses plain actors, to avoid more complexity, each of the Inventory actors waits for an `Order` case class, if this a different case class is sent the message will be dismissed:

{% highlight scala %}
class InventorySystem(inventoryName: String) extends Actor {
  def receive = {
    case OrderPlaced(order) =>
      println(s"$inventoryName: handling $order")
      ContentBasedRouter.completedStep()
    case _ =>
      println(s"$inventoryName: unexpected message")
  }
}
{% endhighlight %}

The router waits for an `Order` to be sent, when one arrives pattern matching with the `match` directive is used and with the  `orderType` field is used to determine to which inventory system the message will be re-sent.

{% highlight scala %}
class OrderRouter extends Actor {
  val inventoryA = context.actorOf(Props(classOf[InventorySystem], "InventoryA"), "inventoryA")
  val inventoryB = context.actorOf(Props(classOf[InventorySystem], "InventoryB"), "inventoryB")

  def receive = {
    case orderPlaced: OrderPlaced =>
      orderPlaced.order.orderType match {
        case "TypeA" =>
          inventoryA ! orderPlaced
        case "TypeB" =>
          inventoryB ! orderPlaced
        case _ =>
          println("OrderRouter: received unexpected message")
      }
      ContentBasedRouter.completedStep()
  }
}
{% endhighlight %}

# Observations

## Metrics

|                       |   Go   |  Elixir | Scala |
|-----------------------|:------:|:-------:|:-----:|
| LOC                   | 119    |  50     |   86  |
| # of Functions        |  10    |   14    |    3  |
| Av. LOC per Function  |  23.8  |   6.25  |   27.2|
| Cyclomatic complexity |    1   |    1    |    5  |


## Qualitative Observations

Elixir's implementation is quite small compared to the other two languages, this is because the other two are statically typed languages, and some boilerplate code is required to create the classes and the types needed respectively for scala and go, also the code for go can be shrunk a little if best practices are ignored and the order examples are created not using the names of the fields and in the single line but they will be harder to read. Each of the languages has certain advantages, Elixir it's not bound by types unless it's stated so by a directive, which in this case helps to write less code, and to implement interesting messaging systems but can be prone to errors if malformed messages are sent. Go can be bound by types but the using of interfaces is so simple that implementing one for the messages can be used for more complex messages, the router channel will be bound to an interface instead of a type. Finally Akka has a lot of features that can be implemented out of the box and actors are spawned quite easily, also case classes also really help since they are simple enough to use with pattern matching.
