package main

import (
	"fmt"
	"os"
	"os/signal"
	"syscall"

	"thetonymaster.github.io/patterns/content-based-router/go/inventory"
	"thetonymaster.github.io/patterns/content-based-router/go/router"
)

func main() {

	sigs := make(chan os.Signal, 1)
	done := make(chan bool, 1)
	signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		sig := <-sigs
		fmt.Println()
		fmt.Println(sig)
		done <- true
	}()

	cbr := router.New(10)
	orderA, orderB := getSeed()
	cbr <- orderA
	cbr <- orderB

	fmt.Println("awaiting signal")
	<-done
	fmt.Println("exiting")
}

func getSeed() (inventory.Order, inventory.Order) {
	orderA := inventory.Order{
		ID:        "1",
		OrderType: "A",
		OrderItems: []inventory.OrderItem{
			{
				ID:          "12",
				ItemType:    "Stuff",
				Description: "More Stuff",
				Price:       3000,
			},
		},
	}

	orderB := inventory.Order{
		ID:        "2",
		OrderType: "B",
		OrderItems: []inventory.OrderItem{
			{
				ID:          "128",
				ItemType:    "Some other stuff",
				Description: "More other stuff",
				Price:       3000,
			},
		},
	}
	return orderA, orderB
}
