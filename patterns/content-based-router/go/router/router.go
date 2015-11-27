package router

import (
	"fmt"

	"thetonymaster.github.io/patterns/content-based-router/go/inventory"
)

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
