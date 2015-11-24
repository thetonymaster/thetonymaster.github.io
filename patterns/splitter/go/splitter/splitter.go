package splitter

import (
	"thetonymaster.github.io/patterns/splitter/go/inventory"
	"thetonymaster.github.io/patterns/splitter/go/orderprocessor"
	"thetonymaster.github.io/patterns/splitter/go/paymentprocessor"
)

type Order struct {
	OrderDetails     orderprocesor.Order
	PaymentDetails   paymentprocessor.Payment
	InventoryRequest inventory.InventoryRequest
}

type Splitter struct {
	orders chan Order
}

func New(capacity int) chan Order {
	orders := make(chan Order, capacity)

	splitter := Splitter{
		orders: orders,
	}

	go splitter.start()
	return orders
}

func (splitter Splitter) start() {
	payments := paymentprocessor.New(10)
	orders := orderprocesor.New(10)
	inv := inventory.New(10)

	for order := range splitter.orders {
		orders <- order.OrderDetails
		payments <- order.PaymentDetails
		inv <- order.InventoryRequest
	}
}
