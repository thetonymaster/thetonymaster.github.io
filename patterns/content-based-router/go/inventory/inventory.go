package inventory

import "fmt"

type Order struct {
	ID         string
	OrderType  string
	OrderItems []OrderItem
}

type OrderItem struct {
	ID          string
	ItemType    string
	Description string
	Price       int
}

type Inventory struct {
	name   string
	orders chan Order
}

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
