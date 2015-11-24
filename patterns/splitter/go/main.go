package main

import (
	"fmt"
	"os"
	"os/signal"
	"syscall"

	"thetonymaster.github.io/patterns/splitter/go/inventory"
	"thetonymaster.github.io/patterns/splitter/go/orderprocessor"
	"thetonymaster.github.io/patterns/splitter/go/paymentprocessor"
	"thetonymaster.github.io/patterns/splitter/go/splitter"
)

func main() {

	sigs := make(chan os.Signal, 1)
	done := make(chan bool, 1)
	signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM)

	order := getSeed()

	spt := splitter.New(10)

	go func() {
		sig := <-sigs
		fmt.Println()
		fmt.Println(sig)
		done <- true
	}()

	spt <- order

	fmt.Println("awaiting signal")
	<-done
	fmt.Println("exiting")

}

func getSeed() splitter.Order {
	order := splitter.Order{
		OrderDetails: orderprocesor.Order{
			OrderNumber: 12345,
			OrderItems: []orderprocesor.OrderItem{
				{
					ID:          "78uakj",
					ItemType:    "Stuff",
					Description: "It goes bit when there's stuff",
					Price:       10000,
				},
				{
					ID:          "lkeoa9",
					ItemType:    "Non euclidean stuff",
					Description: "no description possible",
					Price:       20000,
				},
			},
		},
		PaymentDetails: paymentprocessor.Payment{
			ID:          "jhhamksjd8",
			PaymentType: "Credit Card",
			Amount:      30000,
		},
		InventoryRequest: inventory.InventoryRequest{
			Items: []inventory.Item{
				{
					ID:     1929381,
					Number: 1,
				},
				{
					ID:     9879791,
					Number: 1,
				},
			},
		},
	}
	return order
}
