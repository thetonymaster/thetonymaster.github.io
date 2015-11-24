package orderprocesor

import (
	"fmt"
	"math/rand"
	"time"
)

type Order struct {
	OrderNumber int
	OrderItems  []OrderItem
}

type OrderItem struct {
	ID          string
	ItemType    string
	Description string
	Price       int
}

type OrderProcessor struct {
	orders chan Order
	random *rand.Rand
}

func New(capacity int) chan Order {
	orders := make(chan Order, capacity)

	s1 := rand.NewSource(time.Now().UnixNano())
	r1 := rand.New(s1)

	orderp := OrderProcessor{
		orders: orders,
		random: r1,
	}
	go orderp.start()
	return orders
}

func (orderp OrderProcessor) start() {
	for order := range orderp.orders {
		tm, _ := time.ParseDuration(fmt.Sprintf("%vs", orderp.random.Int31n(10)))
		time.Sleep(tm)
		fmt.Println(order)
	}
}
